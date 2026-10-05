import 'package:flutter/material.dart';
import '../../shared/widgets/app_empty_view.dart';

class DriverHistoryScreen extends StatelessWidget {
  const DriverHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyView(
      icon: Icons.history_outlined,
      title: 'Delivery History',
      message: 'Completed stops and reported exceptions will appear here.',
    );
  }
}
