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
  int sortColumnIndex = 0;

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tableHeaderStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    );

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
            Text("Top 10 Words",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
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
                              child: Text(
                                topWords[index]['word'],
                                style: const TextStyle(fontSize: 10),
                              ),
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
            Text("All Words",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                double totalWidth = constraints.maxWidth;
                double wordColumnWidth = totalWidth * 0.6;
                double countColumnWidth = totalWidth * 0.4;

                return ConstrainedBox(
                  constraints: BoxConstraints(minWidth: totalWidth),
                  child: DataTable(
                    sortAscending: sortAsc,
                    sortColumnIndex: sortColumnIndex,
                    columnSpacing: 12,
                    columns: [
                      DataColumn(
                        label: SizedBox(
                          width: wordColumnWidth,
                          child: Text("Word", style: tableHeaderStyle),
                        ),
                        onSort: (columnIndex, ascending) {
                          setState(() {
                            sortColumnIndex = columnIndex;
                            sortAsc = ascending;
                            sortData();
                          });
                        },
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: countColumnWidth,
                          child: Text("Count", style: tableHeaderStyle),
                        ),
                        numeric: true,
                        onSort: (columnIndex, ascending) {
                          setState(() {
                            sortColumnIndex = columnIndex;
                            sortAsc = ascending;
                            sortData();
                          });
                        },
                      ),
                    ],
                    rows: sortedWords.map((entry) {
                      return DataRow(cells: [
                        DataCell(SizedBox(
                            width: wordColumnWidth, child: Text(entry.key))),
                        DataCell(SizedBox(
                            width: countColumnWidth,
                            child: Text(entry.value.toString()))),
                      ]);
                    }).toList(),
                    headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                        (states) => isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade300),
                    dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                        (states) => isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade100),
                    dividerThickness: 0.5,
                    headingRowHeight: 36,
                    dataRowMinHeight: 32,
                    dataRowMaxHeight: 36,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Chip(
      label: Text("$label: $value"),
      backgroundColor: Theme.of(context).chipTheme.backgroundColor ??
          (Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.blue.shade50),
    );
  }
}
