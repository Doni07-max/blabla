import 'package:android_dev/core/auth/auth_service.dart';
import 'package:android_dev/screens/auth/auth_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_screen.dart';

void main() => runApp(const ProviderScope(child: MainApp()));

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthGate(),
      );
}

/// Shows the login screen while nobody is signed in, otherwise the app.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return user.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Could not open the database: $error'))),
      // Keyed by user id so tab state starts fresh for each account.
      data: (user) => user == null ? const AuthScreen() : MainScreen(key: ValueKey(user.id)),
    );
  }
}
