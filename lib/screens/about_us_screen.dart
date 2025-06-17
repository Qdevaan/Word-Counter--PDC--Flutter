import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class AboutUsScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const AboutUsScreen({super.key, required this.themeNotifier});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> with SingleTickerProviderStateMixin {
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
      'quote': "I don't need Google, my code has all the answers (wrong ones).",
      'image': 'assets/avatars/ahmad.png'
    },
  ];

  int _tapCounter = 0;
  Timer? _tapResetTimer;
  bool _showEasterEgg = false;
  double _opacity = 0.0;
  List<Offset> _skeletonPositions = [];

  final Random _random = Random();

  void _handleAhmadCardTap() {
    _tapCounter++;

    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(seconds: 2), () {
      _tapCounter = 0;
    });

    if (_tapCounter >= 5) {
      _tapCounter = 0;
      _triggerEasterEgg();
    }
  }

  void _triggerEasterEgg() {
    final screenSize = MediaQuery.of(context).size;
    final skeletonCount = 10;
    List<Offset> positions = [];

    for (int i = 0; i < skeletonCount; i++) {
      final dx = _random.nextDouble() * (screenSize.width - 60); // prevent overflow
      final dy = _random.nextDouble() * (screenSize.height - 150);
      positions.add(Offset(dx, dy));
    }

    setState(() {
      _skeletonPositions = positions;
      _showEasterEgg = true;
      _opacity = 1.0;
    });

    Timer(const Duration(seconds: 3), () {
      setState(() => _opacity = 0.0);

      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() => _showEasterEgg = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1000
        ? 4
        : screenWidth > 700
            ? 3
            : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '“We came. We coded. We conquered (after a lot of ChatGPT)😎.”',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: members.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final isAhmad = member['reg'] == 'FA22-BCS-025';

                      return GestureDetector(
                        onTap: isAhmad ? _handleAhmadCardTap : null,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundImage: AssetImage(member['image']!),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  member['name']!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  member['reg']!,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "\"${member['quote']}\"",
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
              duration: const Duration(milliseconds: 500),
              opacity: _opacity,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Stack(
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/logo.png',
                        width: 200,
                        height: 200,
                      ),
                    ),
                    ..._skeletonPositions.map((pos) {
                      return Positioned(
                        left: pos.dx,
                        top: pos.dy,
                        child: Image.asset(
                          'assets/easteregg/skeleton.png',
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
