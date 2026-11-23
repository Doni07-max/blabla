import 'package:android_dev/screens/home_screen/models/post_model.dart';
import 'package:android_dev/screens/content/comments_sheet.dart';
import 'package:android_dev/widgets/user_avatar.dart';
import 'package:material_ui/material_ui.dart';

class PostWidget extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;

  /// Shown as a menu entry when set (only for the author's own posts).
  final VoidCallback? onDelete;

  const PostWidget({super.key, required this.post, required this.onLike, this.onDelete});

  void openBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => CommentsSheet(postId: post.id),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Colors.grey, spreadRadius: 2, blurRadius: 5, offset: Offset(0, 3))],
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                UserAvatar(name: post.authorName, imageUrl: post.authorAvatarUrl, radius: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (onDelete != null)
                  PopupMenuButton<void>(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      PopupMenuItem(onTap: onDelete, child: const Text('Delete post')),
                    ],
                  ),
              ]),
            ),
            GestureDetector(
              onDoubleTap: post.isLiked ? null : onLike,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(post.imageUrl, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
            Row(children: [
              IconButton(
                icon: Icon(post.isLiked ? Icons.favorite : Icons.favorite_border),
                color: post.isLiked ? Colors.red : null,
                onPressed: onLike,
              ),
              Text('${post.likeCount}'),
              IconButton(icon: const Icon(Icons.comment), onPressed: () => openBottomSheet(context)),
              Text('${post.commentCount}'),
              IconButton(icon: const Icon(Icons.share), onPressed: () {}),
              const Spacer(),
              IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
            ]),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(post.description)),
          ],
        ),
      );
}
