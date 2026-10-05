"""
allocator.py – deterministic allocation engine (Steps 0-5 from spec section 5).

STEP 0  Reject non-operating days.
STEP 1  Pre-screen each order; defer immediately (UNAVOIDABLE) if no reefer, no van,
        too large, or window unreachable.
STEP 2  Rank remaining orders.
STEP 3  For each order in rank order:
          a. Add to an existing open trip (same depot, brand, district) that stays valid.
          b. Else open a new trip on the smallest sufficient eligible vehicle slot
             (prefer ambient trucks for ambient orders; keep reefers free).
          c. Else defer with a diagnosed reason.
STEP 4  Sequence stops; compute ETAs, fuel, utilization.
STEP 5  Validate the whole plan with the validator. Any violation is a bug.

Locked trips (CONFIRMED or later) are passed in as fixed input and are never modified.
"""

from __future__ import annotations
from typing import Dict, List, Optional, Tuple

from .constants import (
    BUDGET_FRESH_MIN,
    BUDGET_STYLE_TECH_MIN,
    DEFAULT_PRIORITY_CONFIG,
    DeferralClass,
    DeferralCode,
    MAX_TRIPS_PER_VEHICLE_PER_DAY,
)
from .deferral import diagnose_deferral
from .formula import (
    compute_trip_fuel,
    compute_trip_minutes,
    hhmm_to_minutes,
    minutes_to_hhmm,
)
from .priority import rank_orders
from .timeline import compute_stop_etas, sort_stops, trip_end_min, compute_depart_time
from .types import (
    AllocatorInput,
    AllocatorOutput,
    DeferralRecord,
    OrderInput,
    ReferenceData,
    StopETA,
    TripPlan,
    VehicleRef,
    VehicleSlot,
    ValidationResult,
    ViolationDetail,
)
from .validator import validate_plan


# ---------------------------------------------------------------------------
# Internal mutable trip state
# ---------------------------------------------------------------------------

class _TripState:
    """Mutable working state for an open trip during allocation."""

    def __init__(
        self,
        vehicle_id: str,
        trip_no: int,
        brand: str,
        district: str,
        depot: str,
        vref: VehicleRef,
    ):
        self.vehicle_id = vehicle_id
        self.trip_no = trip_no
        self.brand = brand
        self.district = district
        self.depot = depot
        self.vref = vref
        self.orders: List[OrderInput] = []

    @property
    def key(self) -> str:
        return f"{self.vehicle_id}_trip{self.trip_no}"

    def total_weight(self) -> float:
        return sum(o.order_weight_kg for o in self.orders)

    def total_volume(self) -> float:
        return sum(o.order_volume_m3 for o in self.orders)

    def trip_minutes(self, ref: ReferenceData) -> float:
        dist = ref.districts[self.district]
        return compute_trip_minutes(self.orders, dist, ref, self.brand)

    def fuel_l(self, ref: ReferenceData) -> float:
        dist = ref.districts[self.district]
        return compute_trip_fuel(len(self.orders), dist, self.vref.km_per_l)

    def can_accept(
        self,
        order: OrderInput,
        ref: ReferenceData,
        fuel_committed: Dict[str, float],
        fresh_budget_used: float,
        style_tech_budget_used: float,
        prev_trip_end_min: int = 0,
        reload_buffer_min: int = 0,
    ) -> Optional[str]:
        """Returns None if order can be added, else a DeferralCode."""
        # H6: capacity
        if self.total_weight() + order.order_weight_kg > self.vref.weight_cap_kg:
            return DeferralCode.CAPACITY_FULL
        if self.total_volume() + order.order_volume_m3 > self.vref.volume_cap_m3:
            return DeferralCode.CAPACITY_FULL

        # H2: temperature
        if order.temp_requirement == "chilled" and self.vref.temp != "reefer":
            return DeferralCode.NO_REEFER

        # H3: van_only
        outlet = ref.outlets.get(order.outlet_id)
        if outlet and outlet.parking_constraint == "van_only" and self.vref.type != "van":
            return DeferralCode.NO_VAN

        # H8: time budget (formula, no waiting)
        new_mins = compute_trip_minutes(
            self.orders + [order], ref.districts[self.district], ref, self.brand
        )
        if self.brand == "Fresh":
            if fresh_budget_used - self.trip_minutes(ref) + new_mins > BUDGET_FRESH_MIN:
                return DeferralCode.TIME_BUDGET
        else:
            if style_tech_budget_used - self.trip_minutes(ref) + new_mins > BUDGET_STYLE_TECH_MIN:
                return DeferralCode.TIME_BUDGET

        # H11: waiting-aware ETA window check
        candidate_orders = self.orders + [order]
        etas = compute_stop_etas(
            candidate_orders, self.brand, self.district, self.trip_no, ref,
            prev_trip_end_min=prev_trip_end_min, reload_buffer_min=reload_buffer_min
        )
        for eta in etas:
            out = ref.outlets.get(eta.outlet_id)
            if out and eta.arrival_min > hhmm_to_minutes(out.window_close_time):
                return DeferralCode.WINDOW_INFEASIBLE

        # H12: fuel
        new_fuel = compute_trip_fuel(
            len(candidate_orders), ref.districts[self.district], self.vref.km_per_l
        )
        current_fuel = compute_trip_fuel(
            len(self.orders), ref.districts[self.district], self.vref.km_per_l
        ) if self.orders else 0.0
        committed = fuel_committed.get(self.vehicle_id, 0.0)
        if committed - current_fuel + new_fuel > self.vref.weekly_fuel_quota_l:
            return DeferralCode.FUEL_QUOTA

        return None

    def to_trip_plan(self, ref: ReferenceData, prev_trip_end_min: int = 0, reload_buffer: int = 0) -> TripPlan:
        if not self.orders:
            return TripPlan(
                trip_key=self.key,
                vehicle_id=self.vehicle_id,
                trip_no=self.trip_no,
                brand=self.brand,
                district=self.district,
                depot=self.depot,
            )
        district_ref = ref.districts[self.district]
        mins = compute_trip_minutes(self.orders, district_ref, ref, self.brand)
        fuel = compute_trip_fuel(len(self.orders), district_ref, self.vref.km_per_l)
        etas = compute_stop_etas(
            self.orders, self.brand, self.district, self.trip_no, ref,
            prev_trip_end_min=prev_trip_end_min, reload_buffer_min=reload_buffer
        )
        depart_min = compute_depart_time(
            self.brand, self.trip_no, prev_trip_end_min, self.orders, ref, self.district, reload_buffer
        )
        return TripPlan(
            trip_key=self.key,
            vehicle_id=self.vehicle_id,
            trip_no=self.trip_no,
            brand=self.brand,
            district=self.district,
            depot=self.depot,
            orders=list(self.orders),
            stops=etas,
            trip_minutes=mins,
            est_fuel_l=fuel,
            total_weight_kg=self.total_weight(),
            total_volume_m3=self.total_volume(),
            depart_time=minutes_to_hhmm(depart_min),
        )


# ---------------------------------------------------------------------------
# Pre-screen helpers
# ---------------------------------------------------------------------------

def _prescreen_order(
    order: OrderInput,
    available_vrefs: List[VehicleRef],
    ref: ReferenceData,
) -> Optional[str]:
    """
    STEP 1: Returns a DeferralCode if the order is UNAVOIDABLY infeasible,
    else None (order can proceed).
    """
    outlet = ref.outlets.get(order.outlet_id)
    if outlet is None:
        return DeferralCode.WINDOW_INFEASIBLE

    district_ref = ref.districts.get(order.district)
    if district_ref is None:
        return DeferralCode.WINDOW_INFEASIBLE

    depot_vehicles = [v for v in available_vrefs if v.depot == order.depot]

    # NO_REEFER
    if order.temp_requirement == "chilled":
        if not any(v.temp == "reefer" for v in depot_vehicles):
            return DeferralCode.NO_REEFER

    # NO_VAN
    if outlet.parking_constraint == "van_only":
        if not any(v.type == "van" for v in depot_vehicles):
            return DeferralCode.NO_VAN

    # TOO_LARGE: order exceeds every eligible vehicle
    eligible = [v for v in depot_vehicles
                if (order.temp_requirement != "chilled" or v.temp == "reefer")
                and (outlet.parking_constraint != "van_only" or v.type == "van")]
    if not eligible:
        return DeferralCode.WINDOW_INFEASIBLE  # no vehicle passes H2+H3

    largest_weight = max(v.weight_cap_kg for v in eligible)
    largest_volume = max(v.volume_cap_m3 for v in eligible)
    if order.order_weight_kg > largest_weight or order.order_volume_m3 > largest_volume:
        return DeferralCode.TOO_LARGE

    # WINDOW_INFEASIBLE: even a solo trip cannot arrive before the window closes
    trip_mins = compute_trip_minutes([order], district_ref, ref, order.brand)
    budget = BUDGET_FRESH_MIN if order.brand == "Fresh" else BUDGET_STYLE_TECH_MIN
    if trip_mins > budget:
        return DeferralCode.WINDOW_INFEASIBLE

    etas = compute_stop_etas([order], order.brand, order.district, 1, ref)
    if etas:
        close_min = hhmm_to_minutes(outlet.window_close_time)
        if etas[0].arrival_min > close_min:
            return DeferralCode.WINDOW_INFEASIBLE

    return None


# ---------------------------------------------------------------------------
# Vehicle slot selection
# ---------------------------------------------------------------------------

def _eligible_vehicles_for_order(
    order: OrderInput,
    available_vrefs: List[VehicleRef],
    ref: ReferenceData,
) -> List[VehicleRef]:
    """Returns vehicles at the right depot that pass H2, H3."""
    outlet = ref.outlets.get(order.outlet_id)
    result = []
    for vref in available_vrefs:
        if vref.depot != order.depot:
            continue
        if order.temp_requirement == "chilled" and vref.temp != "reefer":
            continue
        if outlet and outlet.parking_constraint == "van_only" and vref.type != "van":
            continue
        result.append(vref)
    return result


def _pick_vehicle_for_new_trip(
    order: OrderInput,
    eligible: List[VehicleRef],
    is_chilled: bool,
) -> Optional[VehicleRef]:
    """
    Pick the smallest sufficient vehicle.
    Prefer ambient trucks for ambient orders (keep reefers free).
    For chilled, a reefer is required (already filtered).
    Sort by: prefer non-reefer if ambient order, then smallest capacity, then vehicle_id for determinism.
    """
    sufficient = [
        v for v in eligible
        if v.weight_cap_kg >= order.order_weight_kg
        and v.volume_cap_m3 >= order.order_volume_m3
    ]
    if not sufficient:
        return None

    def vehicle_sort_key(v: VehicleRef):
        # Prefer ambient trucks for ambient orders (keep reefers free)
        reefer_penalty = 0 if is_chilled else (1 if v.temp == "reefer" else 0)
        return (reefer_penalty, v.weight_cap_kg, v.volume_cap_m3, v.vehicle_id)

    return min(sufficient, key=vehicle_sort_key)


# ---------------------------------------------------------------------------
# Main allocator
# ---------------------------------------------------------------------------

def allocate(inp: AllocatorInput) -> AllocatorOutput:
    """
    Deterministic allocation engine.
    Returns an AllocatorOutput with trips, deferrals, and validation result.
    """
    ref = inp.reference
    output = AllocatorOutput()

    # STEP 0: non-operating day
    if not inp.is_operating:
        for order in inp.orders:
            rec = diagnose_deferral(
                order, DeferralCode.WINDOW_INFEASIBLE, ref,
                [ref.vehicles[vid] for vid in inp.available_vehicle_ids if vid in ref.vehicles],
                {vid: "available" for vid in inp.available_vehicle_ids},
                {},
                order.days_since_last_served,
            )
            output.deferrals.append(rec)
        output.validation = ValidationResult(
            is_valid=False,
            violations=[ViolationDetail("H10", "Not an operating day", 0, 1)]
        )
        return output

    # Build available VehicleRef list (sorted by id for determinism)
    available_vrefs: List[VehicleRef] = sorted(
        [ref.vehicles[vid] for vid in inp.available_vehicle_ids if vid in ref.vehicles],
        key=lambda v: v.vehicle_id,
    )
    all_vrefs = sorted(list(ref.vehicles.values()), key=lambda v: v.vehicle_id)
    vehicle_statuses = {vid: "available" for vid in inp.available_vehicle_ids}
    for vid in ref.vehicles:
        if vid not in inp.available_vehicle_ids:
            vehicle_statuses[vid] = "in_workshop"

    # Build fuel committed map from ledger
    fuel_committed: Dict[str, float] = {}
    for ledger in inp.fuel_ledger:
        fuel_committed[ledger.vehicle_id] = fuel_committed.get(ledger.vehicle_id, 0.0) + ledger.litres_committed

    # Track how many trips each vehicle has used today (including locked)
    trips_per_vehicle: Dict[str, int] = {}
    fresh_budget: Dict[str, float] = {}
    style_tech_budget: Dict[str, float] = {}
    vehicle_fresh_end: Dict[str, int] = {}

    # Initialize locked slots (preserved as fixed input)
    for locked in inp.locked_slots:
        trips_per_vehicle[locked.vehicle_id] = max(trips_per_vehicle.get(locked.vehicle_id, 0), locked.trip_no)
        fuel_committed[locked.vehicle_id] = fuel_committed.get(locked.vehicle_id, 0.0) + locked.current_fuel_l
        if locked.brand == "Fresh":
            fresh_budget[locked.vehicle_id] = fresh_budget.get(locked.vehicle_id, 0.0) + locked.current_trip_minutes
        else:
            style_tech_budget[locked.vehicle_id] = style_tech_budget.get(locked.vehicle_id, 0.0) + locked.current_trip_minutes

        prev_end = vehicle_fresh_end.get(locked.vehicle_id, 0)
        locked_etas = compute_stop_etas(
            locked.orders, locked.brand or "Fresh", locked.district or "", locked.trip_no, ref,
            prev_trip_end_min=prev_end, reload_buffer_min=inp.reload_buffer_min
        )
        locked_depart = compute_depart_time(
            locked.brand or "Fresh", locked.trip_no, prev_end, locked.orders, ref, locked.district or "", inp.reload_buffer_min
        )
        output.trips.append(TripPlan(
            trip_key=f"{locked.vehicle_id}_trip{locked.trip_no}",
            vehicle_id=locked.vehicle_id,
            trip_no=locked.trip_no,
            brand=locked.brand or "",
            district=locked.district or "",
            depot=locked.vehicle_ref.depot,
            orders=list(locked.orders),
            stops=locked_etas,
            trip_minutes=locked.current_trip_minutes,
            est_fuel_l=locked.current_fuel_l,
            total_weight_kg=locked.used_weight_kg,
            total_volume_m3=locked.used_volume_m3,
            depart_time=minutes_to_hhmm(locked_depart),
        ))
        if locked.brand == "Fresh":
            end = trip_end_min(locked_etas)
            if end > vehicle_fresh_end.get(locked.vehicle_id, 0):
                vehicle_fresh_end[locked.vehicle_id] = end

    # Track open mutable trips
    open_trips: Dict[str, _TripState] = {}  # key: "{vehicle_id}_trip{n}"

    priority_config = inp.priority_config or DEFAULT_PRIORITY_CONFIG

    # STEP 1: pre-screen
    remaining: List[OrderInput] = []
    for order in inp.orders:
        code = _prescreen_order(order, available_vrefs, ref)
        if code:
            rec = diagnose_deferral(
                order, code, ref, all_vrefs, vehicle_statuses, fuel_committed,
                order.days_since_last_served,
            )
            output.deferrals.append(rec)
        else:
            remaining.append(order)

    # STEP 2: rank
    ranked = rank_orders(remaining, ref, priority_config)

    # STEP 3: allocate each order
    for order in ranked:
        placed = False

        # 3a: find existing open trips (same depot, brand, district), sorted deterministically
        candidates = sorted(
            [
                t for t in open_trips.values()
                if t.depot == order.depot
                and t.brand == order.brand
                and t.district == order.district
            ],
            key=lambda t: t.key,
        )

        best_fit: Optional[_TripState] = None
        for trip in candidates:
            fb = fresh_budget.get(trip.vehicle_id, 0.0)
            stb = style_tech_budget.get(trip.vehicle_id, 0.0)
            prev_end = vehicle_fresh_end.get(trip.vehicle_id, 0) if trip.trip_no == 2 else 0
            reject = trip.can_accept(
                order, ref, fuel_committed, fb, stb,
                prev_trip_end_min=prev_end, reload_buffer_min=inp.reload_buffer_min
            )
            if reject is None:
                if best_fit is None:
                    best_fit = trip
                else:
                    # Best fit: smallest remaining weight capacity
                    rem_current = best_fit.vref.weight_cap_kg - best_fit.total_weight()
                    rem_cand = trip.vref.weight_cap_kg - trip.total_weight()
                    if rem_cand < rem_current:
                        best_fit = trip

        if best_fit is not None:
            old_mins = best_fit.trip_minutes(ref)
            best_fit.orders.append(order)
            new_mins = best_fit.trip_minutes(ref)
            diff_mins = new_mins - old_mins

            # Update fuel committed
            dist = ref.districts[best_fit.district]
            old_fuel = compute_trip_fuel(len(best_fit.orders) - 1, dist, best_fit.vref.km_per_l) if len(best_fit.orders) > 1 else 0.0
            new_fuel = compute_trip_fuel(len(best_fit.orders), dist, best_fit.vref.km_per_l)
            fuel_committed[best_fit.vehicle_id] = fuel_committed.get(best_fit.vehicle_id, 0.0) - old_fuel + new_fuel

            # Update budget
            if best_fit.brand == "Fresh":
                fresh_budget[best_fit.vehicle_id] = fresh_budget.get(best_fit.vehicle_id, 0.0) + diff_mins
                etas = compute_stop_etas(
                    best_fit.orders, best_fit.brand, best_fit.district, best_fit.trip_no, ref,
                    prev_trip_end_min=vehicle_fresh_end.get(best_fit.vehicle_id, 0) if best_fit.trip_no == 2 else 0,
                    reload_buffer_min=inp.reload_buffer_min
                )
                end = trip_end_min(etas)
                if end > vehicle_fresh_end.get(best_fit.vehicle_id, 0):
                    vehicle_fresh_end[best_fit.vehicle_id] = end
            else:
                style_tech_budget[best_fit.vehicle_id] = style_tech_budget.get(best_fit.vehicle_id, 0.0) + diff_mins
            placed = True
        else:
            # 3b: open a new trip on an eligible vehicle slot
            is_chilled = order.temp_requirement == "chilled"
            eligible = _eligible_vehicles_for_order(order, available_vrefs, ref)
            eligible_open = []
            for vref in eligible:
                tc = trips_per_vehicle.get(vref.vehicle_id, 0)
                if tc >= MAX_TRIPS_PER_VEHICLE_PER_DAY:
                    continue

                single_mins = compute_trip_minutes([order], ref.districts[order.district], ref, order.brand)
                if order.brand == "Fresh":
                    if fresh_budget.get(vref.vehicle_id, 0.0) + single_mins > BUDGET_FRESH_MIN:
                        continue
                else:
                    if style_tech_budget.get(vref.vehicle_id, 0.0) + single_mins > BUDGET_STYLE_TECH_MIN:
                        continue

                fuel_for_1 = compute_trip_fuel(1, ref.districts[order.district], vref.km_per_l)
                if fuel_committed.get(vref.vehicle_id, 0.0) + fuel_for_1 > vref.weekly_fuel_quota_l:
                    continue

                if order.order_weight_kg > vref.weight_cap_kg:
                    continue
                if order.order_volume_m3 > vref.volume_cap_m3:
                    continue

                # Check H11 for single stop on new trip
                prev_end = vehicle_fresh_end.get(vref.vehicle_id, 0)
                single_etas = compute_stop_etas(
                    [order], order.brand, order.district, tc + 1, ref,
                    prev_trip_end_min=prev_end, reload_buffer_min=inp.reload_buffer_min
                )
                out = ref.outlets.get(order.outlet_id)
                if single_etas and out and single_etas[0].arrival_min > hhmm_to_minutes(out.window_close_time):
                    continue

                eligible_open.append(vref)

            chosen_vref = _pick_vehicle_for_new_trip(order, eligible_open, is_chilled)

            if chosen_vref is not None:
                tc = trips_per_vehicle.get(chosen_vref.vehicle_id, 0)
                trip_no = tc + 1
                new_trip = _TripState(
                    vehicle_id=chosen_vref.vehicle_id,
                    trip_no=trip_no,
                    brand=order.brand,
                    district=order.district,
                    depot=order.depot,
                    vref=chosen_vref,
                )
                new_trip.orders.append(order)
                open_trips[new_trip.key] = new_trip
                trips_per_vehicle[chosen_vref.vehicle_id] = trip_no

                single_mins = new_trip.trip_minutes(ref)
                if order.brand == "Fresh":
                    fresh_budget[chosen_vref.vehicle_id] = fresh_budget.get(chosen_vref.vehicle_id, 0.0) + single_mins
                    prev_end = vehicle_fresh_end.get(chosen_vref.vehicle_id, 0)
                    etas = compute_stop_etas(
                        new_trip.orders, new_trip.brand, new_trip.district, new_trip.trip_no, ref,
                        prev_trip_end_min=prev_end, reload_buffer_min=inp.reload_buffer_min
                    )
                    end = trip_end_min(etas)
                    if end > vehicle_fresh_end.get(chosen_vref.vehicle_id, 0):
                        vehicle_fresh_end[chosen_vref.vehicle_id] = end
                else:
                    style_tech_budget[chosen_vref.vehicle_id] = style_tech_budget.get(chosen_vref.vehicle_id, 0.0) + single_mins

                fuel_1 = compute_trip_fuel(1, ref.districts[order.district], chosen_vref.km_per_l)
                fuel_committed[chosen_vref.vehicle_id] = fuel_committed.get(chosen_vref.vehicle_id, 0.0) + fuel_1
                placed = True
            else:
                # 3c: defer with diagnosed reason
                all_eligible = _eligible_vehicles_for_order(order, available_vrefs, ref)
                if not all_eligible:
                    code = DeferralCode.NO_REEFER if is_chilled else DeferralCode.WINDOW_INFEASIBLE
                elif all(trips_per_vehicle.get(v.vehicle_id, 0) >= MAX_TRIPS_PER_VEHICLE_PER_DAY for v in all_eligible):
                    code = DeferralCode.TRIP_LIMIT
                else:
                    free_slot_vehicles = [v for v in all_eligible if trips_per_vehicle.get(v.vehicle_id, 0) < MAX_TRIPS_PER_VEHICLE_PER_DAY]
                    if free_slot_vehicles and all(
                        fuel_committed.get(v.vehicle_id, 0.0) + compute_trip_fuel(1, ref.districts[order.district], v.km_per_l) > v.weekly_fuel_quota_l
                        for v in free_slot_vehicles
                    ):
                        code = DeferralCode.FUEL_QUOTA
                    elif free_slot_vehicles and all(
                        ((fresh_budget.get(v.vehicle_id, 0.0) + compute_trip_minutes([order], ref.districts[order.district], ref, order.brand) > BUDGET_FRESH_MIN)
                         if order.brand == "Fresh" else
                         (style_tech_budget.get(v.vehicle_id, 0.0) + compute_trip_minutes([order], ref.districts[order.district], ref, order.brand) > BUDGET_STYLE_TECH_MIN))
                        for v in free_slot_vehicles
                    ):
                        code = DeferralCode.TIME_BUDGET
                    elif free_slot_vehicles and all(
                        (order.order_weight_kg > v.weight_cap_kg or order.order_volume_m3 > v.volume_cap_m3)
                        for v in free_slot_vehicles
                    ):
                        code = DeferralCode.CAPACITY_FULL
                    else:
                        code = DeferralCode.CAPACITY_FULL

                rec = diagnose_deferral(
                    order, code, ref, all_vrefs, vehicle_statuses, fuel_committed,
                    order.days_since_last_served,
                )
                output.deferrals.append(rec)

    # STEP 4: finalize open trips and build TripPlan objects
    # Recompute end times in order of trip 1 then trip 2
    for trip_no in [1, 2]:
        for t in sorted(open_trips.values(), key=lambda t: t.key):
            if t.trip_no == trip_no:
                prev_end = vehicle_fresh_end.get(t.vehicle_id, 0) if t.trip_no == 2 else 0
                plan = t.to_trip_plan(ref, prev_end, inp.reload_buffer_min)
                output.trips.append(plan)
                if t.brand == "Fresh":
                    end = trip_end_min(plan.stops) if plan.stops else 0
                    if end > vehicle_fresh_end.get(t.vehicle_id, 0):
                        vehicle_fresh_end[t.vehicle_id] = end

    # Sort output trips deterministically by (vehicle_id, trip_no)
    output.trips.sort(key=lambda t: (t.vehicle_id, t.trip_no))

    # STEP 5: validate the whole plan
    vehicle_statuses_final = {vid: "available" for vid in inp.available_vehicle_ids}
    prev_fresh_end_map: Dict[str, int] = {}
    validation = validate_plan(output.trips, inp, vehicle_statuses_final, prev_fresh_end_map)
    output.validation = validation

    # Flag alerts for consecutive deferrals
    for def_rec in output.deferrals:
        details = def_rec.details or {}
        consecutive = details.get("consecutive_deferrals", 0)
        if consecutive >= 1:
            output.needs_alert.append(def_rec.order_id)

    return output
