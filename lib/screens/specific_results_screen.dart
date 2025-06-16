import 'package:flutter/material.dart';
import 'file_detail_screen.dart'; // Adjust the path if needed
class SpecificResultsScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const SpecificResultsScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    final List files = resultData['files'] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Specific Results')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: files.isEmpty
            ? const Center(child: Text("No file data found."))
            : ListView.builder(
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.insert_drive_file),
                      label: Text("File #${index + 1}"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FileDetailScreen(fileData: file),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
