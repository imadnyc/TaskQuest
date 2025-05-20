import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:taskquest1/screens/sign_up_ui.dart';
import 'screens/authentication_ui.dart';
import 'theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();

  // Safely load .env file
  try {
    await dotenv.load(fileName: ".env");
    print('Loaded API Key: ${dotenv.env['OPENAI_API_KEY']}');
  } catch (e) {
    print('⚠️ .env file not found or failed to load: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppTheme _currentTheme = AppTheme.Default;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appThemeData[_currentTheme],
      home: AuthenticationUI(
        currentTheme: _currentTheme,
        onThemeChanged: (newTheme) {
          setState(() => _currentTheme = newTheme);
        },
      ),
    );
  }
}
