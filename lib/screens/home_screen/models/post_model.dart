class PostModel {
  const PostModel({
    required this.id,
    required this.imageUrl,
    required this.description,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.authorAvatarUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
  });

  final int id;
  final String imageUrl;
  final String description;
  final int authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;

  /// Whether the signed-in user has liked this post.
  final bool isLiked;
}
