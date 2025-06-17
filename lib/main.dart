import 'package:flutter/material.dart'; // Import Flutter's material design package
import 'screens/main_screen.dart'; // Import the main screen widget
import 'screens/about_us_screen.dart'; // Import the about us screen widget
import 'screens/upload_files_screen.dart'; // Import the upload files screen widget
import 'screens/check_connection_screen.dart'; // Import the check connection screen widget
import 'screens/general_results_screen.dart'; // Import the general results screen widget
import 'screens/specific_results_screen.dart'; // Import the specific results screen widget
import 'screens/file_detail_screen.dart'; // Import the file detail screen widget

void main() {
  runApp(const MyApp()); // Entry point: run the app with MyApp as the root widget
}

class MyApp extends StatefulWidget { // Define a stateful widget for the app
  const MyApp({super.key}); // Constructor with optional key

  @override
  State<MyApp> createState() => _MyAppState(); // Create the mutable state for MyApp
}

class _MyAppState extends State<MyApp> { // State class for MyApp
  final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.light); // Notifier to manage theme mode

  void toggleTheme() { // Method to toggle between light and dark themes
    _themeNotifier.value =
        _themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark; // Switch theme mode
  }

  @override
  Widget build(BuildContext context) { // Build method for the widget tree
    return ValueListenableBuilder<ThemeMode>( // Listen to theme changes
      valueListenable: _themeNotifier, // The theme notifier to listen to
      builder: (context, themeMode, _) { // Builder function with current theme mode
        return MaterialApp( // The root MaterialApp widget
          debugShowCheckedModeBanner: false, // Hide the debug banner
          title: 'PDC App', // App title
          theme: ThemeData.light(), // Light theme data
          darkTheme: ThemeData.dark(), // Dark theme data
          themeMode: themeMode, // Current theme mode
          initialRoute: '/', // Initial route of the app
          routes: { // Define named routes
            '/': (context) => MainScreen(themeNotifier: _themeNotifier), // Main screen route
            '/about': (context) => AboutUsScreen(themeNotifier: _themeNotifier), // About us screen route
            '/check': (context) => CheckConnectionScreen(themeNotifier: _themeNotifier), // Check connection screen route
            // '/upload': (context) => UploadFilesScreen(themeNotifier: _themeNotifier), // (Commented out) Upload files screen route
            '/general-results': (context) { // General results screen route
              final args = ModalRoute.of(context)!.settings.arguments; // Get route arguments
              if (args == null || args is! Map<String, dynamic>) { // Check if arguments are valid
                return const Scaffold(
                  body: Center(child: Text("Missing or invalid result data")), // Show error if invalid
                );
              }
              return GeneralResultsScreen(resultData: args); // Pass arguments to GeneralResultsScreen
            },
            // '/specific-results': (context) {
            //   final resultData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            //   return SpecificResultsScreen(resultData: resultData);
            // },

            '/specific-results': (context) { // Specific results screen route
              final args = ModalRoute.of(context)!.settings.arguments; // Get route arguments
              if (args == null || args is! Map<String, dynamic>) { // Check if arguments are valid
                return const Scaffold(
                  body: Center(child: Text("Missing or invalid result data")), // Show error if invalid
                );
              }
              return SpecificResultsScreen(resultData: args); // Pass arguments to SpecificResultsScreen
            },
            '/file-detail': (context) { // File detail screen route
              final args = ModalRoute.of(context)!.settings.arguments; // Get route arguments
              if (args == null || args is! Map<String, dynamic>) { // Check if arguments are valid
                return const Scaffold(
                  body: Center(child: Text("Missing or invalid file data")), // Show error if invalid
                );
              }
              return FileDetailScreen(fileData: args); // Pass arguments to FileDetailScreen
            },
          },
        );
      },
    );
  }
}
