import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'screens/about_us_screen.dart';
import 'screens/upload_files_screen.dart';
import 'screens/check_connection_screen.dart';
import 'screens/general_results_screen.dart';
import 'screens/specific_results_screen.dart';
import 'screens/file_detail_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.light);

  void toggleTheme() {
    _themeNotifier.value =
        _themeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'PDC App',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          initialRoute: '/',
          routes: {
            '/': (context) => MainScreen(themeNotifier: _themeNotifier),
            '/about': (context) => AboutUsScreen(themeNotifier: _themeNotifier),
            '/check': (context) => CheckConnectionScreen(themeNotifier: _themeNotifier),
            // '/upload': (context) => UploadFilesScreen(themeNotifier: _themeNotifier),
            '/general-results': (context) {
              final args = ModalRoute.of(context)!.settings.arguments;
              if (args == null || args is! Map<String, dynamic>) {
                return const Scaffold(
                  body: Center(child: Text("Missing or invalid result data")),
                );
              }
              return GeneralResultsScreen(resultData: args);
            },
            // '/specific-results': (context) {
            //   final resultData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            //   return SpecificResultsScreen(resultData: resultData);
            // },

            '/specific-results': (context) {
              final args = ModalRoute.of(context)!.settings.arguments;
              if (args == null || args is! Map<String, dynamic>) {
                return const Scaffold(
                  body: Center(child: Text("Missing or invalid result data")),
                );
              }
              return SpecificResultsScreen(resultData: args);
            },
            '/file-detail': (context) {
              final args = ModalRoute.of(context)!.settings.arguments;
              if (args == null || args is! Map<String, dynamic>) {
                return const Scaffold(
                  body: Center(child: Text("Missing or invalid file data")),
                );
              }
              return FileDetailScreen(fileData: args);
            },
          },
        );
      },
    );
  }
}
