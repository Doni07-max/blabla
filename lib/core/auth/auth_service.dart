import 'dart:convert';
import 'dart:math';

import 'package:android_dev/core/db/app_database.dart';
import 'package:android_dev/core/db/database_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Local (on-device) accounts: register, log in, log out.
///
/// The signed-in account is stored in the `sessions` table, so it survives
/// app restarts until the user logs out.
class AuthService {
  AuthService(this._db);

  final AppDatabase _db;

  static const minPasswordLength = 6;
  static const _hashRounds = 10000;
  static final _usernamePattern = RegExp(r'^[a-z0-9._]{3,30}$');

  /// Emits the signed-in user, or null when logged out.
  /// Also re-emits when that user's profile is edited.
  Stream<User?> watchCurrentUser() {
    final query = _db.select(_db.sessions).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.sessions.userId)),
    ])
      ..limit(1);
    return query
        .watchSingleOrNull()
        .map((row) => row?.readTable(_db.users));
  }

  static String normalizeUsername(String username) =>
      username.trim().toLowerCase();

  /// Returns an error message, or null when [username] is acceptable.
  static String? validateUsername(String? username) {
    final value = normalizeUsername(username ?? '');
    if (_usernamePattern.hasMatch(value)) return null;
    return '3–30 characters: letters, digits, "." or "_".';
  }

  static String? validatePassword(String? password) =>
      (password ?? '').length >= minPasswordLength
          ? null
          : 'At least $minPasswordLength characters.';

  Future<User> register({
    required String username,
    required String displayName,
    required String password,
  }) async {
    final name = normalizeUsername(username);
    final usernameError = validateUsername(name);
    if (usernameError != null) throw AuthException(usernameError);
    final passwordError = validatePassword(password);
    if (passwordError != null) throw AuthException(passwordError);
    final shownName = displayName.trim().isEmpty ? name : displayName.trim();

    return _db.transaction(() async {
      if (await _findByUsername(name) != null) {
        throw const AuthException('This username is already taken.');
      }
      final salt = _newSalt();
      final user = await _db.into(_db.users).insertReturning(
            UsersCompanion.insert(
              username: name,
              displayName: shownName,
              passwordHash: _hash(password, salt),
              passwordSalt: salt,
            ),
          );
      await _startSession(user.id);
      return user;
    });
  }

  Future<User> login({required String username, required String password}) async {
    final user = await _findByUsername(normalizeUsername(username));
    // Same message for both cases so the form does not reveal which accounts exist.
    if (user == null || !_matches(_hash(password, user.passwordSalt), user.passwordHash)) {
      throw const AuthException('Wrong username or password.');
    }
    await _db.transaction(() => _startSession(user.id));
    return user;
  }

  Future<void> logout() => _db.delete(_db.sessions).go();

  Future<User?> _findByUsername(String username) =>
      (_db.select(_db.users)..where((u) => u.username.equals(username)))
          .getSingleOrNull();

  Future<void> _startSession(int userId) async {
    await _db.delete(_db.sessions).go();
    await _db.into(_db.sessions).insert(SessionsCompanion.insert(userId: Value(userId)));
  }

  static String _newSalt() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  static String _hash(String password, String salt) {
    var digest = sha256.convert(utf8.encode('$salt:$password'));
    for (var i = 1; i < _hashRounds; i++) {
      digest = sha256.convert(digest.bytes);
    }
    return digest.toString();
  }

  /// Constant-time comparison, so timing does not leak how much of a hash matched.
  static bool _matches(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(databaseProvider)),
);

/// The signed-in user (null when logged out).
final currentUserProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).watchCurrentUser(),
);

/// Just the signed-in user's id, so feeds don't reload on profile edits.
final currentUserIdProvider = Provider<int?>(
  (ref) => ref.watch(currentUserProvider).asData?.value?.id,
);
