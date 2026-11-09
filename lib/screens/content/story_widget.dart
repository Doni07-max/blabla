import 'package:android_dev/screens/home_screen/models/story_model.dart';
import 'package:flutter/material.dart';

class StoryWidget extends StatelessWidget {
  final StoryModel story;
  const StoryWidget({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(story.avatarUrl),
          ),
          Text(story.username, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
