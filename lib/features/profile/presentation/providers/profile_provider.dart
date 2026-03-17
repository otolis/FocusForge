import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/profile_repository.dart';
import '../../domain/profile_model.dart';

/// Provides the [ProfileRepository] instance.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);

/// Provides the user's [Profile] as an async value, keyed by userId.
///
/// Usage: `ref.watch(profileProvider(userId))` returns an `AsyncValue<Profile>`
/// that handles loading, data, and error states automatically.
final profileProvider = FutureProvider.family<Profile, String>(
  (ref, userId) async {
    final repo = ref.read(profileRepositoryProvider);
    return repo.getProfile(userId);
  },
);
