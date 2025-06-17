import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const MainScreen({super.key, required this.themeNotifier});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      upperBound: 1.0,
      lowerBound: 0.0,
    );

    if (widget.themeNotifier.value == ThemeMode.dark) {
      _controller.value = 1.0;
    } else {
      _controller.value = 0.0;
    }
  }

  void _toggleTheme(bool isDark) {
    setState(() {
      widget.themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
      isDark ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Main Screen"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => _toggleTheme(!isDark),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 3.14,
                    child: Icon(
                      isDark ? Icons.nightlight_round : Icons.wb_sunny,
                      color: isDark ? Colors.amber : Colors.orangeAccent,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1️⃣ Enlarged logo
              Image.asset('assets/logo.png', height: 210),
              const SizedBox(height: 20),

              // 2️⃣ App name with red V
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.black, // fallback
                  ),
                  children: [
                    TextSpan(
                      text: 'V',
                      style: TextStyle(color: Colors.red),
                    ),
                    TextSpan(
                      text: 'ord Counter',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 3️⃣ Cheesy slogan
              const Text(
                'Faster than MS Word... in one very specific way.',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // 4️⃣ Start button
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/check'),
                child: const Text('Start Application'),
              ),
              const SizedBox(height: 20),

              // 5️⃣ About button
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/about'),
                child: const Text('About Us'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
