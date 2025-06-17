import 'package:flutter/material.dart'; // Import Flutter material design package
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart for chart widgets

// Stateful widget to display file details
class FileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> fileData; // File data passed to the screen

  const FileDetailScreen({super.key, required this.fileData}); // Constructor

  @override
  State<FileDetailScreen> createState() => _FileDetailScreenState(); // Create state
}

// State class for FileDetailScreen
class _FileDetailScreenState extends State<FileDetailScreen> {
  late List<MapEntry<String, dynamic>> sortedWords; // List of word/count pairs
  bool sortAsc = true; // Sorting order: ascending or descending
  int sortColumnIndex = 0; // Which column to sort by: 0=Word, 1=Count

  @override
  void initState() {
    super.initState();
    // Initialize sortedWords from fileData's 'all_words' map
    sortedWords = Map<String, dynamic>.from(widget.fileData['all_words'] ?? {})
        .entries
        .toList();
    sortData(); // Sort the data initially
  }

  // Sort the sortedWords list based on current sort settings
  void sortData() {
    setState(() {
      if (sortColumnIndex == 0) {
        // Sort by word (key)
        sortedWords.sort((a, b) =>
            sortAsc ? a.key.compareTo(b.key) : b.key.compareTo(a.key));
      } else {
        // Sort by count (value)
        sortedWords.sort((a, b) =>
            sortAsc ? a.value.compareTo(b.value) : b.value.compareTo(a.value));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Extract file details from fileData
    final String filename = widget.fileData['filename'] ?? "Unknown";
    final String type = widget.fileData['content_type'] ?? "Unknown";
    final int size = widget.fileData['size_bytes'] ?? 0;
    final int totalWords = widget.fileData['total_words'] ?? 0;
    final double time =
        (widget.fileData['processing_time_seconds'] ?? 0.0).toDouble();

    // Get top 10 words for the bar chart
    final topWords = List<Map<String, dynamic>>.from(
        widget.fileData['top_10_words'] ?? []);
    // Find the maximum count for Y axis
    final double maxY = topWords
        .map((w) => (w['count'] ?? 0).toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);
    // Calculate interval for Y axis labels
    final double interval = (maxY / 5).ceilToDouble();

    return Scaffold(
      appBar: AppBar(title: Text(filename)), // App bar with filename
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16), // Add padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align left
          children: [
            // Display file info chips
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _infoChip("Type", type), // File type
                _infoChip("Size", "$size bytes"), // File size
                _infoChip("Words", "$totalWords"), // Word count
                _infoChip("Time", "${time.toStringAsFixed(3)} s"), // Processing time
              ],
            ),
            const SizedBox(height: 24), // Spacing
            const Text("Top 10 Words",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Section title
            const SizedBox(height: 12), // Spacing
            SizedBox(
              height: 300, // Chart height
              child: BarChart(
                BarChartData(
                  maxY: maxY + interval, // Set Y axis max
                  barGroups: topWords.asMap().entries.map((entry) {
                    final index = entry.key; // Bar index
                    final wordData = entry.value; // Word/count map
                    return BarChartGroupData(
                      x: index, // X position
                      barRods: [
                        BarChartRodData(
                          toY: (wordData['count'] ?? 0).toDouble(), // Bar height
                          color: Colors.primaries[
                              index % Colors.primaries.length], // Bar color
                          width: 12, // Bar width
                          borderRadius: BorderRadius.circular(4), // Rounded corners
                        )
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, // Show X axis titles
                        reservedSize: 60, // Space for titles
                        interval: 1, // Show every bar
                        getTitlesWidget: (value, _) {
                          final index = value.toInt();
                          if (index >= 0 && index < topWords.length) {
                            return Transform.rotate(
                              angle: -0.5, // Rotate label
                              child: Text(topWords[index]['word'],
                                  style: const TextStyle(fontSize: 10)),
                            );
                          } else {
                            return const SizedBox.shrink(); // Empty if out of range
                          }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, // Show Y axis titles
                        interval: interval, // Interval for Y labels
                        getTitlesWidget: (value, _) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10)),
                        reservedSize: 32, // Space for Y labels
                      ),
                    ),
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)), // No top titles
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)), // No right titles
                  ),
                  gridData: FlGridData(show: false), // Hide grid lines
                  borderData: FlBorderData(show: false), // Hide border
                ),
              ),
            ),
            const SizedBox(height: 24), // Spacing
            const Text("All Words",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Section title
            const SizedBox(height: 12), // Spacing
            SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Allow horizontal scroll
              child: DataTable(
                sortAscending: sortAsc, // Current sort order
                sortColumnIndex: sortColumnIndex, // Current sort column
                columns: [
                  DataColumn(
                    label: const Text("Word"), // Column label
                    onSort: (columnIndex, ascending) {
                      sortColumnIndex = columnIndex; // Set sort column
                      sortAsc = ascending; // Set sort order
                      sortData(); // Sort data
                    },
                  ),
                  DataColumn(
                    label: const Text("Count"), // Column label
                    numeric: true, // Numeric column
                    onSort: (columnIndex, ascending) {
                      sortColumnIndex = columnIndex; // Set sort column
                      sortAsc = ascending; // Set sort order
                      sortData(); // Sort data
                    },
                  ),
                ],
                rows: sortedWords.map((entry) {
                  return DataRow(cells: [
                    DataCell(Text(entry.key)), // Word cell
                    DataCell(Text(entry.value.toString())), // Count cell
                  ]);
                }).toList(),
                headingRowHeight: 32, // Header row height
                dataRowMinHeight: 28, // Min data row height
                dataRowMaxHeight: 32, // Max data row height
                dividerThickness: 0.3, // Divider thickness
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to display info as a chip
  Widget _infoChip(String label, String value) {
    return Chip(
      label: Text("$label: $value"), // Chip label
      backgroundColor: Colors.blue.shade50, // Chip background color
    );
  }
}
