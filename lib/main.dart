import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_config.dart';
import 'screens/native_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF07172E),
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ForexlancerApp());
}

class ForexlancerApp extends StatelessWidget {
  const ForexlancerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF07172E);
    const gold = Color(0xFFD4AF37);
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.light,
          primary: navy,
          secondary: gold,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1.5,
          shadowColor: const Color(0x2207172E),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFFE7EBF1))),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0x26D4AF37),
          height: 70,
          labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: navy)),
          iconTheme: WidgetStatePropertyAll(IconThemeData(color: navy)),
        ),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: navy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDE3EA))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFDDE3EA)))),
      ),
      home: const NativeGate(),
    );
  }
}
