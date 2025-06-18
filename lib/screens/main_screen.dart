import 'package:flutter/material.dart'; // Import Flutter material design package

// MainScreen widget, a stateful widget that takes a theme notifier
class MainScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier; // Notifier for theme changes

  const MainScreen({super.key, required this.themeNotifier}); // Constructor

  @override
  State<MainScreen> createState() => _MainScreenState(); // Create state
}

// State class for MainScreen, with animation support
class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Animation controller for icon rotation

  @override
  void initState() {
    super.initState(); // Call parent init
    _controller = AnimationController(
      vsync: this, // Animation ticker
      duration: const Duration(milliseconds: 500), // Animation duration
      upperBound: 1.0, // Max value
      lowerBound: 0.0, // Min value
    );

    // Set initial animation value based on theme
    if (widget.themeNotifier.value == ThemeMode.dark) {
      _controller.value = 1.0; // Dark mode: fully rotated
    } else {
      _controller.value = 0.0; // Light mode: no rotation
    }
  }

  // Toggle theme and animate icon
  void _toggleTheme(bool isDark) {
    setState(() {
      widget.themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light; // Update theme
      isDark ? _controller.forward() : _controller.reverse(); // Animate icon
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeNotifier.value == ThemeMode.dark; // Check current theme

    return Scaffold(
      appBar: AppBar(
        // title: const Text("Main Screen"), // App bar title
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0), // Right padding
            child: GestureDetector(
              onTap: () => _toggleTheme(!isDark), // Toggle theme on tap
              child: AnimatedBuilder(
                animation: _controller, // Listen to animation
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 3.14, // Rotate icon
                    child: Icon(
                      isDark ? Icons.nightlight_round : Icons.wb_sunny, // Icon based on theme
                      color: isDark ? Colors.amber : Colors.orangeAccent, // Icon color
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0), // Horizontal padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            children: [
              // 1️⃣ Enlarged logo
              Image.asset('assets/logo.png', height: 210), // App logo
              const SizedBox(height: 20), // Spacing

              // 2️⃣ App name with red V and dynamic text color
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 28, // Font size
                    fontWeight: FontWeight.bold, // Bold text
                    letterSpacing: 1.2, // Letter spacing
                  ),
                  children: [
                    const TextSpan(
                      text: 'V', // Red 'V'
                      style: TextStyle(color: Colors.red),
                    ),
                    TextSpan(
                      text: 'ord Counter', // Rest of the name
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8), // Spacing

              // 3️⃣ Cheesy slogan
              const Text(
                'Faster than MS Word... in one very specific way.', // Slogan
                style: TextStyle(
                  fontSize: 16, // Font size
                  fontStyle: FontStyle.italic, // Italic text
                  color: Colors.grey, // Grey color
                ),
                textAlign: TextAlign.center, // Centered text
              ),
              const SizedBox(height: 40), // Spacing

              // 4️⃣ Start button
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/check'), // Navigate to check screen
                child: const Text('Start Application'), // Button label
              ),
              const SizedBox(height: 20), // Spacing

              // 5️⃣ About button
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/about'), // Navigate to about screen
                child: const Text('About Us'), // Button label
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose animation controller
    super.dispose(); // Call parent dispose
  }
}
