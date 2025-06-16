import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> fileData;

  const FileDetailScreen({super.key, required this.fileData});

  @override
  State<FileDetailScreen> createState() => _FileDetailScreenState();
}

class _FileDetailScreenState extends State<FileDetailScreen> {
  late List<MapEntry<String, dynamic>> sortedWords;
  bool sortAsc = true;
  int sortColumnIndex = 0; // 0 for Word, 1 for Count

  @override
  void initState() {
    super.initState();
    sortedWords = Map<String, dynamic>.from(widget.fileData['all_words'] ?? {})
        .entries
        .toList();
    sortData();
  }

  void sortData() {
    setState(() {
      if (sortColumnIndex == 0) {
        sortedWords.sort((a, b) =>
            sortAsc ? a.key.compareTo(b.key) : b.key.compareTo(a.key));
      } else {
        sortedWords.sort((a, b) =>
            sortAsc ? a.value.compareTo(b.value) : b.value.compareTo(a.value));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String filename = widget.fileData['filename'] ?? "Unknown";
    final String type = widget.fileData['content_type'] ?? "Unknown";
    final int size = widget.fileData['size_bytes'] ?? 0;
    final int totalWords = widget.fileData['total_words'] ?? 0;
    final double time =
        (widget.fileData['processing_time_seconds'] ?? 0.0).toDouble();

    final topWords = List<Map<String, dynamic>>.from(
        widget.fileData['top_10_words'] ?? []);
    final double maxY = topWords
        .map((w) => (w['count'] ?? 0).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);
    final double interval = (maxY / 5).ceilToDouble();

    return Scaffold(
      appBar: AppBar(title: Text(filename)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _infoChip("Type", type),
                _infoChip("Size", "$size bytes"),
                _infoChip("Words", "$totalWords"),
                _infoChip("Time", "${time.toStringAsFixed(3)} s"),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Top 10 Words",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  maxY: maxY + interval,
                  barGroups: topWords.asMap().entries.map((entry) {
                    final index = entry.key;
                    final wordData = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (wordData['count'] ?? 0).toDouble(),
                          color: Colors.primaries[
                              index % Colors.primaries.length],
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index >= 0 && index < topWords.length) {
                            return Transform.rotate(
                              angle: -0.5,
                              child: Text(topWords[index]['word'],
                                  style: const TextStyle(fontSize: 10)),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: interval,
                        getTitlesWidget: (value, _) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10)),
                        reservedSize: 32,
                      ),
                    ),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("All Words",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortAscending: sortAsc,
                sortColumnIndex: sortColumnIndex,
                columns: [
                  DataColumn(
                    label: const Text("Word"),
                    onSort: (columnIndex, ascending) {
                      sortColumnIndex = columnIndex;
                      sortAsc = ascending;
                      sortData();
                    },
                  ),
                  DataColumn(
                    label: const Text("Count"),
                    numeric: true,
                    onSort: (columnIndex, ascending) {
                      sortColumnIndex = columnIndex;
                      sortAsc = ascending;
                      sortData();
                    },
                  ),
                ],
                rows: sortedWords.map((entry) {
                  return DataRow(cells: [
                    DataCell(Text(entry.key)),
                    DataCell(Text(entry.value.toString())),
                  ]);
                }).toList(),
                headingRowHeight: 32,
                dataRowMinHeight: 28,
                dataRowMaxHeight: 32,
                dividerThickness: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Chip(
      label: Text("$label: $value"),
      backgroundColor: Colors.blue.shade50,
    );
  }
}
