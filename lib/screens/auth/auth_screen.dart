import 'package:android_dev/core/auth/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Log in or create an account. Shown by AuthGate while nobody is signed in;
/// on success the gate switches to the main screen by itself.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _isRegister = false;
  bool _isBusy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toggleMode() => setState(() {
        _isRegister = !_isRegister;
        _error = null;
        _formKey.currentState?.reset();
      });

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider);
    try {
      if (_isRegister) {
        await auth.register(
          username: _username.text,
          displayName: _displayName.text,
          password: _password.text,
        );
      } else {
        await auth.login(username: _username.text, password: _password.text);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Instagram',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRegister ? 'Create an account' : 'Log in to your account',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _username,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          autofillHints: [
                            _isRegister ? AutofillHints.newUsername : AutofillHints.username,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                          validator: _isRegister
                              ? AuthService.validateUsername
                              : (v) => (v ?? '').trim().isEmpty ? 'Enter your username.' : null,
                        ),
                        if (_isRegister) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _displayName,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            maxLength: 50,
                            decoration: const InputDecoration(
                              labelText: 'Name (optional)',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          textInputAction:
                              _isRegister ? TextInputAction.next : TextInputAction.done,
                          autofillHints: [
                            _isRegister ? AutofillHints.newPassword : AutofillHints.password,
                          ],
                          onFieldSubmitted: _isRegister ? null : (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: _isRegister
                              ? AuthService.validatePassword
                              : (v) => (v ?? '').isEmpty ? 'Enter your password.' : null,
                        ),
                        if (_isRegister) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirm,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: const InputDecoration(
                              labelText: 'Repeat password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (v) =>
                                v == _password.text ? null : 'Passwords do not match.',
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red)),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _isBusy ? null : _submit,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: _isBusy
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(_isRegister ? 'Sign up' : 'Log in'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _isBusy ? null : _toggleMode,
                          child: Text(_isRegister
                              ? 'Already have an account? Log in'
                              : "Don't have an account? Sign up"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
