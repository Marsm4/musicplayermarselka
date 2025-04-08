import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> LogOut() async {
    await supabase.auth.signOut();
  }

  Future<User?> sighUp(String email, String password) async {
    try {
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      return res.user;
    } catch (e) {
      print('Ошибка регистрации: $e');
      return null;
    }
  }
}