import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../shared/theme/app_theme.dart';
import 'loader_api.dart';

enum _ReportCategory {
  missingItems,
  damagedItems,
  shortQuantity,
}

class ReportAllocationPage extends ConsumerStatefulWidget {
  final TripCard trip;
  final StopDetail stop;
  final int planVersion;

  const ReportAllocationPage({
    super.key,
    required this.trip,
    required this.stop,
    required this.planVersion,
  });

  static Future<bool> show(
    BuildContext context, {
    required TripCard trip,
    required StopDetail stop,
    required int planVersion,
  }) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => ReportAllocationPage(
          trip: trip,
          stop: stop,
          planVersion: planVersion,
        ),
      ),
    );
    return submitted ?? false;
  }

  @override
  ConsumerState<ReportAllocationPage> createState() =>
      _ReportAllocationPageState();
}

class _ReportAllocationPageState extends ConsumerState<ReportAllocationPage> {
  final TextEditingController _noteController = TextEditingController();
  _ReportCategory _selectedCategory = _ReportCategory.missingItems;
  int _affectedQuantity = 1;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final issue = _selectedCategory == _ReportCategory.damagedItems
        ? LoadCheckIssue.damaged
        : LoadCheckIssue.missing;
    final categoryLabel = switch (_selectedCategory) {
      _ReportCategory.missingItems => 'Missing items',
      _ReportCategory.damagedItems => 'Damaged items',
      _ReportCategory.shortQuantity => 'Short quantity',
    };
    final affectedDescription =
        _selectedCategory == _ReportCategory.damagedItems
            ? '$_affectedQuantity damaged'
            : '$_affectedQuantity missing';
    final noteParts = [
      '$categoryLabel: $affectedDescription of ${widget.stop.orderUnits} units.',
      if (_noteController.text.trim().isNotEmpty) _noteController.text.trim(),
    ];

    try {
      await ref.read(loaderApiProvider).reportLoadCheck(
            tripId: widget.trip.id,
            orderId: widget.stop.orderId,
            planVersion: widget.planVersion,
            expectedQty: widget.stop.orderUnits,
            loadedQty: widget.stop.orderUnits - _affectedQuantity,
            issue: issue.name,
            note: noteParts.join(' '),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = _friendlyError(error);
      });
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final stop = widget.stop;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Allocation')),
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _OrderBanner(
                  orderId: stop.orderId,
                  tripNo: widget.trip.tripNo,
                ),
                const SizedBox(height: 20),
                const _SectionTitle(
                  number: '1',
                  title: 'SELECT ISSUE CATEGORY',
                  trailing: 'Touch to select',
                ),
                const SizedBox(height: 10),
                _CategoryTile(
                  title: 'Missing Items',
                  description: 'Items not found at the loading bay',
                  icon: Icons.inventory_2_outlined,
                  selected: _selectedCategory == _ReportCategory.missingItems,
                  onTap: () => setState(
                    () => _selectedCategory = _ReportCategory.missingItems,
                  ),
                ),
                const SizedBox(height: 8),
                _CategoryTile(
                  title: 'Damaged Items',
                  description: 'Leaking, crushed, or unusable items',
                  icon: Icons.home_repair_service_outlined,
                  selected: _selectedCategory == _ReportCategory.damagedItems,
                  onTap: () => setState(
                    () => _selectedCategory = _ReportCategory.damagedItems,
                  ),
                ),
                const SizedBox(height: 8),
                _CategoryTile(
                  title: 'Short Quantity',
                  description: 'Fewer units available than the manifest',
                  icon: Icons.production_quantity_limits,
                  selected: _selectedCategory == _ReportCategory.shortQuantity,
                  onTap: () => setState(
                    () => _selectedCategory = _ReportCategory.shortQuantity,
                  ),
                ),
                const SizedBox(height: 22),
                _SectionTitle(
                  number: '2',
                  title: 'AFFECTED QUANTITY',
                  trailing: 'On manifest: ${stop.orderUnits} units',
                ),
                const SizedBox(height: 10),
                _QuantitySelector(
                  quantity: _affectedQuantity,
                  total: stop.orderUnits,
                  category: _selectedCategory,
                  onDecrease: _affectedQuantity > 1
                      ? () => setState(() => _affectedQuantity--)
                      : null,
                  onIncrease: _affectedQuantity < stop.orderUnits
                      ? () => setState(() => _affectedQuantity++)
                      : null,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F1EF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'The dispatcher will be notified. '
                    '${stop.orderUnits - _affectedQuantity} of '
                    '${stop.orderUnits} units will be marked as available.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _noteController,
                  enabled: !_isSubmitting,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Additional details (optional)',
                    hintText: 'Describe what was found at the loading bay',
                    alignLabelWithHint: true,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitReport,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      _isSubmitting
                          ? 'Sending report...'
                          : 'Send to Dispatcher',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderBanner extends StatelessWidget {
  final String orderId;
  final int tripNo;

  const _OrderBanner({
    required this.orderId,
    required this.tripNo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF87171),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '!',
              style: TextStyle(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REPORT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  orderId,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'TRIP $tripNo',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String number;
  final String title;
  final String trailing;

  const _SectionTitle({
    required this.number,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppTheme.primaryDark,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF518D83) : const Color(0xFFD5E5E1);
    final foreground = selected ? Colors.white : AppTheme.textPrimary;

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.8),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_box : Icons.check_box_outline_blank,
                color: selected ? Colors.white : AppTheme.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final int total;
  final _ReportCategory category;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _QuantitySelector({
    required this.quantity,
    required this.total,
    required this.category,
    required this.onDecrease,
    required this.onIncrease,
  });

  String get unitLabel => total == 1 ? 'UNIT' : 'UNITS';

  String get affectedLabel => switch (category) {
        _ReportCategory.missingItems => 'MISSING',
        _ReportCategory.damagedItems => 'DAMAGED',
        _ReportCategory.shortQuantity => 'SHORT',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF9BBDB7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _QuantityButton(
            icon: Icons.remove,
            onPressed: onDecrease,
          ),
          Expanded(
            child: Column(
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                    children: [
                      TextSpan(
                        text: '$quantity',
                        style: const TextStyle(fontSize: 24),
                      ),
                      TextSpan(
                        text: ' / $total',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$unitLabel $affectedLabel',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          _QuantityButton(
            icon: Icons.add,
            onPressed: onIncrease,
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: AppTheme.primaryDark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.primaryDark.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        child: Icon(icon, size: 21),
      ),
    );
  }
}
