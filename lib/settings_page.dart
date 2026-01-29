import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.person),
            title: Text("Account"),
            subtitle: Text("Edit profile, change password"),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text("Notifications"),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.lock),
            title: Text("Privacy"),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info),
            title: Text("About App"),
          ),
        ],
      ),
    );
  }
}