import 'package:android_dev/screens/content/story_widget.dart';
import 'package:android_dev/screens/home_screen/models/story_model.dart';
import 'package:flutter/material.dart';

class StoriesList extends StatelessWidget {
  final List<StoryModel> stories;
  const StoriesList({super.key, required this.stories});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        itemBuilder: (context, index) {
          return StoryWidget(story: stories[index]);
        },
      ),
    );
  }
}
