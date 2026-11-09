import 'package:android_dev/screens/home_screen/models/comment_model.dart';

class PostModel {
  final String? username;
  final String? avatarUrl;
  final String? imageUrl;
  int? likeCount;
  int? commentCount;
  final String? description;
  final List<CommentModel> comments; // свои комментарии у каждого поста

  PostModel({
    this.username,
    this.avatarUrl,
    this.imageUrl,
    this.likeCount,
    this.commentCount,
    this.description,
    this.comments = const [],
  });

  void addLike(int newCount) {
    likeCount = newCount;
  }
}
