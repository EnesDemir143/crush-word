import 'package:crush_word/src/core/models/app_user.dart';
import 'package:crush_word/src/core/storage/local_storage_service.dart';

class ProfileRepository {
  ProfileRepository({LocalStorageService? storage})
    : _storage = storage ?? SharedPreferencesLocalStorageService();

  static const String _usernameKey = 'profile.username';

  final LocalStorageService _storage;

  Future<AppUser?> loadUser() async {
    final String? username = await _storage.readString(_usernameKey);
    final String normalizedUsername = username?.trim() ?? '';

    if (normalizedUsername.isEmpty) {
      return null;
    }

    return AppUser(username: normalizedUsername);
  }

  Future<AppUser> saveUsername(String username) async {
    final String normalizedUsername = username.trim();

    if (normalizedUsername.isEmpty) {
      throw ArgumentError.value(
        username,
        'username',
        'Username cannot be empty.',
      );
    }

    await _storage.writeString(_usernameKey, normalizedUsername);
    return AppUser(username: normalizedUsername);
  }

  Future<void> clearUser() async {
    await _storage.remove(_usernameKey);
  }
}
