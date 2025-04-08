import 'package:flutter/material.dart';
import 'package:marselkaplaer/PlaylistsPage.dart';
import 'package:marselkaplaer/auth.dart';
import 'package:marselkaplaer/database/landing.dart';
import 'package:marselkaplaer/home.dart';
import 'package:marselkaplaer/music/player.dart';
import 'package:marselkaplaer/recovery.dart';
import 'package:marselkaplaer/reg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpbHZmb2FwdXJnZ2hxdHNnZ21sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5NTk5MTQsImV4cCI6MjA1NTUzNTkxNH0.0SdlUcFWNMHGW1cy1YrKiGTraVSl8_HabUHVkHNKA2A',
    url: 'https://dilvfoapurgghqtsggml.supabase.co',
  );
  runApp(const AppTheme());
}

class AppTheme extends StatelessWidget {
  const AppTheme({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        listTileTheme: ListTileThemeData(
          textColor: Colors.white,
          iconColor: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        scaffoldBackgroundColor: Colors.transparent,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.white),
            foregroundColor: WidgetStatePropertyAll(Colors.blueGrey),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(Colors.white),
            side: WidgetStatePropertyAll(
              BorderSide(color: Colors.white),
            ),
          ),
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => LandingPage(),
        '/auth': (context) => AuthPage(),
        '/reg': (context) => RegPage(),
        '/recovery': (context) => RecoveryPage(),
        '/home': (context) => TrackListPage(),
        '/player': (context) => PlayerPage(),
        '/playlists': (context) => PlaylistsPage(),
      },
    );
  }
}
