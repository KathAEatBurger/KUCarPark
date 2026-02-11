import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Authentication'),
        actions: [
          // Profile Button
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<ProfileScreen>(
                  builder: (context) => ProfileScreen(
                    appBar: AppBar(title: const Text('User Profile')),
                    actions: [
                      SignedOutAction((context) {
                        Navigator.pushReplacementNamed(context, '/sign-in');
                      }),
                    ],
                  ),
                ),
              );
            },
          ), // Fixed closing parenthesis/comma here

          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/sign-in');
              }
            },
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centers content vertically
          children: [
            Text(
              'Hello ${FirebaseAuth.instance.currentUser?.email ?? 'User'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20), // Added some spacing
            Image.asset('assets/images/dash.png'),
          ],
        ),
      ),
    );
  }
}