import 'package:flutter/material.dart';
import 'AdminPage.dart';
import 'WelcomeScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: 'AIzaSyBzU3K2PdePKmgrP1vEhT8myzVUU0xk7y4',
        authDomain: 'clinic-5e409.firebaseapp.com',
        projectId: 'clinic-5e409',
        storageBucket: 'clinic-5e409.firebasestorage.app',
        messagingSenderId: '138103242978',
        appId: '1:138103242978:web:62b85ec03686e14ebd9ebb',
        measurementId: 'G-7YCNZGRWFR'
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(ClinicBookingApp());
}


class ClinicBookingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clinic Booking',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Segoe UI',
        scaffoldBackgroundColor: Colors.grey[100],
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      home: WelcomeScreen(),
    );
  }
}

