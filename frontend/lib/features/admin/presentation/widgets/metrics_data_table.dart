import 'package:flutter/material.dart';

class MetricsDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final List<String> columns;
  final List<String> valueFields;
  
  const MetricsDataTable({
    Key? key,
    required this.data,
    required this.columns,
    required this.valueFields,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            Theme.of(context).primaryColor.withOpacity(0.1),
          ),
          columnSpacing: 24,
          columns: List.generate(columns.length, (index) {
            return DataColumn(
              label: Text(
                columns[index],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }),
          rows: List.generate(data.length, (rowIndex) {
            return DataRow(
              cells: List.generate(valueFields.length, (colIndex) {
                final value = data[rowIndex][valueFields[colIndex]];
                return DataCell(
                  Text(value?.toString() ?? 'N/A'),
                );
              }),
            );
          }),
        ),
      ),
    );
  }
} 