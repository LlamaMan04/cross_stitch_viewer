import 'package:flutter/material.dart';

/// Basic application settings and product information screen.
class SettingsScreen extends StatelessWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  /// Builds the current settings list.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About StitchScope'),
            subtitle: Text('A home for your cross-stitch patterns.'),
          ),
        ],
      ),
    );
  }
}
