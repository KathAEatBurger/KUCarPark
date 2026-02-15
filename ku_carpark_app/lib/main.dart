import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signin.dart';
import 'home.dart';

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
      title: 'KU Carpark',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38B38D),
          primary: const Color(0xFF38B38D),  
          secondary: Colors.grey[600],       
          surface: Colors.white,              
        ),
        
        
        inputDecorationTheme: InputDecorationTheme(
          border: const UnderlineInputBorder(),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF38B38D), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.grey[600]),
        ),

        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF38B38D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),

        
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700], 
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          if (snapshot.hasData) {
            return const HomePage();
          }
          
          return const SigninPage();
        },
      ),
      
      routes: {
        '/sign-in': (context) => const SigninPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}