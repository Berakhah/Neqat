import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FilterBar extends StatelessWidget {
  final List<String>? actions;
  final String? selectedAction;
  final ValueChanged<String?>? onActionChanged;
  final TextEditingController? searchController;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback? onDateRangePick;
  final VoidCallback? onClearDateRange;
  final List<Widget>? children;

  const FilterBar({
    Key? key,
    this.actions,
    this.selectedAction,
    this.onActionChanged,
    this.searchController,
    this.searchHint,
    this.onSearchChanged,
    this.startDate,
    this.endDate,
    this.onDateRangePick,
    this.onClearDateRange,
    this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (actions != null && actions!.isNotEmpty) ...[
            const Text('Action:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: selectedAction,
              items: actions!.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
              onChanged: onActionChanged,
            ),
            const SizedBox(width: 16),
          ],
          if (searchController != null) ...[
            SizedBox(
              width: 140,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(hintText: searchHint ?? 'Search', isDense: true),
                onChanged: onSearchChanged,
              ),
            ),
            const SizedBox(width: 16),
          ],
          if (onDateRangePick != null) ...[
            OutlinedButton(
              onPressed: onDateRangePick,
              child: Text(
                (startDate == null || endDate == null)
                    ? 'Pick Date Range'
                    : '${DateFormat('yyyy-MM-dd').format(startDate!)} - ${DateFormat('yyyy-MM-dd').format(endDate!)}',
              ),
            ),
            if (startDate != null || endDate != null)
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear date filter',
                onPressed: onClearDateRange,
              ),
            const SizedBox(width: 16),
          ],
          if (children != null) ...children!,
        ],
      ),
    );
  }
} 