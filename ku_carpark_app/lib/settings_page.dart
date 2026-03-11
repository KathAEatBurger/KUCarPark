import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  final user = FirebaseAuth.instance.currentUser;

  Future<void> _changePassword() async {

    TextEditingController oldPassword = TextEditingController();
    TextEditingController newPassword = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(
          title: const Text("Change Password"),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: oldPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Current Password",
                ),
              ),

              TextField(
                controller: newPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "New Password",
                ),
              ),

            ],
          ),

          actions: [

            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            ElevatedButton(
              child: const Text("Update"),
              onPressed: () async {

                try {

                  final credential = EmailAuthProvider.credential(
                    email: user!.email!,
                    password: oldPassword.text,
                  );

                  await user!.reauthenticateWithCredential(credential);

                  await user!.updatePassword(newPassword.text);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password updated successfully")),
                  );

                } catch (e) {

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );

                }

              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.teal,
      ),

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          Timestamp createdAt = data['createdAt'];
          DateTime date = createdAt.toDate();

          return ListView(
            children: [

              const SizedBox(height: 10),

              ListTile(
                leading: const Icon(Icons.person),
                title: Text(data['displayName'] ?? ""),
                subtitle: const Text("Display Name"),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.email),
                title: Text(data['email'] ?? ""),
                subtitle: const Text("Email"),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: Text(data['role'] ?? ""),
                subtitle: const Text("Role"),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(date.toString()),
                subtitle: const Text("Created At"),
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text("Change Password"),
                onTap: _changePassword,
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text("Logout"),
                onTap: () async {

                  await FirebaseAuth.instance.signOut();

                  Navigator.pop(context);
                },
              ),

            ],
          );
        },
      ),
    );
  }
}