/*import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'dart:io'; // Для работы с File
import 'package:image_picker/image_picker.dart'; // Для выбора изображений (если требуется)

class StorageCloud {
  final Supabase _supabase = Supabase.instance;

  // Метод для загрузки изображения в облако
  Future<void> uploadImage(XFile imageFile) async {
    try {
      // Получаем имя файла из пути
      final fileName = path.basename(imageFile.path);

      // Загружаем файл в облако
      await _supabase.client.storage
          .from('storage') // Укажите имя вашего бакета
          .upload(fileName, File(imageFile.path));

      print("Изображение успешно загружено: $fileName");
    } catch (e) {
      print("Ошибка при загрузке изображения: $e");
      rethrow; // Повторно выбрасываем исключение для обработки в вызывающем коде
    }
  }

  // Метод для выбора изображения (если требуется)
  Future<XFile?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    return await picker.pickImage(source: ImageSource.gallery);
  }
}*/