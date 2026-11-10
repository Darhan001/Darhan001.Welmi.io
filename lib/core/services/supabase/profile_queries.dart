import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:lumina/core/models/supabase_models.dart';
import 'package:lumina/core/services/supabase/supabase_base.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Профиль пользователя и его фото.
mixin ProfileQueries on SupabaseQueryBase {
  Future<UserProfile> createProfile(UserProfile profile) async {
    final response = await client
        .from('profiles')
        .insert(profile.toJson())
        .select()
        .single();
    return UserProfile.fromJson(response);
  }

  Future<UserProfile?> getProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response != null ? UserProfile.fromJson(response) : null;
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    final response = await client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id)
        .select()
        .single();
    return UserProfile.fromJson(response);
  }

  /// Создать профиль если нет, обновить если есть
  Future<UserProfile> upsertProfile(UserProfile profile) async {
    final existing = await getProfile(profile.id);
    if (existing != null) {
      return updateProfile(profile);
    } else {
      return createProfile(profile);
    }
  }

  /// Допустимые форматы аватара → MIME-тип.
  static const avatarMimeTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
  };

  /// Лимит размера аватара (после сжатия image_picker фото много меньше).
  static const maxAvatarBytes = 5 * 1024 * 1024;

  /// Загрузить фото профиля в Supabase Storage (bucket 'avatars')
  /// и вернуть публичный URL.
  ///
  /// Bucket публичный, поэтому расширение и тип проверяются: раньше в него
  /// можно было положить файл с любым расширением (например .html/.svg),
  /// который отдавался бы с домена Storage. Бросает [AvatarUploadException].
  Future<String> uploadProfilePhoto(String userId, XFile file) async {
    final Uint8List bytes = await file.readAsBytes();
    final name = file.name;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final mime = avatarMimeTypes[ext];
    if (mime == null) {
      throw const AvatarUploadException(AvatarUploadError.unsupportedFormat);
    }
    if (bytes.isEmpty || bytes.length > maxAvatarBytes) {
      throw const AvatarUploadException(AvatarUploadError.tooLarge);
    }
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(upsert: true, contentType: mime),
        );
    return client.storage.from('avatars').getPublicUrl(path);
  }
}

enum AvatarUploadError { unsupportedFormat, tooLarge }

/// Фото профиля отклонено до загрузки (формат или размер).
class AvatarUploadException implements Exception {
  const AvatarUploadException(this.error);

  final AvatarUploadError error;

  @override
  String toString() => 'AvatarUploadException(${error.name})';
}
