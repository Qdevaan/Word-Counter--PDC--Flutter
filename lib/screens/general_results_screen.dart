import 'package:flutter/material.dart'; // Import Flutter material design package
import 'package:fl_chart/fl_chart.dart'; // Import FL Chart package for charts

// Define a stateless widget for the general results screen
class GeneralResultsScreen extends StatelessWidget {
  final Map<String, dynamic> resultData; // Store the result data passed to the screen

  // Constructor with required resultData parameter
  const GeneralResultsScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    print("Received resultData: $resultData"); // Debug print of received data

    // Extract top 20 words from the result data
    final topWords = List<Map<String, dynamic>>.from(resultData['overall_top_30_words']).take(20).toList();
    // Extract file details from the result data
    final files = List<Map<String, dynamic>>.from(resultData['files']);

    // Get total number of files, fallback to files.length if not present
    final int totalFiles = resultData['total_files_received'] ?? files.length;
    // Calculate total words by summing up words in each file
    final int totalWords = files.fold<num>(0, (sum, file) => sum + (file['total_words'] ?? 0)).toInt();
    // Get total processing time from result data
    final double totalTime = resultData['overall_processing_time_seconds'] ?? 0.0;
    // Find the maximum word count among top words for chart scaling
    final double maxY = topWords.map((w) => (w['count'] ?? 0).toDouble()).fold(0, (prev, el) => el > prev ? el : prev);
    // Calculate interval for Y axis labels in the chart
    final double interval = (maxY / 5).ceilToDouble();

    // Build the UI
    return Scaffold(
      appBar: AppBar(title: const Text('General Results')), // App bar with title
      body: SingleChildScrollView( // Make the body scrollable
        padding: const EdgeInsets.all(16), // Add padding around the content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start
          children: [
            Card( // Summary card at the top
              elevation: 6, // Card elevation
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
              child: Padding(
                padding: const EdgeInsets.all(16), // Padding inside the card
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly space summary items
                  children: [
                    _buildSummaryItem("Total Files", "$totalFiles", Icons.insert_drive_file), // Total files summary
                    _buildSummaryItem("Total Words", "$totalWords", Icons.text_fields), // Total words summary
                    _buildSummaryItem("Total Time", "${totalTime.toStringAsFixed(2)}s", Icons.timer), // Total time summary
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24), // Spacing

            const Text("Top 20 Words", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Section title
            const SizedBox(height: 16), // Spacing

            SizedBox(
              height: 300, // Fixed height for the chart
              child: BarChart(
                BarChartData(
                  maxY: maxY + interval, // Set max Y value for the chart
                  barGroups: topWords.asMap().entries.map((entry) { // Create bar groups for each word
                    final index = entry.key; // Index of the word
                    final wordData = entry.value; // Word data map
                    return BarChartGroupData(
                      x: index, // X position
                      barRods: [
                        BarChartRodData(
                          toY: (wordData['count'] ?? 0).toDouble(), // Height of the bar
                          color: Colors.primaries[index % Colors.primaries.length], // Bar color
                          width: 12, // Bar width
                          borderRadius: BorderRadius.circular(4), // Rounded bar corners
                        )
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData( // Configure axis titles
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, // Show bottom titles
                        reservedSize: 60, // Reserve space for titles
                        getTitlesWidget: (value, meta) { // Widget for each title
                          final index = value.toInt();
                          if (index >= 0 && index < topWords.length) {
                            return Transform.rotate(
                              angle: -0.5, // Rotate label for readability
                              child: Text(
                                topWords[index]['word'], // Word label
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          } else {
                            return const SizedBox.shrink(); // Empty widget if out of range
                          }
                        },
                        interval: 1, // Show every label
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, // Show left axis titles
                        interval: interval, // Interval between labels
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(), // Show integer value
                          style: const TextStyle(fontSize: 10),
                        ),
                        reservedSize: 32, // Reserve space for left titles
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide top titles
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide right titles
                  ),
                  gridData: FlGridData(show: false), // Hide grid lines
                  borderData: FlBorderData(show: false), // Hide chart border
                ),
              ),
            ),

            const SizedBox(height: 32), // Spacing
            const Text("File Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // Section title
            const SizedBox(height: 16), // Spacing

            ...files.map((file) => _buildFileCard(file)).toList(), // Build a card for each file
          ],
        ),
      ),
    );
  }

  // Helper widget to build a summary item with icon, value, and label
  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blueAccent), // Icon
        const SizedBox(height: 8), // Spacing
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Value
        Text(label, style: const TextStyle(color: Colors.grey)), // Label
      ],
    );
  }

  // Helper widget to build a card for each file's details
  Widget _buildFileCard(Map<String, dynamic> file) {
    final topWords = List<Map<String, dynamic>>.from(file['top_10_words']); // Extract top 10 words for the file

    return Card(
      elevation: 4, // Card elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Rounded corners
      margin: const EdgeInsets.symmetric(vertical: 12), // Vertical margin
      child: Padding(
        padding: const EdgeInsets.all(16), // Padding inside the card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start
          children: [
            Text(file['filename'] ?? "Unnamed File",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // File name
            const SizedBox(height: 8), // Spacing
            Wrap(
              spacing: 12, // Space between chips
              runSpacing: 8, // Space between lines
              children: [
                _infoChip("Type", file['content_type'] ?? "N/A"), // File type chip
                _infoChip("Size", "${file['size_bytes']} bytes"), // File size chip
                _infoChip("Words", "${file['total_words']}"), // Word count chip
                _infoChip("Time", "${(file['processing_time_seconds'] ?? 0.0).toStringAsFixed(3)} s"), // Processing time chip
              ],
            ),
            const SizedBox(height: 12), // Spacing
            const Text("Top 10 Words:", style: TextStyle(fontWeight: FontWeight.bold)), // Section title
            const SizedBox(height: 8), // Spacing
            DataTable(
              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold), // Header style
              columnSpacing: 48, // Space between columns
              horizontalMargin: 12, // Horizontal margin
              columns: const [
                DataColumn(label: Text('Word')), // Word column
                DataColumn(label: Text('Count')), // Count column
              ],
              rows: topWords.map((wordData) { // Create a row for each word
                return DataRow(cells: [
                  DataCell(Text(wordData['word'] ?? '')), // Word cell
                  DataCell(Text(wordData['count'].toString())), // Count cell
                ]);
              }).toList(),
              headingRowHeight: 32, // Header row height
              dataRowMinHeight: 28, // Minimum data row height
              dataRowMaxHeight: 32, // Maximum data row height
              dividerThickness: 0.3, // Divider thickness
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build a chip with label and value
  Widget _infoChip(String label, String value) {
    return Chip(
      label: Text("$label: $value"), // Chip label
      backgroundColor: Colors.blue.shade50, // Chip background color
    );
  }
}
