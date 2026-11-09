import 'package:android_dev/screens/home_screen/models/comment_model.dart';

class PostModel {
  final String? username;
  final String? avatarUrl;
  final String? imageUrl;
  int? likeCount;
  int? commentCount;
  final String? description;
  final List<CommentModel> comments;

  PostModel({
    this.username,
    this.avatarUrl,
    this.imageUrl,
    this.likeCount,
    this.commentCount,
    this.description,
    List<CommentModel>? comments,
  }) : comments = comments ?? [];

  void addLike(int newCount) {
    likeCount = newCount;
  }

  void addComment(CommentModel comment) {
    comments.add(comment);
    commentCount = comments.length;
  }
}
