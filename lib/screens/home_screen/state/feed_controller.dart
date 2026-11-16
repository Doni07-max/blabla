import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:android_dev/core/db/app_database.dart';
import '../services/local_data_service.dart';
import '../models/post_model.dart';

extension CachedPostMapper on CachedPost {
  PostModel toModel() => PostModel(
        id: id,
        imageUrl: imageUrl,
        description: caption,
        authorId: authorId,
        authorName: authorName,
        likeCount: likes,
        isLiked: isLiked,
      );
}

final feedPostsProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.watch(localDataServiceProvider).watchPosts().map(
        (posts) => posts.map((post) => post.toModel()).toList(),
      );
});

class FeedController {
  FeedController(this._localData);

  final LocalDataService _localData;

  Future<void> toggleLike(String id) async {
    final post = await _localData.getPost(id);
    if (post != null) await _localData.toggleLike(post);
  }

  Future<void> createPost({required String imageUrl, required String caption}) {
    final now = DateTime.now().microsecondsSinceEpoch;
    return _localData.savePost(
      CachedPostsCompanion.insert(
        id: 'post-$now',
        authorId: 'me',
        authorName: 'alimhan',
        imageUrl: imageUrl,
        caption: caption,
      ),
    );
  }
}

final feedControllerProvider = Provider<FeedController>(
  (ref) => FeedController(ref.watch(localDataServiceProvider)),
);
