import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SigninPage extends StatelessWidget {
  const SigninPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [
        EmailAuthProvider(),
        GoogleProvider(clientId: "59601837642-h7p8aseudpgjleqjllqr3bnpgfeoft0b.apps.googleusercontent.com"),
      ],
      actions: [
        
        AuthStateChangeAction<UserCreated>((context, state) async {
          final user = state.credential.user;
          if (user != null) {
            await _initializeUserData(user);
          }
          if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
        }),
        
        
        AuthStateChangeAction<SignedIn>((context, state) async {
          final user = state.user;
          if (user != null) {
            await _initializeUserData(user); 
          }
          if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
        }),
      ],
      headerBuilder: (context, constraints, shrinkOffset) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.asset('assets/images/kucarpark_logo.jpg'),
          ),
        );
      },
      subtitleBuilder: (context, action) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: action == AuthAction.signIn
              ? const Text('Welcome to KU Carpark! Please log in.')
              : const Text('New here? Create an account to get started!'),
        );
      },
    );
  }

  
  Future<void> _initializeUserData(dynamic user) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'email': user.email,
        'role': 'user',
        'displayName': user.displayName ?? 'New User',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}