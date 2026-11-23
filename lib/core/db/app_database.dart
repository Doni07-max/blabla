import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Registered accounts. Passwords are never stored in plain text:
/// only a salted, iterated SHA-256 hash (see AuthService).
@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withLength(min: 3, max: 30).unique()();
  TextColumn get displayName => text().withLength(min: 1, max: 50)();
  TextColumn get passwordHash => text()();
  TextColumn get passwordSalt => text()();
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get bio => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@TableIndex(name: 'posts_author_idx', columns: {#authorId})
@TableIndex(name: 'posts_created_idx', columns: {#createdAt})
class Posts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get authorId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get imageUrl => text()();
  TextColumn get caption => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One row per (post, user) like. The composite primary key makes a double
/// like impossible; the like count is derived with COUNT(*), never stored.
@TableIndex(name: 'post_likes_user_idx', columns: {#userId})
class PostLikes extends Table {
  IntColumn get postId =>
      integer().references(Posts, #id, onDelete: KeyAction.cascade)();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {postId, userId};
}

@TableIndex(name: 'comments_post_idx', columns: {#postId, #createdAt})
class Comments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get postId =>
      integer().references(Posts, #id, onDelete: KeyAction.cascade)();
  IntColumn get authorId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get body => text().withLength(min: 1, max: 1000)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// The signed-in account on this device. Holds at most one row;
/// logging out deletes it.
class Sessions extends Table {
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {userId};
}

@DriftDatabase(tables: [Users, Posts, PostLikes, Comments, Sessions])
class AppDatabase extends _$AppDatabase {
  // shareAcrossIsolates: the UI and the workmanager background isolate use one
  // connection, so writes made by a background task also update the UI's watch() streams.
  AppDatabase([QueryExecutor? executor])
      : super(executor ??
            driftDatabase(
              name: 'social_app',
              native: const DriftNativeOptions(shareAcrossIsolates: true),
            ));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v1 kept posts without real owners (authorId 'me') and comments
            // in an untyped side table, so they cannot be mapped onto accounts.
            await customStatement('DROP TABLE IF EXISTS cached_posts');
            await customStatement('DROP TABLE IF EXISTS user_profiles');
            await customStatement('DROP TABLE IF EXISTS post_comments');
            await m.createAll();
          }
        },
        beforeOpen: (details) async {
          // SQLite ignores REFERENCES / ON DELETE CASCADE unless this is on.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
