import 'package:android_dev/core/auth/auth_service.dart';
import 'package:android_dev/core/db/app_database.dart';
import 'package:android_dev/screens/home_screen/services/local_data_service.dart';
import 'package:android_dev/screens/home_screen/state/feed_controller.dart';
import 'package:android_dev/widgets/user_avatar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    if (user == null) return const Scaffold(body: SizedBox.shrink());
    final posts = ref.watch(feedPostsProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('@${user.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profile',
            onPressed: () => _showEditProfile(context, ref, user),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      body: posts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load profile: $error')),
        data: (allPosts) {
          final ownPosts = allPosts.where((post) => post.authorId == user.id).toList();
          final likesReceived = ownPosts.fold<int>(0, (sum, post) => sum + post.likeCount);
          return CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  UserAvatar(name: user.displayName, imageUrl: user.avatarUrl, radius: 42),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text('${ownPosts.length} posts · $likesReceived likes'),
                        if (user.bio.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(user.bio),
                        ],
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text('Posts', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            SliverGrid.builder(
              itemCount: ownPosts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemBuilder: (context, index) => Image.network(
                ownPosts[index].imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ]);
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) await ref.read(authServiceProvider).logout();
  }

  Future<void> _showEditProfile(BuildContext context, WidgetRef ref, User user) async {
    final nameController = TextEditingController(text: user.displayName);
    final imageController = TextEditingController(text: user.avatarUrl ?? '');
    final bioController = TextEditingController(text: user.bio);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                maxLength: 50,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: imageController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Profile picture URL'),
              ),
              TextField(
                controller: bioController,
                maxLines: 3,
                maxLength: 150,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final image = imageController.text.trim();
              await ref.read(localDataServiceProvider).updateProfile(
                    userId: user.id,
                    displayName: name,
                    avatarUrl: image.isEmpty ? null : image,
                    bio: bioController.text.trim(),
                  );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameController.dispose();
    imageController.dispose();
    bioController.dispose();
  }
}
