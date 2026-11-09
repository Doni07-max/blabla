import "package:android_dev/screens/content/comment_widget.dart";
import "package:android_dev/screens/home_screen/models/post_model.dart";
import "package:flutter/material.dart";

class PostWidget extends StatefulWidget {
  final PostModel? post;
  const PostWidget({super.key, required this.post});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  bool isLiked = false;

  // Открывает снизу список комментариев этого поста
  void openComments() {
    final comments = widget.post?.comments ?? [];
    showModalBottomSheet(
      context: context,
      builder: (context) {
        if (comments.isEmpty) {
          return const Center(child: Text('Пока нет комментариев'));
        }
        return ListView.builder(
          itemCount: comments.length,
          itemBuilder: (context, index) {
            return CommentWidget(comment: comments[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Аватар и имя автора
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.post?.avatarUrl ?? ''),
              ),
              const SizedBox(width: 10),
              Text(
                widget.post?.username ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Картинка поста
          Image.network(
            widget.post?.imageUrl ?? '',
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          // Кнопки лайк и комментарии
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : null,
                ),
                onPressed: () {
                  setState(() {
                    if (isLiked) {
                      widget.post?.addLike((widget.post?.likeCount ?? 1) - 1);
                    } else {
                      widget.post?.addLike((widget.post?.likeCount ?? 0) + 1);
                    }
                    isLiked = !isLiked;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.comment),
                onPressed: openComments,
              ),
            ],
          ),
          Text(
            'Нравится: ${widget.post?.likeCount ?? 0}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(widget.post?.description ?? ''),
          TextButton(
            onPressed: openComments,
            child: Text(
              'Комментарии (${widget.post?.comments.length ?? 0})',
            ),
          ),
        ],
      ),
    );
  }
}
