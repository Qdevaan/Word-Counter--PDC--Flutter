import 'package:flutter/material.dart'; // Import Flutter material design package
import 'dart:async'; // Import for Timer functionality
import 'dart:math'; // Import for random number generation

// Define a stateful widget for the About Us screen
class AboutUsScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier; // Theme notifier for theme changes

  const AboutUsScreen({super.key, required this.themeNotifier}); // Constructor

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState(); // Create state
}

// State class for AboutUsScreen
class _AboutUsScreenState extends State<AboutUsScreen> with SingleTickerProviderStateMixin {
  // List of team members with their details
  final List<Map<String, String>> members = const [
    {
      'name': 'Abdul Rehman Tariq',
      'reg': 'FA22-BCS-017',
      'quote': "I write code... sometimes it even works!",
      'image': 'assets/avatars/tariq.png'
    },
    {
      'name': 'Zain Ul Abideen',
      'reg': 'FA22-BCS-020',
      'quote': "Ctrl + C and Ctrl + V is my superpower.",
      'image': 'assets/avatars/zain.png'
    },
    {
      'name': 'Mahnoor Tariq',
      'reg': 'FA22-BCS-021',
      'quote': "99 little bugs in the code, take one down, 127 bugs now...",
      'image': 'assets/avatars/mahnoor.png'
    },
    {
      'name': 'Muhammad Ahmad',
      'reg': 'FA22-BCS-025',
      'quote': "Love Triange, Me, GPT and Errors.",
      'image': 'assets/avatars/ahmad.png'
    },
  ];

  int _tapCounter = 0; // Counter for taps on Ahmad's card
  Timer? _tapResetTimer; // Timer to reset tap counter
  bool _showEasterEgg = false; // Whether to show the easter egg
  double _opacity = 0.0; // Opacity for fade animation
  List<Offset> _skeletonPositions = []; // Positions for skeleton images

  final Random _random = Random(); // Random number generator

  // Handle taps on Ahmad's card
  void _handleAhmadCardTap() {
    _tapCounter++; // Increment tap counter

    _tapResetTimer?.cancel(); // Cancel previous timer if any
    _tapResetTimer = Timer(const Duration(seconds: 2), () {
      _tapCounter = 0; // Reset tap counter after 2 seconds
    });

    if (_tapCounter >= 5) { // If tapped 5 times
      _tapCounter = 0; // Reset counter
      _triggerEasterEgg(); // Show easter egg
    }
  }

  // Show the easter egg animation
  void _triggerEasterEgg() {
    final screenSize = MediaQuery.of(context).size; // Get screen size
    final skeletonCount = 10; // Number of skeletons to show
    List<Offset> positions = []; // List to hold random positions

    for (int i = 0; i < skeletonCount; i++) {
      final dx = _random.nextDouble() * (screenSize.width - 60); // Random x position
      final dy = _random.nextDouble() * (screenSize.height - 150); // Random y position
      positions.add(Offset(dx, dy)); // Add position to list
    }

    setState(() {
      _skeletonPositions = positions; // Set skeleton positions
      _showEasterEgg = true; // Show easter egg
      _opacity = 1.0; // Set opacity to fully visible
    });

    Timer(const Duration(seconds: 3), () { // After 3 seconds
      setState(() => _opacity = 0.0); // Fade out

      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() => _showEasterEgg = false); // Hide easter egg after fade
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // Get screen width
    // Determine number of columns based on screen width
    final crossAxisCount = screenWidth > 1000
        ? 4
        : screenWidth > 700
            ? 3
            : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'), // App bar title
        centerTitle: true, // Center the title
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16), // Padding around content
              child: Column(
                children: [
                  const Text(
                    '“We came. We coded. We conquered (after a lot of ChatGPT)😎.”', // Team quote
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 5), // Spacing
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(), // Disable grid scrolling
                    shrinkWrap: true, // Let grid take only needed space
                    itemCount: members.length, // Number of members
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount, // Columns
                      mainAxisSpacing: 5, // Vertical spacing
                      crossAxisSpacing: 5, // Horizontal spacing
                      childAspectRatio: 0.53, // Card aspect ratio
                    ),
                    itemBuilder: (context, index) {
                      final member = members[index]; // Get member data
                      final isAhmad = member['reg'] == 'FA22-BCS-025'; // Check if Ahmad

                      return GestureDetector(
                        onTap: isAhmad ? _handleAhmadCardTap : null, // Only Ahmad's card is tappable
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16), // Rounded corners
                          ),
                          elevation: 5, // Card shadow
                          child: Padding(
                            padding: const EdgeInsets.all(12), // Padding inside card
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 60, // Avatar size
                                  backgroundImage: AssetImage(member['image']!), // Member image
                                ),
                                const SizedBox(height: 12), // Spacing
                                Text(
                                  member['name']!, // Member name
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  member['reg']!, // Registration number
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 6), // Spacing
                                Text(
                                  "\"${member['quote']}\"", // Member quote
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Easter Egg with Fade Animation
          if (_showEasterEgg)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500), // Fade duration
              opacity: _opacity, // Current opacity
              child: Container(
                color: Colors.black.withOpacity(0.3), // Semi-transparent overlay
                child: Stack(
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/logo.png', // Center logo
                        width: 200,
                        height: 200,
                      ),
                    ),
                    ..._skeletonPositions.map((pos) {
                      return Positioned(
                        left: pos.dx, // Skeleton x position
                        top: pos.dy, // Skeleton y position
                        child: Image.asset(
                          'assets/easteregg/skeleton.png', // Skeleton image
                          width: 80,
                          height: 80,
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
