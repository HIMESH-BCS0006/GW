import '../../core/models/enums.dart';

class OutcomeValidationResult {
  final bool isValid;
  final String? error;

  const OutcomeValidationResult._(this.isValid, this.error);

  factory OutcomeValidationResult.valid() => const OutcomeValidationResult._(true, null);
  factory OutcomeValidationResult.invalid(String error) => OutcomeValidationResult._(false, error);
}

class StopOutcomeValidator {
  StopOutcomeValidator._();

  /// Validates stop outcome according to Decision D20 rules:
  /// - delivered: quantity_delivered = ordered units; received_by required.
  /// - partial: 0 < quantity < ordered; received_by required.
  /// - refused / closed: quantity 0; no received_by needed.
  /// - completed_at: device time in ISO-8601 with +05:30 offset.
  static OutcomeValidationResult validate({
    required StopOutcome outcome,
    required int orderedUnits,
    required int? quantityDelivered,
    required String? receivedBy,
    required String completedAt,
  }) {
    // Validate completed_at contains +05:30 offset
    if (!completedAt.endsWith('+05:30') && !completedAt.contains('+05:30')) {
      return OutcomeValidationResult.invalid(
        'completed_at timestamp must be in Asia/Colombo time with +05:30 offset',
      );
    }

    final receiver = receivedBy?.trim() ?? '';

    switch (outcome) {
      case StopOutcome.delivered:
        if (quantityDelivered != orderedUnits) {
          return OutcomeValidationResult.invalid(
            'Delivered quantity ($quantityDelivered) must equal ordered units ($orderedUnits).',
          );
        }
        if (receiver.isEmpty) {
          return OutcomeValidationResult.invalid(
            'Received by person name is required for delivered status.',
          );
        }
        return OutcomeValidationResult.valid();

      case StopOutcome.partial:
        if (quantityDelivered == null || quantityDelivered <= 0 || quantityDelivered >= orderedUnits) {
          return OutcomeValidationResult.invalid(
            'Partial delivery quantity ($quantityDelivered) must be strictly between 0 and $orderedUnits units.',
          );
        }
        if (receiver.isEmpty) {
          return OutcomeValidationResult.invalid(
            'Received by person name is required for partial delivery status.',
          );
        }
        return OutcomeValidationResult.valid();

      case StopOutcome.refused:
      case StopOutcome.closed:
        if (quantityDelivered != null && quantityDelivered != 0) {
          return OutcomeValidationResult.invalid(
            'Delivered quantity must be 0 for refused or closed outlet.',
          );
        }
        return OutcomeValidationResult.valid();
    }
  }
}
