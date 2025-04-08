// drawer.dart
import 'package:flutter/material.dart';
import 'package:marselkaplaer/FavoritesPage.dart';
import 'package:marselkaplaer/PlaylistsPage.dart';
import 'package:marselkaplaer/auth.dart';
import 'package:marselkaplaer/database/auth.dart';

import 'package:shared_preferences/shared_preferences.dart';

class DrawerPage extends StatefulWidget {
  const DrawerPage({super.key});

  @override
  State<DrawerPage> createState() => _DrawerPageState();
}

class _DrawerPageState extends State<DrawerPage> {
  String userName = '';
  String userEmail = '';
  String userAvatarUrl = '';
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Гость';
      userEmail = prefs.getString('userEmail') ?? 'Не авторизован';
      userAvatarUrl = prefs.getString('userAvatarUrl') ??
          'https://dilvfoapurgghqtsggml.supabase.co/storage/v1/object/public/Storage//profile.jpg';
    });
  }

  Future<void> _logout() async {
    await authService.LogOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.6,
      child: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade400,
                Colors.blue.shade700,
              ],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue.shade600,
                      Colors.blue.shade900,
                    ],
                  ),
                ),
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(userAvatarUrl),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: const Text(
                  "Моя музыка",
                  style: TextStyle(color: Colors.white),
                ),
                leading: const Icon(Icons.music_note, color: Colors.white),
                onTap: () {
                  Navigator.pop(context); // Закрываем drawer
                  Navigator.pushNamed(context, '/home');
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: const Text(
                  "Плейлисты",
                  style: TextStyle(color: Colors.white),
                ),
                leading:
                    const Icon(Icons.featured_play_list, color: Colors.white),
                onTap: () {
                  Navigator.pop(context); // Закрываем drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PlaylistsPage()),
                  );
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: const Text("Избранное",
                    style: TextStyle(color: Colors.white)),
                leading: const Icon(Icons.favorite, color: Colors.white),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const FavoritesPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
