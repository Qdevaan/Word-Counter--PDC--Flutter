import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'dart:convert'; 

class UploadFilesScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final String serverUrl;

  const UploadFilesScreen({
    super.key,
    required this.themeNotifier,
    required this.serverUrl,
  });

  @override
  State<UploadFilesScreen> createState() => _UploadFilesScreenState();
}

class _UploadFilesScreenState extends State<UploadFilesScreen> {
  Map<String, dynamic>? _responseData; // Add this at class level (_UploadFilesScreenState)
  final List<PlatformFile?> _selectedFiles = List.filled(10, null);
  String? _statusMessage;
  IconData? _statusIcon;
  Color? _statusColor;
  bool _showPopup = false;
  String? _errorMessage;

  Future<void> _pickFile(int index) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
      withData: true,
    );
    print(result); // Print the result to the console


    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles[index] = result.files.first;
      });
    }
  }

  void _showStatusPopup(String message, IconData icon, Color color) {
    setState(() {
      _statusMessage = message;
      _statusIcon = icon;
      _statusColor = color;
      _errorMessage = null;
      _showPopup = true;
    });
  }

  void _updatePopup(String message, IconData icon, Color color, {String? error}) {
    setState(() {
      _statusMessage = message;
      _statusIcon = icon;
      _statusColor = color;
      _errorMessage = error;
    });
  }

  void _closePopup() {
    setState(() {
      _showPopup = false;
      _statusMessage = null;
      _statusIcon = null;
      _statusColor = null;
      _errorMessage = null;
    });
  }

  Future<void> _submitFiles() async {
    final selected = _selectedFiles.where((file) => file != null).toList();

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one file.")),
      );
      return;
    }

    final uri = Uri.parse("${widget.serverUrl}/upload-files");

    final request = http.MultipartRequest('POST', uri);

    for (var file in selected) {
      if (file != null && file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            file.bytes!,
            filename: file.name,
          ),
        );
      }
    }

    _showStatusPopup("Uploading...", Icons.upload_file, Colors.blue);

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        _responseData = json.decode(response.body);
        _updatePopup("Processing...", Icons.check_circle, Colors.green);

        // Simulate processing delay
        await Future.delayed(const Duration(seconds: 2));

        _updatePopup("Processing Complete!", Icons.check_circle, Colors.green);
      } else {
        _updatePopup("Upload failed", Icons.cancel, Colors.red,
            error: "Status: ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      _updatePopup("Error occurred", Icons.error_outline, Colors.red,
          error: e.toString());
    }
  }

  Widget _buildLottieAnimation() {
    if (_statusMessage == "Uploading...") {
      return Lottie.asset('assets/animations/uploading.json', width: 100);
    }else if (_statusMessage?.startsWith("Processing...") ?? false) {
      return Lottie.asset('assets/animations/success.json', width: 100);
    }else if (_statusMessage?.startsWith("Processin Complete") ?? false) {
      return Lottie.asset('assets/animations/success-2.json', width: 100);
    } else if (_statusMessage == "Upload failed" || _statusMessage == "Error occurred") {
      return Lottie.asset('assets/animations/error.json', width: 100);
    } else {
      return Icon(
        _statusIcon ?? Icons.info_outline,
        color: _statusColor ?? Colors.grey,
        size: 60,
      );
    }
  }

  Widget _buildPopupContent() {
    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: Colors.red),
      );
    } else if (_statusMessage?.startsWith("Processing Complete") ?? false) {
      return Column(
        children: [
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.bar_chart),
            label: const Text("General Review"),
            

            onPressed: () {
              if (_responseData != null) {
                Navigator.pushNamed(
                  context,
                  '/general-results',
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
        if (_responseData != null) {
          Navigator.pushNamed(
            context,
            '/specific-results',
            arguments: _responseData,
          );
        }
      },
    ),

        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Upload Files")),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: 10,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final file = _selectedFiles[index];
                      return ElevatedButton.icon(
                        onPressed: () => _pickFile(index),
                        icon: const Icon(Icons.upload_file),
                        label: Text(file?.name ?? "Choose File ${index + 1}"),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _submitFiles,
                        icon: const Icon(Icons.send),
                        label: const Text("Submit Files"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
                ),
          if (_showPopup)
            Material(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  width: 280,
                  height: 360,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
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
                          icon: Icon(Icons.close, color: theme.iconTheme.color),
                          onPressed: _closePopup,
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLottieAnimation(),
                            const SizedBox(height: 12),
                            Text(
                              _statusMessage ?? "",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: _statusColor ?? Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildPopupContent(),
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
