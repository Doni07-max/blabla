class CommentModel {
  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    this.authorAvatarUrl,
  });

  final int id;
  final int postId;
  final int authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String body;
  final DateTime createdAt;
}
