import 'package:json_annotation/json_annotation.dart';

enum Role {
  @JsonValue('dispatcher')
  dispatcher,
  @JsonValue('loader')
  loader,
  @JsonValue('driver')
  driver,
  @JsonValue('store_manager')
  storeManager,
}

enum Brand {
  @JsonValue('Fresh')
  fresh,
  @JsonValue('Style')
  style,
  @JsonValue('Tech')
  tech,
}

enum VehicleStatus {
  @JsonValue('available')
  available,
  @JsonValue('in_workshop')
  inWorkshop,
}

enum TemperatureRequirement {
  @JsonValue('chilled')
  chilled,
  @JsonValue('ambient')
  ambient,
  @JsonValue('reefer')
  reefer,
}

enum VehicleType {
  @JsonValue('truck')
  truck,
  @JsonValue('van')
  van,
}

enum DockType {
  @JsonValue('rear_dock')
  rearDock,
  @JsonValue('street')
  street,
  @JsonValue('mall_bay')
  mallBay,
}

enum ParkingConstraint {
  @JsonValue('normal')
  normal,
  @JsonValue('van_only')
  vanOnly,
  @JsonValue('mall_dock')
  mallDock,
}

enum OrderStatus {
  @JsonValue('SUBMITTED')
  submitted,
  @JsonValue('PLANNED')
  planned,
  @JsonValue('SCHEDULED')
  scheduled,
  @JsonValue('LOADED')
  loaded,
  @JsonValue('IN_TRANSIT')
  inTransit,
  @JsonValue('DELIVERED')
  delivered,
  @JsonValue('PARTIALLY_DELIVERED')
  partiallyDelivered,
  @JsonValue('DEFERRED')
  deferred,
  @JsonValue('CANCELLED')
  cancelled,
}

enum TripStatus {
  @JsonValue('DRAFT')
  draft,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('LOADING')
  loading,
  @JsonValue('LOADED')
  loaded,
  @JsonValue('IN_PROGRESS')
  inProgress,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('BLOCKED')
  blocked,
  @JsonValue('CANCELLED')
  cancelled,
}

enum StopStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('ARRIVED')
  arrived,
  @JsonValue('DELIVERED')
  delivered,
  @JsonValue('PARTIAL')
  partial,
  @JsonValue('FAILED')
  failed,
  @JsonValue('EXCEPTION')
  exception,
  @JsonValue('SKIPPED')
  skipped,
}

enum ReceiptStatus {
  @JsonValue('NONE')
  none,
  @JsonValue('AWAITING')
  awaiting,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('DISCREPANCY')
  discrepancy,
}

enum StopOutcome {
  @JsonValue('delivered')
  delivered,
  @JsonValue('partial')
  partial,
  @JsonValue('refused')
  refused,
  @JsonValue('closed')
  closed,
}

enum ReceiptOutcome {
  @JsonValue('full')
  full,
  @JsonValue('discrepancy')
  discrepancy,
}

enum LoadCheckIssue {
  @JsonValue('missing')
  missing,
  @JsonValue('damaged')
  damaged,
}

enum LoadCheckStatus {
  @JsonValue('OPEN')
  open,
  @JsonValue('RESOLVED')
  resolved,
}

enum LoadCheckResolution {
  @JsonValue('defer_order')
  deferOrder,
  @JsonValue('replan_order')
  replanOrder,
  @JsonValue('proceed_partial')
  proceedPartial,
}

enum ExceptionType {
  @JsonValue('dock_blocked')
  dockBlocked,
  @JsonValue('outlet_closed')
  outletClosed,
  @JsonValue('vehicle_issue')
  vehicleIssue,
  @JsonValue('access_problem')
  accessProblem,
  @JsonValue('other')
  other,
}

enum ExceptionStatus {
  @JsonValue('OPEN')
  open,
  @JsonValue('DECIDED')
  decided,
}

enum ExceptionDecision {
  @JsonValue('retry')
  retry,
  @JsonValue('skip')
  skip,
}

enum SyncOpResult {
  @JsonValue('applied')
  applied,
  @JsonValue('replayed')
  replayed,
  @JsonValue('applied_with_conflict')
  appliedWithConflict,
  @JsonValue('rejected')
  rejected,
}

enum EventType {
  @JsonValue('order.submitted')
  orderSubmitted,
  @JsonValue('order.deferred')
  orderDeferred,
  @JsonValue('order.cancelled')
  orderCancelled,
  @JsonValue('plan.generated')
  planGenerated,
  @JsonValue('trip.confirmed')
  tripConfirmed,
  @JsonValue('trip.updated')
  tripUpdated,
  @JsonValue('loading.shortfall')
  loadingShortfall,
  @JsonValue('shortfall.resolved')
  shortfallResolved,
  @JsonValue('trip.loaded')
  tripLoaded,
  @JsonValue('trip.started')
  tripStarted,
  @JsonValue('stop.arrived')
  stopArrived,
  @JsonValue('stop.outcome')
  stopOutcome,
  @JsonValue('stop.exception')
  stopException,
  @JsonValue('exception.decided')
  exceptionDecided,
  @JsonValue('receipt.confirmed')
  receiptConfirmed,
  @JsonValue('receipt.discrepancy')
  receiptDiscrepancy,
  @JsonValue('sync.reconciled')
  syncReconciled,
  @JsonValue('sync.conflict')
  syncConflict,
  @JsonValue('run.closed')
  runClosed,
}
