// apps/web/src/features/store-manager/pages/StoreManagerHome.tsx
// SM1 Home (desktop layout) built from the Figma frame "Store Manager Home (Desktop)".
// Needs: react, tailwindcss, lucide-react. Colours use Tailwind arbitrary values; move them into tailwind.config tokens later.
//
// Departures from the Figma (list in the README):
//  - "Crates" become units (D4: no SKUs or line items); kg and m3 are shown where available.
//  - Header outlet, vehicle, driver, order ids, ETAs and counts come from the API, not from the Figma placeholders.
//  - The cutoff countdown uses business_now() from GET /ref/config (D11), never the browser clock.
//  - "Review Reschedule" opens the deferral notice (SM3); there is no approval step in the contract.

import { useMemo, useState } from "react";
import {
  AlertTriangle, CalendarX, CheckCircle2, Clock, FileText, Info, Package,
  ShoppingCart, Snowflake, Truck, Crosshair, ExternalLink, RotateCw,
} from "lucide-react";

/* ---------- Types (map these from the generated OpenAPI client) ---------- */

export type OrderStatus =
  | "SUBMITTED" | "PLANNED" | "SCHEDULED" | "LOADED" | "IN_TRANSIT"
  | "DELIVERED" | "PARTIALLY_DELIVERED" | "DEFERRED" | "CANCELLED";

export interface ConsignmentRow {
  id: string;                 // order id
  ref: string;                // display reference
  brandLabel: string;         // e.g. "Waypoint Fresh"
  temperature: "ambient" | "chilled";
  units: number;
  weightKg: number;
  volumeM3: number;
  status: OrderStatus;
  eta?: string;               // "HH:MM"
  etaDay?: string;            // "Tomorrow" | "Today" | date
  deliveredAt?: string;       // "HH:MM"
  stopId?: string;
  receiptStatus?: "NONE" | "AWAITING" | "CONFIRMED" | "DISCREPANCY";
  note?: string;
}

export interface NextDelivery {
  vehicleId: string;          // e.g. "VEH014"
  vehicleDesc: string;        // e.g. "Reefer truck"
  driverName: string;
  depotName: string;          // e.g. "Peliyagoda Hub"
  units: number;
  ambientUnits: number;
  chilledUnits: number;
  eta?: string;
}

export interface DeferralNotice {
  orderRef: string;
  message: string;
}

export interface StoreManagerHomeProps {
  managerName: string;
  outletLabel: string;        // "Waypoint Fresh, Gampaha (OUT018)"
  depotNode: string;          // footer "Regional Node"
  outletId: string;
  online: boolean;
  syncState: string;          // "Normal" | "Syncing"
  cutoffRemainingMin: number | null; // from business_now(); null while loading
  cutoffLabel?: string;       // "4:00 PM"
  deliveryDayLabel?: string;  // "Tomorrow's Restock"
  notice?: DeferralNotice | null;
  nextDelivery?: NextDelivery | null;
  consignments: ConsignmentRow[];
  onNavigate?: (to: string) => void; // wire to react-router's navigate
}

/* ---------- Demo data so the file renders on its own ---------- */

const demo: StoreManagerHomeProps = {
  managerName: "Nimali Fernando",
  outletLabel: "Waypoint Fresh, Gampaha (OUT018)",
  depotNode: "Peliyagoda Hub",
  outletId: "OUT018",
  online: true,
  syncState: "Normal",
  cutoffRemainingMin: 98,
  notice: {
    orderRef: "#C-2289",
    message: "Chilled order #C-2289 was deferred: all eligible trips were full. New expected date is shown on the order.",
  },
  nextDelivery: {
    vehicleId: "VEH014", vehicleDesc: "Reefer truck", driverName: "Chaminda B.",
    depotName: "Peliyagoda Hub", units: 42, ambientUnits: 28, chilledUnits: 14, eta: "06:45",
  },
  consignments: [
    { id: "o1", ref: "#F-9412", brandLabel: "Waypoint Fresh", temperature: "ambient", units: 28, weightKg: 410, volumeM3: 3.2, status: "IN_TRANSIT", eta: "06:45", etaDay: "Tomorrow" },
    { id: "o2", ref: "#C-2291", brandLabel: "Waypoint Fresh", temperature: "chilled", units: 14, weightKg: 190, volumeM3: 1.6, status: "SCHEDULED", eta: "06:50", etaDay: "Tomorrow" },
    { id: "o3", ref: "#C-2289", brandLabel: "Waypoint Fresh", temperature: "chilled", units: 12, weightKg: 160, volumeM3: 1.4, status: "DEFERRED" },
    { id: "o4", ref: "#D-8820", brandLabel: "Waypoint Fresh", temperature: "ambient", units: 35, weightKg: 520, volumeM3: 4.0, status: "DELIVERED", deliveredAt: "06:52", stopId: "s4", receiptStatus: "AWAITING" },
  ],
};

/* ---------- Helpers ---------- */

type Filter = "all" | "progress" | "done";
const IN_PROGRESS: OrderStatus[] = ["SUBMITTED", "PLANNED", "SCHEDULED", "LOADED", "IN_TRANSIT"];
const DONE: OrderStatus[] = ["DELIVERED", "PARTIALLY_DELIVERED"];

const fmtRemaining = (min: number | null) => {
  if (min === null) return "--";
  if (min <= 0) return "Closed";
  return `${String(Math.floor(min / 60)).padStart(2, "0")}h ${String(min % 60).padStart(2, "0")}m`;
};

const statusStyle: Record<OrderStatus, { label: string; pill: string; row: string; iconBg: string }> = {
  SUBMITTED: { label: "Received", pill: "bg-[#2B6E62] text-white", row: "bg-[#B8D8CC]", iconBg: "bg-[#DCEBE5]" },
  PLANNED: { label: "Planned", pill: "bg-[#2B6E62] text-white", row: "bg-[#B8D8CC]", iconBg: "bg-[#DCEBE5]" },
  SCHEDULED: { label: "Scheduled", pill: "bg-[#0F6B3E] text-white", row: "bg-[#B8D8CC]", iconBg: "bg-[#E8EFEA]" },
  LOADED: { label: "Loaded", pill: "bg-[#0F6B3E] text-white", row: "bg-[#B8D8CC]", iconBg: "bg-[#DCEBE5]" },
  IN_TRANSIT: { label: "On the way", pill: "bg-[#0F6B3E] text-white", row: "bg-[#B8D8CC]", iconBg: "bg-[#DCEBE5]" },
  DELIVERED: { label: "Delivered", pill: "bg-[#CFF1E4] text-[#0F5C45] border border-[#7CC7AE]", row: "bg-[#B8D8CC]", iconBg: "bg-[#CFF1E4]" },
  PARTIALLY_DELIVERED: { label: "Partly delivered", pill: "bg-[#CFF1E4] text-[#0F5C45] border border-[#7CC7AE]", row: "bg-[#B8D8CC]", iconBg: "bg-[#CFF1E4]" },
  DEFERRED: { label: "Deferred", pill: "bg-[#E9B9A5] text-[#7A2E10]", row: "bg-[#FFD9CC]", iconBg: "bg-[#F2BFAA]" },
  CANCELLED: { label: "Cancelled", pill: "bg-gray-200 text-gray-700", row: "bg-gray-100", iconBg: "bg-gray-200" },
};

function StatusIcon({ row }: { row: ConsignmentRow }) {
  const cls = "h-5 w-5 text-[#2B5A50]";
  if (row.status === "DEFERRED") return <CalendarX className="h-5 w-5 text-[#8A3A1C]" />;
  if (row.status === "DELIVERED" || row.status === "PARTIALLY_DELIVERED") return <CheckCircle2 className={cls} />;
  if (row.temperature === "chilled") return <Snowflake className={cls} />;
  return <Truck className={cls} />;
}

function rowAction(row: ConsignmentRow): { label: string; icon: JSX.Element; to: string } {
  switch (row.status) {
    case "IN_TRANSIT": return { label: "Track delivery", icon: <Crosshair className="h-3.5 w-3.5" />, to: `/store/orders/${row.id}` };
    case "DEFERRED": return { label: "View deferral", icon: <RotateCw className="h-3.5 w-3.5" />, to: "/store/notifications" };
    case "DELIVERED":
    case "PARTIALLY_DELIVERED":
      return row.receiptStatus === "AWAITING"
        ? { label: "Confirm receipt", icon: <FileText className="h-3.5 w-3.5" />, to: `/store/orders/${row.id}/receipt` }
        : { label: "View receipt", icon: <FileText className="h-3.5 w-3.5" />, to: `/store/orders/${row.id}` };
    default: return { label: "View details", icon: <ExternalLink className="h-3.5 w-3.5" />, to: `/store/orders/${row.id}` };
  }
}

function rowMeta(row: ConsignmentRow): string {
  if (row.status === "DEFERRED") return "Waiting for a new delivery date";
  if (row.status === "DELIVERED" || row.status === "PARTIALLY_DELIVERED") return `Delivered today at ${row.deliveredAt ?? "--:--"}`;
  return row.eta ? `ETA: ${row.eta} (${row.etaDay ?? "Tomorrow"})` : "ETA not set yet";
}

/* ---------- Component ---------- */

export default function StoreManagerHome(props: Partial<StoreManagerHomeProps>) {
  const p = { ...demo, ...props };
  const [filter, setFilter] = useState<Filter>("all");
  const go = (to: string) => p.onNavigate?.(to);

  const rows = useMemo(() => p.consignments.filter((r) =>
    filter === "all" ? true : filter === "progress" ? IN_PROGRESS.includes(r.status) : DONE.includes(r.status)
  ), [p.consignments, filter]);

  const count = (f: Filter) => p.consignments.filter((r) =>
    f === "all" ? true : f === "progress" ? IN_PROGRESS.includes(r.status) : DONE.includes(r.status)).length;

  const closed = p.cutoffRemainingMin !== null && p.cutoffRemainingMin <= 0;
  const locking = p.cutoffRemainingMin !== null && p.cutoffRemainingMin > 0 && p.cutoffRemainingMin <= 120;

  return (
    <div className="min-h-screen bg-[#0F4C45] p-4 font-sans text-[#1E2B27]">
      <div className="mx-auto flex min-h-[calc(100vh-2rem)] max-w-[1040px] flex-col bg-white shadow-xl">
        {/* Top bar */}
        <header className="grid grid-cols-[1fr_auto_1fr] items-center border-b border-gray-100 px-6 py-3">
          <div className="flex items-center gap-3">
            <div className="flex h-9 w-12 items-center justify-center rounded bg-[#E3F1EC]"><Truck className="h-5 w-5 text-[#1F7A8C]" /></div>
            <div>
              <p className="text-sm font-bold leading-tight">WAYPOINT express <span className="ml-1 text-xs font-semibold text-[#2B6E62]">Store Manager</span></p>
              <p className="text-[11px] text-gray-600">
                {p.outletLabel}{" "}
                <span className={`ml-1 rounded px-1.5 py-0.5 text-[10px] font-semibold ${p.online ? "bg-[#DCEFE6] text-[#0F6B3E]" : "bg-amber-100 text-amber-800"}`}>
                  ● {p.online ? "Online" : "Offline"}
                </span>
              </p>
            </div>
          </div>
          <nav aria-label="Main" className="flex gap-1 rounded-xl bg-[#F4F1E6] p-1">
            {[["Home", "/store"], ["Orders", "/store/orders"], ["Tracking", "/store/tracking"]].map(([l, to], i) => (
              <button key={l} onClick={() => go(to)} aria-current={i === 0 ? "page" : undefined}
                className={`rounded-lg px-4 py-1.5 text-xs font-semibold focus:outline-none focus-visible:ring-2 focus-visible:ring-[#2B6E62] ${i === 0 ? "bg-[#2B6E62] text-white" : "text-gray-700 hover:bg-white"}`}>{l}</button>
            ))}
          </nav>
          <div className="flex items-center justify-end gap-2 text-right">
            <div><p className="text-xs font-semibold">{p.managerName}</p><p className="text-[10px] text-gray-500">Store Manager</p></div>
            <div className="h-6 w-6 rounded-full bg-gradient-to-br from-gray-800 to-gray-300" aria-hidden />
          </div>
        </header>

        <main className="flex-1 px-14 pb-10 pt-10">
          {/* Deferral notice */}
          {p.notice && (
            <button onClick={() => go("/store/notifications")}
              className="mt-6 flex w-full items-center gap-3 rounded-xl bg-[#FFDDD0] px-3 py-2.5 text-left shadow-sm focus:outline-none focus-visible:ring-2 focus-visible:ring-[#8A3A1C]">
              <span className="flex h-9 w-9 items-center justify-center rounded-lg bg-[#7A3A1C] text-white"><AlertTriangle className="h-5 w-5" /></span>
              <span>
                <span className="block text-[10px] font-bold uppercase tracking-wide text-[#8A3A1C]">Deferral notice</span>
                <span className="block text-sm">{p.notice.message}</span>
              </span>
            </button>
          )}

          {/* Next delivery + cutoff */}
          <section className="mt-4 grid grid-cols-2 gap-5">
            <div className="min-h-[240px] rounded-2xl bg-[#85B9A5] p-4">
              <h2 className="flex items-center gap-2 text-lg font-bold text-[#16322B]"><Truck className="h-4 w-4" />Next scheduled delivery</h2>
              {p.nextDelivery ? (
                <div className="mt-4 grid grid-cols-3 gap-2">
                  <div className="rounded-md bg-white p-2.5 shadow-sm">
                    <p className="text-[10px] text-gray-500">Vehicle</p>
                    <p className="text-sm font-bold">{p.nextDelivery.vehicleId}</p>
                    <p className="text-[10px] text-gray-500">{p.nextDelivery.vehicleDesc}</p>
                  </div>
                  <div className="rounded-md bg-white p-2.5 shadow-sm">
                    <p className="text-[10px] text-gray-500">Driver</p>
                    <p className="text-sm font-bold">{p.nextDelivery.driverName}</p>
                    <p className="text-[10px] text-gray-500">{p.nextDelivery.depotName}</p>
                  </div>
                  <div className="rounded-md bg-white p-2.5 shadow-sm">
                    <p className="text-[10px] text-gray-500">Total load</p>
                    <p className="text-sm font-bold text-[#0F5C45]">{p.nextDelivery.units} <span className="text-[10px] font-medium text-gray-600">units</span></p>
                    <p className="text-[10px] text-gray-500">{p.nextDelivery.ambientUnits} ambient / {p.nextDelivery.chilledUnits} chilled</p>
                  </div>
                </div>
              ) : (
                <p className="mt-6 rounded-md bg-white/60 p-3 text-sm">No delivery is scheduled yet. Orders placed before the cutoff appear here once the dispatcher confirms a trip.</p>
              )}
            </div>

            <div className="rounded-2xl border border-gray-100 p-4">
              <div className="flex items-baseline justify-between">
                <h2 className="text-lg font-bold">{p.deliveryDayLabel ?? "Tomorrow's restock"}</h2>
                <span className="text-xs font-medium text-gray-600">Next run</span>
              </div>
              <p className="mt-1 max-w-[260px] text-[11px] leading-snug text-gray-500">Order deadline for fresh produce, bakery and chilled lines.</p>
              <div className="mt-3 rounded-lg bg-[#F5F0E3] p-3">
                <div className="flex items-center justify-between text-[11px] font-semibold">
                  <span className="flex items-center gap-1"><Clock className="h-3.5 w-3.5 text-[#2B6E62]" />{p.cutoffLabel ?? "4:00 PM"} cutoff</span>
                  {(locking || closed) && <span className="rounded bg-gray-200 px-1.5 py-0.5 text-[9px] font-medium">{closed ? "Closed" : "Locking soon"}</span>}
                </div>
                <p className="mt-1 text-3xl font-extrabold text-[#0F5C45]" aria-live="polite">
                  {fmtRemaining(p.cutoffRemainingMin)}
                  {!closed && p.cutoffRemainingMin !== null && <span className="ml-2 text-xs font-medium text-gray-600">remaining today</span>}
                </p>
                {closed && <p className="mt-1 flex items-center gap-1 text-[11px] text-gray-600"><Info className="h-3 w-3" />New orders roll to the next operating day.</p>}
              </div>
              <button onClick={() => go("/store/orders/new")}
                className="mt-4 flex w-full items-center justify-center gap-2 rounded-lg bg-[#2B6E62] py-3 text-sm font-semibold text-white hover:bg-[#245C52] focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#2B6E62]">
                <ShoppingCart className="h-4 w-4" />Place new order
              </button>
            </div>
          </section>

          {/* Consignments */}
          <section className="mt-9" aria-labelledby="consignments">
            <div className="flex items-end justify-between">
              <div>
                <p className="flex items-center gap-1 text-[9px] font-bold uppercase tracking-wide text-gray-500"><Package className="h-3 w-3" />Store receiving manifest</p>
                <h2 id="consignments" className="text-lg font-bold">Active &amp; recent consignments</h2>
              </div>
              <div role="tablist" className="flex gap-1 rounded-lg bg-[#F4F1E6] p-1 text-[11px] font-semibold">
                {([["all", "All orders"], ["progress", "In progress"], ["done", "Completed"]] as [Filter, string][]).map(([k, l]) => (
                  <button key={k} role="tab" aria-selected={filter === k} onClick={() => setFilter(k)}
                    className={`rounded-md px-3 py-1.5 ${filter === k ? "bg-white shadow-sm" : "text-gray-600 hover:bg-white/60"}`}>{l} ({count(k)})</button>
                ))}
              </div>
            </div>

            <ul className="mt-3 space-y-2.5">
              {rows.length === 0 && (
                <li className="rounded-xl border border-dashed border-gray-300 p-6 text-center text-sm text-gray-500">
                  No orders in this view. Place an order before the cutoff to see it here.
                </li>
              )}
              {rows.map((r) => {
                const s = statusStyle[r.status]; const a = rowAction(r);
                return (
                  <li key={r.id} className={`flex items-center justify-between rounded-xl px-3 py-2.5 ${s.row}`}>
                    <div className="flex items-center gap-3">
                      <span className={`flex h-10 w-10 items-center justify-center rounded-lg ${s.iconBg}`}><StatusIcon row={r} /></span>
                      <div>
                        <p className="text-sm">
                          <span className={`font-bold ${r.status === "DEFERRED" ? "text-[#8A3A1C]" : ""}`}>{r.ref}</span>{" "}
                          <span className="font-semibold">{r.brandLabel} • {r.temperature === "chilled" ? "Chilled" : "Ambient"}</span>
                          {r.note && <span className="ml-1.5 text-[10px] text-gray-600">{r.note}</span>}
                        </p>
                        <p className="mt-0.5 text-[11px] text-gray-700">
                          {r.units} units • {r.weightKg} kg • {r.volumeM3} m³ • {rowMeta(r)}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <span className={`rounded px-2 py-0.5 text-[10px] font-semibold ${s.pill}`}>
                        {r.status === "DEFERRED" && <AlertTriangle className="mr-1 inline h-3 w-3" />}{s.label}
                      </span>
                      <button onClick={() => go(a.to)}
                        className="flex items-center gap-1.5 rounded-lg bg-white px-3.5 py-2 text-xs font-semibold shadow-sm hover:bg-gray-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-[#2B6E62]">
                        {a.label}{a.icon}
                      </button>
                    </div>
                  </li>
                );
              })}
            </ul>
          </section>
        </main>

        <footer className="flex justify-between border-t border-gray-200 bg-[#F6F4EC] px-4 py-2 text-[10px] font-medium text-gray-600">
          <span>Waypoint Logistics OS • Store Dispatch Terminal</span>
          <span>Outlet ID: {p.outletId}&nbsp;&nbsp; Regional node: {p.depotNode}&nbsp;&nbsp; Sync state: {p.syncState}</span>
        </footer>
      </div>
    </div>
  );
}
