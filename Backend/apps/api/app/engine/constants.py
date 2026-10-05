"""
constants.py – single source for rule IDs, budgets, reason codes and config defaults.
No values are hard-coded here that exist in the CSVs; all CSV-derived values come in
via the ReferenceData dataclass at runtime.
"""

# --- Hard constraint IDs (H1-H12) ---
RULES = {
    "H1": "One trip = one vehicle + one trip number; same brand and district.",
    "H2": "Chilled order requires a reefer vehicle.",
    "H3": "van_only outlet requires a van vehicle.",
    "H4": "Vehicle serves only its own depot.",
    "H5": "Whole orders only; no splitting.",
    "H6": "Trip weight and volume within vehicle capacity.",
    "H7": "At most 2 trips per vehicle per day.",
    "H8": "Trip time within daily budget (formula, no waiting).",
    "H9": "Only available vehicles (not in_workshop).",
    "H10": "Deliver only on operating calendar days.",
    "H11": "Every stop arrival within outlet window (waiting-aware ETA).",
    "H12": "Weekly fuel litres within vehicle quota.",
}

# --- Time budgets (minutes) ---
BUDGET_FRESH_MIN = 270        # Fresh trips: sum of all Fresh trip_minutes <= 270
BUDGET_STYLE_TECH_MIN = 480   # Style + Tech trips combined <= 480

FRESH_DEPART_TIME = "03:30"   # Fresh trip 1 departs at 03:30

# --- Deferral reason codes ---
class DeferralCode:
    NO_REEFER           = "NO_REEFER"
    NO_VAN              = "NO_VAN"
    TOO_LARGE           = "TOO_LARGE"
    WINDOW_INFEASIBLE   = "WINDOW_INFEASIBLE"
    CAPACITY_FULL       = "CAPACITY_FULL"
    TIME_BUDGET         = "TIME_BUDGET"
    TRIP_LIMIT          = "TRIP_LIMIT"
    FUEL_QUOTA          = "FUEL_QUOTA"
    SHORTFALL           = "SHORTFALL"
    DELIVERY_FAILED     = "DELIVERY_FAILED"
    EXCEPTION_SKIPPED   = "EXCEPTION_SKIPPED"
    MANUAL              = "MANUAL"

# --- Deferral classes ---
class DeferralClass:
    UNAVOIDABLE  = "UNAVOIDABLE"
    CHOICE       = "CHOICE"
    OPERATIONAL  = "OPERATIONAL"
    DISPATCHER   = "DISPATCHER"

# Default class per reason code
DEFERRAL_CLASS_DEFAULT = {
    DeferralCode.NO_REEFER:         DeferralClass.UNAVOIDABLE,
    DeferralCode.NO_VAN:            DeferralClass.UNAVOIDABLE,
    DeferralCode.TOO_LARGE:         DeferralClass.UNAVOIDABLE,
    DeferralCode.WINDOW_INFEASIBLE: DeferralClass.UNAVOIDABLE,
    DeferralCode.CAPACITY_FULL:     DeferralClass.CHOICE,
    DeferralCode.TIME_BUDGET:       DeferralClass.CHOICE,
    DeferralCode.TRIP_LIMIT:        DeferralClass.CHOICE,
    DeferralCode.FUEL_QUOTA:        DeferralClass.CHOICE,
    DeferralCode.SHORTFALL:         DeferralClass.OPERATIONAL,
    DeferralCode.DELIVERY_FAILED:   DeferralClass.OPERATIONAL,
    DeferralCode.EXCEPTION_SKIPPED: DeferralClass.OPERATIONAL,
    DeferralCode.MANUAL:            DeferralClass.DISPATCHER,
}

# --- Priority config defaults (lexicographic) ---
DEFAULT_PRIORITY_CONFIG = {
    "p1_deferred_yesterday": True,
    "p2_days_since_last_served": True,
    "p3_brand_temp_order": ["Fresh/chilled", "Fresh/ambient", "Style", "Tech"],
    "p4_window_close_time": True,
    "p5_service_cost": True,
    "p6_order_ref": True,
}

# --- Misc ---
MAX_TRIPS_PER_VEHICLE_PER_DAY = 2
RELOAD_BUFFER_MIN = 0  # configurable; default 0
