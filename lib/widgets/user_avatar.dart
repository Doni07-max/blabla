import 'package:material_ui/material_ui.dart';

/// Round avatar: the user's picture, or the first letter of their name.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.imageUrl, this.radius = 20});

  final String name;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundImage: hasImage ? NetworkImage(url) : null,
      child: hasImage
          ? null
          : Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: TextStyle(fontSize: radius * .8),
            ),
    );
  }
}
