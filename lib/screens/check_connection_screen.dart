import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'upload_files_screen.dart';

class CheckConnectionScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const CheckConnectionScreen({super.key, required this.themeNotifier});

  @override
  State<CheckConnectionScreen> createState() => _CheckConnectionScreenState();
}

class _CheckConnectionScreenState extends State<CheckConnectionScreen> {
  final TextEditingController _inputController = TextEditingController();
  bool _checking = false;
  bool? _connectionSuccess;
  String? _fullUrl;

  Timer? _matrixTimer;
  String _matrixText = "";

  void _startMatrixText() {
    _matrixTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() {
        _matrixText =
            List.generate(10, (_) => Random().nextBool() ? '1' : '0').join(' ');
      });
    });
  }

  void _stopMatrixText() {
    _matrixTimer?.cancel();
    setState(() {
      _matrixText = "";
    });
  }

  Future<void> _checkConnection() async {
    final userInput = _inputController.text.trim();

    if (userInput.isEmpty || !RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(userInput)) {
      setState(() {
        _connectionSuccess = false;
        _fullUrl = null;
      });
      return;
    }

    setState(() {
      _checking = true;
      _connectionSuccess = null;
    });

    _startMatrixText();
    final startTime = DateTime.now();

    final url = "http://$userInput:8000/ping";
    _fullUrl = "http://$userInput:8000";


    bool success;
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      success = response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      success = false;
    }

    final elapsed = DateTime.now().difference(startTime);
    final remaining = Duration(seconds: 2) - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    _stopMatrixText();

    setState(() {
      _checking = false;
      _connectionSuccess = success;
    });
  }

  void _resetPopup() {
    setState(() {
      _connectionSuccess = null;
      _fullUrl = null;
    });
  }

  @override
  void dispose() {
    _stopMatrixText();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Check Connection')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text('Enter the full local IP address (e.g. 192.168.0.102):'),
                const SizedBox(height: 10),
                TextField(
                  controller: _inputController,
                    decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 192.168.0.102',

                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      (_checking || _connectionSuccess == true) ? null : _checkConnection,
                  child: _checking
                      ? Text(
                          _matrixText,
                          style: const TextStyle(fontFamily: 'Courier', fontSize: 16),
                        )
                      : const Text('Check Connection'),
                ),
              ],
            ),
          ),
          if (_connectionSuccess != null)
            Material(
              color: Colors.transparent,
              elevation: 30,
              child: Container(
                width: 280,
                height: 280,
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
                        onPressed: _resetPopup,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _connectionSuccess! ? Icons.check_circle : Icons.cancel,
                            color: _connectionSuccess! ? Colors.green : Colors.red,
                            size: 60,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _connectionSuccess!
                                ? 'Connection successful!'
                                : 'Connection failed!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  _connectionSuccess! ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_fullUrl != null)
                            Text(
                              _fullUrl!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          const SizedBox(height: 15),
                          if (_connectionSuccess == true)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UploadFilesScreen(
                                      themeNotifier: widget.themeNotifier,
                                      serverUrl: _fullUrl!,
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Upload Files"),
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
