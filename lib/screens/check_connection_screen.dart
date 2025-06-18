import 'dart:async';
import 'dart:convert';
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
  String _connectionType = 'Local IP';

  Timer? _matrixTimer;
  String _matrixText = "";

  void _startMatrixText() {
    _matrixTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() {
        _matrixText = List.generate(10, (_) => Random().nextBool() ? '1' : '0').join(' ');
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

    // Validate input
    if (userInput.isEmpty ||
        (_connectionType == 'Local IP' &&
            !RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(userInput)) ||
        (_connectionType == 'Ngrok' &&
            !RegExp(r'^[\w.-]+\.(ngrok\.io|ngrok-free\.app)$').hasMatch(userInput))) {
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

    final url = _connectionType == 'Local IP'
        ? "http://$userInput:8000/ping"
        : "https://$userInput/ping";

    _fullUrl = _connectionType == 'Local IP'
        ? "http://$userInput:8000"
        : "https://$userInput";

    bool success = false;
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final msg = json['message']?.toString().toLowerCase();
        success = ['pong', 'server is alive!', 'connection ok', 'connection successful'].contains(msg);
      }
    } catch (e) {
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
                const Text('Select connection type:'),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: _connectionType,
                  items: const [
                    DropdownMenuItem(value: 'Local IP', child: Text('Local IP')),
                    DropdownMenuItem(value: 'Ngrok', child: Text('Ngrok')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _connectionType = value!;
                      _inputController.clear();
                      _connectionSuccess = null;
                      _fullUrl = null;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  _connectionType == 'Local IP'
                      ? 'Enter the full local IP address (e.g. 192.168.0.102):'
                      : 'Enter your full Ngrok domain (e.g. abc123.ngrok.io):',
                ),
                const SizedBox(height: 5),
                if (_connectionType == 'Local IP')
                  const Text(
                    'Make sure that you and your server are on the same network.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: _connectionType == 'Local IP'
                        ? 'e.g. 192.168.0.102'
                        : 'e.g. abc123.ngrok-free.app',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (_checking || _connectionSuccess == true) ? null : _checkConnection,
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
                              color: _connectionSuccess! ? Colors.green : Colors.red,
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
