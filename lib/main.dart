import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'utilities/theme.dart';
import 'utilities/dependencies.dart';
import 'screens/home_page.dart';
import 'screens/settings_page.dart'; // ThemeController lives here

void main() {
  // Register ThemeController before the app starts so it's available everywhere
  Get.put(ThemeController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();

    // Obx wraps GetMaterialApp so the whole app rebuilds when theme changes
    return Obx(() => GetMaterialApp(
          title: 'AidLink - Smart Social Assistance',
          // Light theme — your existing customTheme
          theme: customTheme,
          // Dark theme — mirrors customTheme but dark
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.dark(
              primary: const Color(0xff1A56C4),
              secondary: const Color(0xff0d9488),
              surface: const Color(0xff1f2937),
            ),
            scaffoldBackgroundColor: const Color(0xff111827),
            cardColor: const Color(0xff1f2937),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xff0A3080),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1A56C4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: const Color(0xff374151),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white),
              bodySmall: TextStyle(color: Color(0xffb0b8c8)),
            ),
          ),
          // This is what makes theme changes instant across the whole app
          themeMode: themeCtrl.themeMode,
          debugShowCheckedModeBanner: false,
          initialBinding: InitialBindings(),
          home: const LoadingScreen(),
        ));
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assist_walker,
                size: 64, color: Color(0xff164EB0)),
            const SizedBox(height: 20),
            const Text(
              'AidLink',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xff164EB0),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Smart Social Assistance Matching',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('Loading your assistance portal...'),
          ],
        ),
      ),
    );
  }
}