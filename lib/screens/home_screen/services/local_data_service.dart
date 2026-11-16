import 'package:android_dev/core/db/app_database.dart';
import 'package:android_dev/core/db/database_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local persistence API for posts and profiles. Kept independent of widgets.
class LocalDataService {
  LocalDataService(this._database);

  final AppDatabase _database;

  Stream<List<CachedPost>> watchPosts() {
    final query = _database.select(_database.cachedPosts)
      // IDs include the creation timestamp, so this keeps newest local posts first.
      ..orderBy([(post) => OrderingTerm.desc(post.id)]);
    return query.watch();
  }

  Future<List<CachedPost>> getPosts() => _database.select(_database.cachedPosts).get();

  Future<CachedPost?> getPost(String id) =>
      (_database.select(_database.cachedPosts)..where((post) => post.id.equals(id))).getSingleOrNull();

  Future<void> savePost(CachedPostsCompanion post) =>
      _database.into(_database.cachedPosts).insertOnConflictUpdate(post);

  Future<void> savePosts(List<CachedPostsCompanion> posts) async {
    await _database.batch((batch) => batch.insertAllOnConflictUpdate(_database.cachedPosts, posts));
  }

  Future<void> deletePost(String id) =>
      (_database.delete(_database.cachedPosts)..where((post) => post.id.equals(id))).go();

  Future<void> toggleLike(CachedPost post) {
    final isLiked = !post.isLiked;
    return (_database.update(_database.cachedPosts)..where((row) => row.id.equals(post.id))).write(
      CachedPostsCompanion(
        isLiked: Value(isLiked),
        likes: Value(post.likes + (isLiked ? 1 : -1)),
      ),
    );
  }

  Stream<List<UserProfile>> watchProfiles() => _database.select(_database.userProfiles).watch();

  Future<UserProfile?> getProfile(String id) =>
      (_database.select(_database.userProfiles)..where((profile) => profile.id.equals(id))).getSingleOrNull();

  Future<void> saveProfile(UserProfilesCompanion profile) =>
      _database.into(_database.userProfiles).insertOnConflictUpdate(profile);
}

final localDataServiceProvider = Provider<LocalDataService>(
  (ref) => LocalDataService(ref.watch(databaseProvider)),
);
