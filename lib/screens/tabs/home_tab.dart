import "package:android_dev/screens/content/post_widget.dart";
import "package:android_dev/screens/content/stories_list.dart";
import "package:android_dev/screens/home_screen/data/posts_data.dart";
import "package:android_dev/screens/home_screen/services/post_services.dart";
import "package:flutter/material.dart";

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final PostServices postServices = PostServices();

  @override
  void initState() {
    super.initState();
    postServices.batchAddPosts(postsData);
    postServices.batchAddStories(storiesData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Instagram'),
      ),
      body: ListView.builder(
        itemCount: postServices.posts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return StoriesList(stories: postServices.stories);
          }
          return Padding(
            padding: const EdgeInsets.all(4.0),
            child: PostWidget(post: postServices.posts[index - 1]),
          );
        },
      ),
    );
  }
}
