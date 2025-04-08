import 'package:supabase_flutter/supabase_flutter.dart';

class UsersTable {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> addUser(String name, String email, String password, String avatarUrl) async {
    try {
      await supabase.from('users').insert({
        'email': email,
        'name': name,
        'password': password, // В реальном приложении пароль нужно хэшировать!
        'avatar': avatarUrl,
      });
    } catch (e) {
      print('Ошибка добавления пользователя: $e');
      rethrow;
    }
  }
}