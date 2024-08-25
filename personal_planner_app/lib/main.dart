import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:personal_planner_app/screens/login_screen.dart';
import 'package:personal_planner_app/screens/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Planner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple,
          secondary: Colors.deepOrange,
          background: Colors.white,
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
            displayLarge: TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            displayMedium: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            displaySmall: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            headlineLarge: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            headlineMedium: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            titleLarge: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            titleMedium: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.purple),
            bodyLarge: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.black87),
            bodyMedium: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.black87),
            bodySmall: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.normal,
                color: Colors.black87),
            labelLarge: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            labelMedium: TextStyle(fontSize: 12, color: Colors.white),
            labelSmall: TextStyle(fontSize: 10, color: Colors.white)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          titleTextStyle: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white, // Setzt die Textfarbe auf Weiß
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.deepPurple),
          ),
          labelStyle: TextStyle(
              color: Colors.black87), // Label-Farbe auf Schwarz gesetzt
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            // Benutzer ist eingeloggt
            return const HomeScreen();
          } else {
            // Benutzer ist nicht eingeloggt
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
