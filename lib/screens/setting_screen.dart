import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:semuria/screens/auth_screen.dart';
import 'package:semuria/util/theme_provider.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    Future<void> signOut(BuildContext context) async {
      await FirebaseAuth.instance.signOut();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const StartScreen()),
        (Route<dynamic> route) => false,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontFamily: 'playpen',
            fontWeight: FontWeight.bold,
            color: Color(0xFFfd0054),
            shadows: <Shadow>[
              Shadow(
                offset: Offset(0, 1.0),
                blurRadius: 3.0,
                color: Color.fromARGB(255, 164, 164, 164),
              ),
            ],
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: theme.colorScheme.onBackground,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text(
                'Mode Gelap',
                style: TextStyle(
                  fontFamily: 'playpen',
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Switch(
                value: themeProvider.isDark,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  fontFamily: 'playpen',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                signOut(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.info, color: theme.colorScheme.onBackground),
              title: const Text(
                'About Us',
                style: TextStyle(
                  fontFamily: 'playpen',
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'The Semurians',
                  applicationVersion: '1.0.0',
                  children: [
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Created by Semurian Group',
                        style: TextStyle(fontFamily: 'playpen'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
