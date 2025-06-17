import 'package:flutter/material.dart'; // Import the Flutter material design package.
import 'file_detail_screen.dart'; // Import the file detail screen (adjust path if needed).

// Define a stateless widget called SpecificResultsScreen.
class SpecificResultsScreen extends StatelessWidget {
  final Map<String, dynamic> resultData; // Store the result data passed to the screen.

  // Constructor for SpecificResultsScreen, requiring resultData.
  const SpecificResultsScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    final List files = resultData['files'] ?? []; // Extract the 'files' list from resultData, or use empty list if null.

    return Scaffold(
      appBar: AppBar(title: const Text('Specific Results')), // App bar with title.
      body: Padding(
        padding: const EdgeInsets.all(16), // Add padding around the body.
        child: files.isEmpty
            ? const Center(child: Text("No file data found.")) // Show message if no files.
            : ListView.builder(
                itemCount: files.length, // Number of items in the list.
                itemBuilder: (context, index) {
                  final file = files[index]; // Get the file at the current index.
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8), // Vertical padding between buttons.
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.insert_drive_file), // File icon.
                      label: Text("File #${index + 1}"), // Button label with file number.
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FileDetailScreen(fileData: file), // Navigate to FileDetailScreen with file data.
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
