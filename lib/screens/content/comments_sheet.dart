import 'package:android_dev/core/auth/auth_service.dart';
import 'package:android_dev/screens/home_screen/state/feed_controller.dart';
import 'package:android_dev/widgets/user_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({super.key, required this.postId});

  final int postId;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await ref.read(feedControllerProvider).addComment(postId: widget.postId, body: body);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider(widget.postId));
    final userId = ref.watch(currentUserIdProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            Expanded(
              child: comments.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Could not load comments: $error')),
                data: (items) => items.isEmpty
                    ? const Center(child: Text('Be the first to comment.'))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final comment = items[index];
                          return ListTile(
                            leading: UserAvatar(
                              name: comment.authorName,
                              imageUrl: comment.authorAvatarUrl,
                              radius: 18,
                            ),
                            title: Text(comment.authorName,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(comment.body),
                            trailing: comment.authorId == userId
                                ? IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: 'Delete comment',
                                    onPressed: () => ref
                                        .read(feedControllerProvider)
                                        .deleteComment(comment.id),
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: 1000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        counterText: '',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _isSending ? null : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
