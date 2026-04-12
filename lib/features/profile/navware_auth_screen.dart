import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/nav/navware_auth_service.dart';

class NavwareAuthScreen extends StatefulWidget {
  const NavwareAuthScreen({super.key});

  @override
  State<NavwareAuthScreen> createState() => _NavwareAuthScreenState();
}

class _NavwareAuthScreenState extends State<NavwareAuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Navware Account'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Sign in'), Tab(text: 'Create account')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AuthForm(
            key: const ValueKey('login'),
            mode: _AuthMode.login,
            onSuccess: (user) => _onSuccess(user),
          ),
          _AuthForm(
            key: const ValueKey('register'),
            mode: _AuthMode.register,
            onSuccess: (user) => _onSuccess(user),
          ),
        ],
      ),
    );
  }

  void _onSuccess(NavwareUser user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Signed in as ${user.email}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
    context.pop(user);
  }
}

enum _AuthMode { login, register }

class _AuthForm extends StatefulWidget {
  const _AuthForm({super.key, required this.mode, required this.onSuccess});

  final _AuthMode mode;
  final void Function(NavwareUser) onSuccess;

  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Passkey flow ─────────────────────────────────────────────────────────────

  Future<void> _submitPasskey() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter your email first');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final NavwareUser user;
      if (widget.mode == _AuthMode.login) {
        user = await NavwareAuthService.loginWithPasskey(email);
      } else {
        user = await NavwareAuthService.registerWithPasskey(email);
      }
      if (mounted) widget.onSuccess(user);
    } on NavwareAuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not reach Navware server. '
            'Check your connection or server URL in Developer Settings.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Password flow ─────────────────────────────────────────────────────────────

  Future<void> _submitPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      final NavwareUser user;
      if (widget.mode == _AuthMode.login) {
        user = await NavwareAuthService.login(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        user = await NavwareAuthService.register(
          _emailController.text,
          _passwordController.text,
        );
      }
      if (mounted) widget.onSuccess(user);
    } on NavwareAuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not reach Navware server. '
            'Check your connection or server URL in Developer Settings.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLogin = widget.mode == _AuthMode.login;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // ── Email field (shared by both passkey and password flows) ─────────
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Passkey button ──────────────────────────────────────────────────
            FilledButton.icon(
              onPressed: _loading ? null : _submitPasskey,
              icon: _loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fingerprint),
              label: Text(isLogin ? 'Sign in with passkey' : 'Create passkey'),
            ),

            // ── Error display ───────────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Divider ─────────────────────────────────────────────────────────
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or use password',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            // ── Password field ──────────────────────────────────────────────────
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submitPassword(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (!isLogin && v.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _loading ? null : _submitPassword,
              child: Text(isLogin ? 'Sign in with password' : 'Create account'),
            ),
          ],
        ),
      ),
    );
  }
}
