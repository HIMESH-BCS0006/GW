# API Endpoint Coverage & Screen Mapping

This document maps all contract endpoints from `docs/spec/03-api-contract.md` to their unique OpenAPI `operationId` in `docs/spec/openapi.yaml`, and maps every screen action from `docs/spec/04-screens-and-departures.md` to its corresponding operation.

---

## 1. Contract Endpoint Coverage Table

| Method | Contract Endpoint Path | Operation ID | Role Tag | Status |
|--------|------------------------|--------------|----------|--------|
| POST | `/auth/login` | `login` | auth | Covered |
| GET | `/me` | `getCurrentUser` | auth | Covered |
| GET | `/ref/outlets` | `getRefOutlets` | reference | Covered |
| GET | `/ref/vehicles` | `getRefVehicles` | reference | Covered |
| GET | `/ref/calendar` | `getRefCalendar` | reference | Covered |
| GET | `/ref/config` | `getRefConfig` | reference | Covered |
| POST | `/orders` | `createOrder` | store_manager | Covered |
| GET | `/orders` | `listOrders` | store_manager | Covered |
| GET | `/orders/{id}` | `getOrderById` | store_manager | Covered |
| POST | `/orders/{id}/cancel` | `cancelOrder` | store_manager | Covered |
| GET | `/outlets/{id}/expected-deliveries` | `getOutletExpectedDeliveries` | store_manager | Covered |
| POST | `/stops/{id}/receipt` | `recordStopReceipt` | store_manager | Covered |
| GET | `/notifications` | `listNotifications` | store_manager | Covered |
| POST | `/notifications/{id}/read` | `markNotificationRead` | store_manager | Covered |
| GET | `/dashboard` | `getDashboard` | dispatcher | Covered |
| GET | `/dispatch/queue` | `getDispatchQueue` | dispatcher | Covered |
| POST | `/plans/generate` | `generatePlan` | dispatcher | Covered |
| GET | `/plans` | `listPlans` | dispatcher | Covered |
| GET | `/plans/{plan_run_id}/trips` | `getPlanRunTrips` | dispatcher | Covered |
| POST | `/plans/validate` | `validatePlan` | dispatcher | Covered |
| POST | `/trips/{id}/orders` | `addOrderToTrip` | dispatcher | Covered |
| DELETE | `/trips/{id}/orders/{order_id}` | `removeOrderFromTrip` | dispatcher | Covered |
| POST | `/orders/{id}/defer` | `deferOrder` | dispatcher | Covered |
| POST | `/orders/{id}/requeue` | `requeueOrder` | dispatcher | Covered |
| POST | `/trips/{id}/confirm` | `confirmTrip` | dispatcher | Covered |
| POST | `/trips/{id}/cancel` | `cancelTrip` | dispatcher | Covered |
| POST | `/plans/close-run` | `closePlanRun` | dispatcher | Covered |
| GET | `/plans/summary` | `getPlansSummary` | dispatcher | Covered |
| GET | `/fuel` | `getFuelState` | dispatcher | Covered |
| GET | `/fleet` | `getFleetAvailability` | dispatcher | Covered |
| GET | `/monitoring/live` | `getLiveMonitoring` | dispatcher | Covered |
| GET | `/alerts` | `listAlerts` | dispatcher | Covered |
| GET | `/load-checks` | `listLoadChecks` | dispatcher | Covered |
| POST | `/exceptions/{id}/decision` | `resolveExceptionDecision` | dispatcher | Covered |
| POST | `/load-checks/{id}/resolve` | `resolveLoadCheck` | dispatcher | Covered |
| GET | `/deferrals` | `listDeferrals` | dispatcher | Covered |
| GET | `/outlets/{id}/skip-history` | `getOutletSkipHistory` | dispatcher | Covered |
| GET | `/loading/trips` | `getLoadingTrips` | loader | Covered |
| GET | `/trips/{id}/load-list` | `getTripLoadList` | loader | Covered |
| POST | `/trips/{id}/load-start` | `startTripLoading` | loader | Covered |
| POST | `/trips/{id}/load-checks` | `reportLoadCheck` | loader | Covered |
| POST | `/trips/{id}/load-confirm` | `confirmTripLoad` | loader | Covered |
| GET | `/driver/trips` | `getDriverTrips` | driver | Covered |
| POST | `/trips/{id}/start` | `startTrip` | driver | Covered |
| POST | `/stops/{id}/arrive` | `recordStopArrival` | driver | Covered |
| POST | `/stops/{id}/outcome` | `recordStopOutcome` | driver | Covered |
| POST | `/stops/{id}/exception` | `reportStopException` | driver | Covered |
| POST | `/trips/{id}/complete` | `completeTrip` | driver | Covered |
| POST | `/sync` | `syncOfflineOperations` | driver | Covered |
| GET | `/events/stream` | `getEventsStream` | reference | Covered |

*Missing or Extra Endpoints:* None (exactly 50 operations defined in the contract and implemented in `openapi.yaml`).

---

## 2. Screen & Action Mapping Table

| Screen Code | Screen Name | User Action / Behaviour | Mapped Operation ID |
|-------------|-------------|-------------------------|----------------------|
| **D1** | Driver Home | View assigned trips & status | `getDriverTrips` |
| **D2** | Driver Handover | Accept handover and start route | `startTrip` |
| **D2** | Driver Handover | Report loading discrepancy | `reportStopException` |
| **D3** | Stop Sequence | View ordered stops & ETAs | `getDriverTrips` |
| **D4** | Active Stop | Record arrival at stop | `recordStopArrival` |
| **D4** | Active Stop | Record stop outcome (delivered, partial, refused, closed) | `recordStopOutcome` |
| **D4** | Active Stop | Report field exception (vehicle issue, blocked dock) | `reportStopException` |
| **D5** | History | View completed stops and exceptions | `getDriverTrips` |
| **L1** | Loader Trips | View confirmed trips ready for loading | `getLoadingTrips` |
| **L1** | Loader Trips | Start loading trip | `startTripLoading` |
| **L2** | Load List | View manifest sequence & reverse load order | `getTripLoadList` |
| **L2** | Load List | Confirm load completed | `confirmTripLoad` |
| **L3** | Report Issue | Report missing or damaged stock shortfall | `reportLoadCheck` |
| **P1** | Dispatcher Dashboard | View order counts, vehicle states, cutoff countdown | `getDashboard`, `listAlerts` |
| **P2** | Dispatcher Orders | View unallocated queue | `getDispatchQueue` |
| **P2** | Dispatcher Orders | Cancel order with reason | `cancelOrder` |
| **P2** | Dispatcher Orders | Requeue order | `requeueOrder` |
| **P3** | Dispatcher Planning | Generate / re-run plan | `generatePlan` |
| **P3** | Dispatcher Planning | Validate draft plan | `validatePlan` |
| **P3** | Dispatcher Planning | Add order to draft trip | `addOrderToTrip` |
| **P3** | Dispatcher Planning | Remove order from draft trip | `removeOrderFromTrip` |
| **P3** | Dispatcher Planning | Manually defer order | `deferOrder` |
| **P3** | Dispatcher Planning | Confirm trip for dispatch | `confirmTrip` |
| **P3** | Dispatcher Planning | View remaining fuel quotas | `getFuelState` |
| **P3** | Dispatcher Planning | Close plan run | `closePlanRun` |
| **P4** | Loading Coordination | View shortfall alerts & departure blocks | `listAlerts` |
| **P4** | Loading Coordination | Resolve shortfall (adjust plan / defer / partial) | `resolveLoadCheck` |
| **P5** | Live Monitoring | View vehicle progress, delay status, at-risk stops | `getLiveMonitoring`, `getEventsStream` |
| **P5** | Live Monitoring | Record exception decision (retry / skip) | `resolveExceptionDecision` |
| **P6** | Deferred Queue | View deferred orders queue & skip history | `listDeferrals`, `getOutletSkipHistory` |
| **SM1** | Store Manager Home | View notices & expected delivery ETAs | `listNotifications`, `getOutletExpectedDeliveries` |
| **SM2** | Place Order | Place new order before cutoff | `createOrder` |
| **SM3** | Deferred Notice | View deferral reason & mark notice read | `listNotifications`, `markNotificationRead` |
| **SM4** | Order Tracking | Track order progress rail | `getOrderById`, `getEventsStream` |
| **SM5** | Confirm Receipt | Confirm receipt or report discrepancy | `recordStopReceipt` |

*Screen Actions with no endpoint flagged:* None (100% of defined screen actions map to an API endpoint).
