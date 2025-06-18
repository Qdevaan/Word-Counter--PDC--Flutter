import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GeneralResultsScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const GeneralResultsScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    final topWords = List<Map<String, dynamic>>.from(resultData['overall_top_30_words']).take(20).toList();
    final files = List<Map<String, dynamic>>.from(resultData['files']);
    final int totalFiles = resultData['total_files_received'] ?? files.length;
    final int totalWords = files.fold<num>(0, (sum, file) => sum + (file['total_words'] ?? 0)).toInt();
    final double totalTime = resultData['overall_processing_time_seconds'] ?? 0.0;
    final double maxY = topWords.map((w) => (w['count'] ?? 0).toDouble()).fold(0, (prev, el) => el > prev ? el : prev);
    final double interval = (maxY / 5).ceilToDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('General Results')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSummaryItem("Total Files", "$totalFiles", Icons.insert_drive_file),
                    _buildSummaryItem("Total Words", "$totalWords", Icons.text_fields),
                    _buildSummaryItem("Total Time", "${totalTime.toStringAsFixed(2)}s", Icons.timer),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("Top 20 Words", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
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
                          color: Colors.primaries[index % Colors.primaries.length],
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
                        getTitlesWidget: (value, meta) {
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
                        interval: 1,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: interval,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                        reservedSize: 32,
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text("File Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...files.map((file) => _buildFileCard(context, file)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blueAccent),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildFileCard(BuildContext context, Map<String, dynamic> file) {
    final topWords = List<Map<String, dynamic>>.from(file['top_10_words']);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tableHeaderStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(file['filename'] ?? "Unnamed File",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _infoChip(context, "Type", file['content_type'] ?? "N/A"),
                _infoChip(context, "Size", "${file['size_bytes']} bytes"),
                _infoChip(context, "Words", "${file['total_words']}"),
                _infoChip(context, "Time", "${(file['processing_time_seconds'] ?? 0.0).toStringAsFixed(3)} s"),
              ],
            ),
            const SizedBox(height: 12),
            const Text("Top 10 Words:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                double totalWidth = constraints.maxWidth;
                double wordColumnWidth = totalWidth * 0.6;
                double countColumnWidth = totalWidth * 0.4;

                return ConstrainedBox(
                  constraints: BoxConstraints(minWidth: totalWidth),
                  child: DataTable(
                    columnSpacing: 12,
                    headingRowHeight: 32,
                    dataRowMinHeight: 28,
                    dataRowMaxHeight: 32,
                    dividerThickness: 0.5,
                    headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (states) => isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    ),
                    dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (states) => isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                    ),
                    columns: [
                      DataColumn(
                        label: SizedBox(
                          width: wordColumnWidth,
                          child: Text("Word", style: tableHeaderStyle),
                        ),
                      ),
                      DataColumn(
                        label: SizedBox(
                          width: countColumnWidth,
                          child: Text("Count", style: tableHeaderStyle),
                        ),
                        numeric: true,
                      ),
                    ],
                    rows: topWords.map((wordData) {
                      return DataRow(cells: [
                        DataCell(SizedBox(
                            width: wordColumnWidth,
                            child: Text(wordData['word'] ?? ''))),
                        DataCell(SizedBox(
                            width: countColumnWidth,
                            child: Text(wordData['count'].toString()))),
                      ]);
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Chip(
      label: Text("$label: $value"),
      backgroundColor: Theme.of(context).chipTheme.backgroundColor ??
          (isDark ? Colors.grey.shade800 : Colors.blue.shade50),
    );
  }
}
