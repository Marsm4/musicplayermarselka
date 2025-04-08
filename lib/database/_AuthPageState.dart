
/*import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> _syncUserData(String userId, String email) async {
  try {
    final response = await supabase
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (response == null) {
      // Создаем запись в вашей таблице users
      await supabase.from('users').insert({
        'id': userId,
        'email': email,
        'name': email.split('@').first, // Генерируем имя из email
        'avatar': 'https://dilvfoapurgghqtsggml.supabase.co/storage/v1/object/public/Storage//profile.jpg',
      });
    }
  } catch (e) {
    print('Ошибка синхронизации пользователя: $e');
  }
}*/