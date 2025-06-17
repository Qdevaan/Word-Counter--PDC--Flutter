import 'dart:async'; // Import for Timer and asynchronous operations
import 'dart:math'; // Import for generating random numbers
import 'package:flutter/material.dart'; // Flutter UI toolkit
import 'package:http/http.dart' as http; // HTTP requests package
import 'upload_files_screen.dart'; // Import the UploadFilesScreen widget

// Stateful widget for checking server connection
class CheckConnectionScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier; // Theme notifier for theme changes

  const CheckConnectionScreen({super.key, required this.themeNotifier}); // Constructor

  @override
  State<CheckConnectionScreen> createState() => _CheckConnectionScreenState(); // Create state
}

// State class for CheckConnectionScreen
class _CheckConnectionScreenState extends State<CheckConnectionScreen> {
  final TextEditingController _inputController = TextEditingController(); // Controller for IP input field
  bool _checking = false; // Indicates if connection check is in progress
  bool? _connectionSuccess; // Stores result of connection check
  String? _fullUrl; // Stores the full server URL

  Timer? _matrixTimer; // Timer for matrix text animation
  String _matrixText = ""; // Animated matrix text

  // Starts the matrix text animation
  void _startMatrixText() {
    _matrixTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() {
        _matrixText =
            List.generate(10, (_) => Random().nextBool() ? '1' : '0').join(' '); // Generate random 1s and 0s
      });
    });
  }

  // Stops the matrix text animation
  void _stopMatrixText() {
    _matrixTimer?.cancel(); // Cancel the timer if running
    setState(() {
      _matrixText = ""; // Clear the matrix text
    });
  }

  // Checks the connection to the server
  Future<void> _checkConnection() async {
    final userInput = _inputController.text.trim(); // Get trimmed input

    // Validate IP address format
    if (userInput.isEmpty ||
        !RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(userInput)) {
      setState(() {
        _connectionSuccess = false; // Set connection as failed
        _fullUrl = null; // Clear URL
      });
      return; // Exit function
    }

    setState(() {
      _checking = true; // Set checking flag
      _connectionSuccess = null; // Reset connection result
    });

    _startMatrixText(); // Start matrix animation
    final startTime = DateTime.now(); // Record start time

    final url = "http://$userInput:8000/ping"; // Construct ping URL
    _fullUrl = "http://$userInput:8000"; // Store base URL

    bool success; // Variable to store success status
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5)); // Send GET request with timeout
      success = response.statusCode >= 200 && response.statusCode < 300; // Check for successful status code
    } catch (_) {
      success = false; // Set as failed on error
    }

    final elapsed = DateTime.now().difference(startTime); // Calculate elapsed time
    final remaining = Duration(seconds: 2) - elapsed; // Ensure minimum 2 seconds for UX
    if (remaining > Duration.zero) {
      await Future.delayed(remaining); // Wait if needed
    }

    _stopMatrixText(); // Stop matrix animation

    setState(() {
      _checking = false; // Reset checking flag
      _connectionSuccess = success; // Set connection result
    });
  }

  // Resets the popup dialog state
  void _resetPopup() {
    setState(() {
      _connectionSuccess = null; // Reset connection result
      _fullUrl = null; // Clear URL
    });
  }

  // Dispose controllers and timers
  @override
  void dispose() {
    _stopMatrixText(); // Stop animation timer
    _inputController.dispose(); // Dispose text controller
    super.dispose(); // Call superclass dispose
  }

  // Builds the widget tree
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get current theme

    return Scaffold(
      appBar: AppBar(title: const Text('Check Connection')), // App bar title
      body: Stack(
        alignment: Alignment.center, // Center stack children
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0), // Outer padding
            child: Column(
              children: [
                const Text('Enter the full local IP address (e.g. 192.168.0.102):'), // Instruction text
                const SizedBox(height: 5), // Spacing
                const Text(
                  'Make sure that you and your server are on the same network.',
                  style: TextStyle(fontSize: 13, color: Colors.grey), // Sub-instruction
                ),
                const SizedBox(height: 10), // Spacing
                TextField(
                  controller: _inputController, // Input controller
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(), // Input border
                    hintText: 'e.g. 192.168.0.102', // Placeholder text
                  ),
                  keyboardType: TextInputType.number, // Numeric keyboard
                ),
                const SizedBox(height: 20), // Spacing
                ElevatedButton(
                  onPressed: (_checking || _connectionSuccess == true)
                      ? null // Disable if checking or already successful
                      : _checkConnection, // Otherwise, check connection
                  child: _checking
                      ? Text(
                          _matrixText, // Show matrix animation while checking
                          style: const TextStyle(fontFamily: 'Courier', fontSize: 16),
                        )
                      : const Text('Check Connection'), // Button label
                ),
              ],
            ),
          ),
          if (_connectionSuccess != null) // Show popup if result is available
            Material(
              color: Colors.transparent, // Transparent background
              elevation: 30, // Popup elevation
              child: Container(
                width: 280,
                height: 280,
                padding: const EdgeInsets.all(20), // Inner padding
                decoration: BoxDecoration(
                  color: theme.cardColor, // Card color from theme
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3), // Shadow color
                      blurRadius: 30, // Shadow blur
                      offset: const Offset(0, 12), // Shadow offset
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
                        onPressed: _resetPopup, // Reset popup on close
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Minimize vertical space
                        children: [
                          Icon(
                            _connectionSuccess! ? Icons.check_circle : Icons.cancel, // Success or fail icon
                            color: _connectionSuccess! ? Colors.green : Colors.red, // Icon color
                            size: 60, // Icon size
                          ),
                          const SizedBox(height: 12), // Spacing
                          Text(
                            _connectionSuccess!
                                ? 'Connection successful!' // Success message
                                : 'Connection failed!', // Failure message
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  _connectionSuccess! ? Colors.green : Colors.red, // Text color
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10), // Spacing
                          if (_fullUrl != null)
                            Text(
                              _fullUrl!, // Show server URL
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          const SizedBox(height: 15), // Spacing
                          if (_connectionSuccess == true)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UploadFilesScreen(
                                      themeNotifier: widget.themeNotifier, // Pass theme notifier
                                      serverUrl: _fullUrl!, // Pass server URL
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Upload Files"), // Button label
                            )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
