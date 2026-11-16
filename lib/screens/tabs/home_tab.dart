import 'package:android_dev/screens/content/post_widget.dart';
import 'package:android_dev/screens/home_screen/state/feed_controller.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(feedPostsProvider);
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text('Instagram')),
      body: posts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load posts: $error')),
        data: (items) => items.isEmpty
            ? const Center(child: Text('No posts yet. Create your first post.'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(4),
                  child: PostWidget(
                    post: items[index],
                    onLike: () => ref.read(feedControllerProvider).toggleLike(items[index].id),
                  ),
                ),
              ),
      ),
    );
  }
}
