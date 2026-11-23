import 'package:android_dev/core/db/app_database.dart';
import 'package:android_dev/core/db/database_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';

/// Local persistence API for posts, likes, comments and profiles.
/// Kept independent of widgets.
class LocalDataService {
  LocalDataService(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------- posts

  /// All posts, newest first, with their author, like/comment counts and
  /// whether [viewerId] liked each one. Re-emits whenever any of the
  /// underlying tables change, so likes and comments update the feed live.
  Stream<List<PostModel>> watchFeed(int viewerId) {
    return _db.customSelect(
      '''
      SELECT p.id, p.author_id, p.image_url, p.caption, p.created_at,
             u.display_name, u.avatar_url,
             (SELECT COUNT(*) FROM post_likes l WHERE l.post_id = p.id) AS like_count,
             (SELECT COUNT(*) FROM comments c WHERE c.post_id = p.id) AS comment_count,
             EXISTS (SELECT 1 FROM post_likes l
                     WHERE l.post_id = p.id AND l.user_id = ?) AS is_liked
      FROM posts p
      JOIN users u ON u.id = p.author_id
      ORDER BY p.created_at DESC, p.id DESC
      ''',
      variables: [Variable.withInt(viewerId)],
      readsFrom: {_db.posts, _db.users, _db.postLikes, _db.comments},
    ).watch().map((rows) => rows
        .map((row) => PostModel(
              id: row.read<int>('id'),
              authorId: row.read<int>('author_id'),
              imageUrl: row.read<String>('image_url'),
              description: row.read<String>('caption'),
              createdAt: row.read<DateTime>('created_at'),
              authorName: row.read<String>('display_name'),
              authorAvatarUrl: row.readNullable<String>('avatar_url'),
              likeCount: row.read<int>('like_count'),
              commentCount: row.read<int>('comment_count'),
              isLiked: row.read<bool>('is_liked'),
            ))
        .toList());
  }

  Future<int> createPost({
    required int authorId,
    required String imageUrl,
    required String caption,
  }) =>
      _db.into(_db.posts).insert(PostsCompanion.insert(
            authorId: authorId,
            imageUrl: imageUrl,
            caption: Value(caption),
          ));

  /// Deletes the post if [userId] owns it. Its likes and comments are
  /// removed by ON DELETE CASCADE.
  Future<void> deletePost({required int postId, required int userId}) =>
      (_db.delete(_db.posts)
            ..where((p) => p.id.equals(postId) & p.authorId.equals(userId)))
          .go();

  // ---------------------------------------------------------------- likes

  Future<void> toggleLike({required int postId, required int userId}) {
    return _db.transaction(() async {
      final removed = await (_db.delete(_db.postLikes)
            ..where((l) => l.postId.equals(postId) & l.userId.equals(userId)))
          .go();
      if (removed == 0) {
        await _db.into(_db.postLikes).insert(
              PostLikesCompanion.insert(postId: postId, userId: userId),
            );
      }
    });
  }

  // ------------------------------------------------------------- comments

  Stream<List<CommentModel>> watchComments(int postId) {
    final query = _db.select(_db.comments).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.comments.authorId)),
    ])
      ..where(_db.comments.postId.equals(postId))
      ..orderBy([
        OrderingTerm.asc(_db.comments.createdAt),
        OrderingTerm.asc(_db.comments.id),
      ]);
    return query.watch().map((rows) => rows.map((row) {
          final comment = row.readTable(_db.comments);
          final author = row.readTable(_db.users);
          return CommentModel(
            id: comment.id,
            postId: comment.postId,
            authorId: author.id,
            authorName: author.displayName,
            authorAvatarUrl: author.avatarUrl,
            body: comment.body,
            createdAt: comment.createdAt,
          );
        }).toList());
  }

  Future<void> addComment({
    required int postId,
    required int authorId,
    required String body,
  }) =>
      _db.into(_db.comments).insert(CommentsCompanion.insert(
            postId: postId,
            authorId: authorId,
            body: body,
          ));

  Future<void> deleteComment({required int commentId, required int userId}) =>
      (_db.delete(_db.comments)
            ..where((c) => c.id.equals(commentId) & c.authorId.equals(userId)))
          .go();

  // ------------------------------------------------------------- profiles

  Future<void> updateProfile({
    required int userId,
    required String displayName,
    String? avatarUrl,
    String bio = '',
  }) =>
      (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
        UsersCompanion(
          displayName: Value(displayName),
          avatarUrl: Value(avatarUrl),
          bio: Value(bio),
        ),
      );
}

final localDataServiceProvider = Provider<LocalDataService>(
  (ref) => LocalDataService(ref.watch(databaseProvider)),
);
