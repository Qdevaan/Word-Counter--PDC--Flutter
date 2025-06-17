import 'package:flutter/material.dart'; // Import Flutter material design package
import 'package:file_picker/file_picker.dart'; // Import file picker package for picking files
import 'package:http/http.dart' as http; // Import HTTP package for making network requests
import 'package:lottie/lottie.dart'; // Import Lottie for animations
import 'dart:convert'; // Import dart:convert for JSON encoding/decoding

// Define a stateful widget for the upload files screen
class UploadFilesScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier; // Notifier for theme changes
  final String serverUrl; // Server URL for file upload

  const UploadFilesScreen({
    super.key, // Pass key to superclass
    required this.themeNotifier, // Require themeNotifier
    required this.serverUrl, // Require serverUrl
  });

  @override
  State<UploadFilesScreen> createState() => _UploadFilesScreenState(); // Create state
}

// State class for UploadFilesScreen
class _UploadFilesScreenState extends State<UploadFilesScreen> {
  Map<String, dynamic>? _responseData; // Store response data from server
  final List<PlatformFile?> _selectedFiles = List.filled(10, null); // List to hold up to 10 selected files
  String? _statusMessage; // Message to show in popup
  IconData? _statusIcon; // Icon to show in popup
  Color? _statusColor; // Color for status icon/message
  bool _showPopup = false; // Whether to show popup
  String? _errorMessage; // Error message to display

  // Function to pick a file for a given index
  Future<void> _pickFile(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom, // Allow custom file types
      allowedExtensions: ['pdf', 'docx', 'txt'], // Allowed file extensions
      withData: true, // Load file bytes into memory
    );
    print(result); // Print the result to the console

    if (result != null && result.files.isNotEmpty) { // If a file was picked
      setState(() {
        _selectedFiles[index] = result.files.first; // Store the selected file
      });
    }
  }

  // Show a popup with a status message, icon, and color
  void _showStatusPopup(String message, IconData icon, Color color) {
    setState(() {
      _statusMessage = message; // Set status message
      _statusIcon = icon; // Set status icon
      _statusColor = color; // Set status color
      _errorMessage = null; // Clear error message
      _showPopup = true; // Show popup
    });
  }

  // Update the popup with new message, icon, color, and optional error
  void _updatePopup(String message, IconData icon, Color color, {String? error}) {
    setState(() {
      _statusMessage = message; // Update status message
      _statusIcon = icon; // Update icon
      _statusColor = color; // Update color
      _errorMessage = error; // Set error message if provided
    });
  }

  // Close the popup and reset status variables
  void _closePopup() {
    setState(() {
      _showPopup = false; // Hide popup
      _statusMessage = null; // Clear status message
      _statusIcon = null; // Clear icon
      _statusColor = null; // Clear color
      _errorMessage = null; // Clear error message
    });
  }

  // Submit selected files to the server
  Future<void> _submitFiles() async {
    final selected = _selectedFiles.where((file) => file != null).toList(); // Get non-null selected files

    if (selected.isEmpty) { // If no files selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one file.")), // Show error
      );
      return;
    }

    final uri = Uri.parse("${widget.serverUrl}/upload-files"); // Build upload URL

    final request = http.MultipartRequest('POST', uri); // Create multipart POST request

    for (var file in selected) { // Add each selected file to the request
      if (file != null && file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files', // Field name
            file.bytes!, // File bytes
            filename: file.name, // File name
          ),
        );
      }
    }

    _showStatusPopup("Uploading...", Icons.upload_file, Colors.blue); // Show uploading popup

    try {
      final streamedResponse = await request.send(); // Send request
      final response = await http.Response.fromStream(streamedResponse); // Get response

      if (response.statusCode == 200) { // If upload successful
        _responseData = json.decode(response.body); // Decode response data
        _updatePopup("Processing...", Icons.check_circle, Colors.green); // Show processing popup

        // Simulate processing delay
        await Future.delayed(const Duration(seconds: 2));

        _updatePopup("Processing Complete!", Icons.check_circle, Colors.green); // Show complete popup
      } else { // If upload failed
        _updatePopup("Upload failed", Icons.cancel, Colors.red,
            error: "Status: ${response.statusCode}\n${response.body}"); // Show error
      }
    } catch (e) { // On error
      _updatePopup("Error occurred", Icons.error_outline, Colors.red,
          error: e.toString()); // Show error
    }
  }

  // Build Lottie animation based on status message
  Widget _buildLottieAnimation() {
    if (_statusMessage == "Uploading...") {
      return Lottie.asset('assets/animations/uploading.json', width: 100); // Uploading animation
    }else if (_statusMessage?.startsWith("Processing...") ?? false) {
      return Lottie.asset('assets/animations/success.json', width: 100); // Processing animation
    }else if (_statusMessage?.startsWith("Processin Complete") ?? false) {
      return Lottie.asset('assets/animations/success-2.json', width: 100); // Complete animation
    } else if (_statusMessage == "Upload failed" || _statusMessage == "Error occurred") {
      return Lottie.asset('assets/animations/error.json', width: 100); // Error animation
    } else {
      return Icon(
        _statusIcon ?? Icons.info_outline, // Default icon
        color: _statusColor ?? Colors.grey, // Default color
        size: 60,
      );
    }
  }

  // Build the content of the popup based on status/error
  Widget _buildPopupContent() {
    if (_errorMessage != null) { // If there's an error
      return Text(
        _errorMessage!, // Show error message
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: Colors.red),
      );
    } else if (_statusMessage?.startsWith("Processing Complete") ?? false) { // If processing complete
      return Column(
        children: [
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.bar_chart),
            label: const Text("General Review"),
            onPressed: () {
              if (_responseData != null) { // If response data exists
                Navigator.pushNamed(
                  context,
                  '/general-results', // Navigate to general results
                  arguments: _responseData,
                );
              }
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.insert_drive_file),
            label: const Text("View Individual Results"),
            onPressed: () {
              if (_responseData != null) { // If response data exists
                Navigator.pushNamed(
                  context,
                  '/specific-results', // Navigate to specific results
                  arguments: _responseData,
                );
              }
            },
          ),
        ],
      );
    } else {
      return const SizedBox.shrink(); // Empty widget
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get current theme

    return Scaffold(
      appBar: AppBar(title: const Text("Upload Files")), // App bar title
      body: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16), // Padding around content
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: 10, // 10 file pickers
                    separatorBuilder: (_, __) => const SizedBox(height: 12), // Space between pickers
                    itemBuilder: (context, index) {
                      final file = _selectedFiles[index]; // Get file at index
                      return ElevatedButton.icon(
                        onPressed: () => _pickFile(index), // Pick file on press
                        icon: const Icon(Icons.upload_file),
                        label: Text(file?.name ?? "Choose File ${index + 1}"), // Show file name or prompt
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _submitFiles, // Submit files on press
                  icon: const Icon(Icons.send),
                  label: const Text("Submit Files"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50), // Full width button
                  ),
                ),
              ],
            ),
          ),
          if (_showPopup) // If popup should be shown
            Material(
              color: Colors.black.withOpacity(0.3), // Semi-transparent background
              child: Center(
                child: Container(
                  width: 280,
                  height: 360,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor, // Card color from theme
                    borderRadius: BorderRadius.circular(20), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: Icon(Icons.close, color: theme.iconTheme.color), // Close icon
                          onPressed: _closePopup, // Close popup on press
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLottieAnimation(), // Show animation
                            const SizedBox(height: 12),
                            Text(
                              _statusMessage ?? "", // Show status message
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: _statusColor ?? Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildPopupContent(), // Show popup content
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
