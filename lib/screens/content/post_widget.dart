import "package:android_dev/screens/content/comment_widget.dart";
import "package:android_dev/screens/home_screen/models/comment_model.dart";
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
  final TextEditingController commentController = TextEditingController();

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  void openBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final comments = widget.post?.comments ?? [];
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Комментарии',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: comments.isEmpty
                          ? const Center(child: Text('Пока нет комментариев'))
                          : ListView.builder(
                              itemCount: comments.length,
                              itemBuilder: (context, index) {
                                return CommentWidget(comment: comments[index]);
                              },
                            ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              decoration: const InputDecoration(
                                hintText: 'Добавьте комментарий...',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () {
                              if (commentController.text.trim().isEmpty) {
                                return;
                              }
                              widget.post?.addComment(
                                CommentModel(
                                  username: 'me',
                                  avatarUrl: 'https://i.pravatar.cc/150?img=68',
                                  text: commentController.text.trim(),
                                ),
                              );
                              commentController.clear();
                              setSheetState(() {});
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
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
          Padding(
            padding: const EdgeInsets.only(left: 5, bottom: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(
                    widget.post?.avatarUrl ?? 'https://i.pravatar.cc/150',
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.post?.username ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              widget.post?.imageUrl ?? 'https://picsum.photos/600/400',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
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
                onPressed: () {
                  openBottomSheet();
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {},
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Нравится: ${widget.post?.likeCount ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.post?.description ?? '',
                  style: const TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: openBottomSheet,
                  child: Text(
                    'Посмотреть все комментарии (${widget.post?.comments.length ?? 0})',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
