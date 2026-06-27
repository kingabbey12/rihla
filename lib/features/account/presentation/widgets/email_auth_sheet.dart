import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rihla/features/account/presentation/providers/account_providers.dart';
import 'package:rihla/shared/widgets/premium_buttons.dart';

enum EmailAuthMode { signIn, signUp, reset }

/// Email/password authentication sheet.
class EmailAuthSheet extends ConsumerStatefulWidget {
  const EmailAuthSheet({
    super.key,
    this.mode = EmailAuthMode.signIn,
    this.onSuccess,
  });

  final EmailAuthMode mode;
  final VoidCallback? onSuccess;

  @override
  ConsumerState<EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends ConsumerState<EmailAuthSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  late EmailAuthMode _mode;
  bool _loading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    final controller = ref.read(accountControllerProvider.notifier);
    try {
      switch (_mode) {
        case EmailAuthMode.signIn:
          await controller.signInWithEmail(email, password);
        case EmailAuthMode.signUp:
          await controller.signUpWithEmail(
            email,
            password,
            displayName: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
          );
        case EmailAuthMode.reset:
          await controller.resetPassword(email);
          setState(() => _message = 'Password reset email sent');
      }
      if (mounted && _mode != EmailAuthMode.reset) {
        widget.onSuccess?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            switch (_mode) {
              EmailAuthMode.signIn => 'Sign in with email',
              EmailAuthMode.signUp => 'Create account',
              EmailAuthMode.reset => 'Reset password',
            },
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (_mode == EmailAuthMode.signUp)
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          if (_mode != EmailAuthMode.reset) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(_message!, style: TextStyle(color: Colors.orange.shade800)),
          ],
          const SizedBox(height: 16),
          PremiumPrimaryButton(
            label: _loading ? 'Please wait…' : 'Continue',
            onPressed: _loading ? () {} : _submit,
          ),
          if (_mode == EmailAuthMode.signIn) ...[
            TextButton(
              onPressed: () => setState(() => _mode = EmailAuthMode.signUp),
              child: const Text('Create account'),
            ),
            TextButton(
              onPressed: () => setState(() => _mode = EmailAuthMode.reset),
              child: const Text('Forgot password?'),
            ),
          ],
        ],
      ),
    );
  }
}
