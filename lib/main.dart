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
      ),
      home: const NativeGate(),
    );
  }
}
