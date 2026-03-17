import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/profile_model.dart';

/// Repository for profile CRUD operations against the Supabase `profiles`
/// table and `avatars` storage bucket.
///
/// Accepts an optional [SupabaseClient] for dependency injection in tests.
class ProfileRepository {
  ProfileRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetches the profile for the given [userId].
  ///
  /// Throws if the profile does not exist.
  Future<Profile> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return Profile.fromJson(data);
  }

  /// Updates the given [profile] in the database.
  ///
  /// Uses the profile's `id` to match the row and applies `toJson()` values.
  Future<void> updateProfile(Profile profile) async {
    await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id);
  }

  /// Uploads an avatar [file] for the given [userId] and returns the public URL.
  ///
  /// The file is stored at `{userId}/avatar.{ext}` in the `avatars` bucket,
  /// with `upsert: true` so subsequent uploads overwrite the previous avatar.
  Future<String> uploadAvatar(String userId, File file) async {
    final fileExt = file.path.split('.').last;
    final filePath = '$userId/avatar.$fileExt';

    await _client.storage
        .from('avatars')
        .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

    return _client.storage.from('avatars').getPublicUrl(filePath);
  }
}
