import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const AboutUsScreen({super.key, required this.themeNotifier});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Us'),
        centerTitle: true,
      ),
      body: Center(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          itemCount: members.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final member = members[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundImage: AssetImage(member['image']!),

                    ),
                    const SizedBox(height: 10),
                    Text(
                      member['name']!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
            );
          },
        ),
      ),
    );
  }
}
