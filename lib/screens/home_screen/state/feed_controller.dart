import 'package:android_dev/core/auth/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/comment_model.dart';
import '../models/post_model.dart';
import '../services/local_data_service.dart';

/// The feed as seen by the signed-in user (empty when logged out).
final feedPostsProvider = StreamProvider<List<PostModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(localDataServiceProvider).watchFeed(userId);
});

final commentsProvider =
    StreamProvider.autoDispose.family<List<CommentModel>, int>(
  (ref, postId) => ref.watch(localDataServiceProvider).watchComments(postId),
);

/// Write actions on posts, always performed as the signed-in user.
class FeedController {
  FeedController(this._ref);

  final Ref _ref;

  LocalDataService get _localData => _ref.read(localDataServiceProvider);

  int get _userId {
    final id = _ref.read(currentUserIdProvider);
    if (id == null) throw const AuthException('You need to log in first.');
    return id;
  }

  Future<void> toggleLike(int postId) =>
      _localData.toggleLike(postId: postId, userId: _userId);

  Future<void> createPost({required String imageUrl, required String caption}) =>
      _localData.createPost(authorId: _userId, imageUrl: imageUrl, caption: caption);

  Future<void> deletePost(int postId) =>
      _localData.deletePost(postId: postId, userId: _userId);

  Future<void> addComment({required int postId, required String body}) =>
      _localData.addComment(postId: postId, authorId: _userId, body: body);

  Future<void> deleteComment(int commentId) =>
      _localData.deleteComment(commentId: commentId, userId: _userId);
}

final feedControllerProvider = Provider<FeedController>(FeedController.new);
