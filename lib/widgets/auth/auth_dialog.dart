import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:travio/services/auth_service.dart';
import 'package:travio/utils/utils.dart';
import 'package:travio/widgets/sonnar.dart';

enum AuthMode { signIn, signUp }

/// Authentication dialog aligned to top-right with Google and email/password options
class AuthDialog extends StatefulWidget {
  const AuthDialog({
    super.key,
    this.initialMode = AuthMode.signIn,
  });

  final AuthMode initialMode;

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  AuthMode _currentMode = AuthMode.signIn;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.signInWithGoogle();
      if (user != null && mounted) {
        logPrint('✅ Google Sign-In successful, closing dialog');
        Navigator.of(context).pop(true);

        // Show success toast
        AppSonnar.of(context).show(
          AppToast(
            title: Text('Welcome!'),
            description: Text('Successfully signed in with Google'),
            variant: AppToastVariant.primary,
          ),
        );
      } else if (mounted) {
        logPrint(
            'ℹ️ Google Sign-In returned null - user may have cancelled or configuration incomplete');
      }
    } catch (e) {
      logPrint('❌ Google Sign-In error: $e');
      if (mounted) {
        AppSonnar.of(context).show(
          AppToast(
            title: Text('Sign-In Failed'),
            description: Text('Error signing in with Google: ${e.toString()}'),
            variant: AppToastVariant.destructive,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;
      final displayName = _nameController.text.trim();

      if (_currentMode == AuthMode.signUp && password != confirmPassword) {
        AppSonnar.of(context).show(
          AppToast(
            title: Text('Password mismatch'),
            description: Text('Please enter the same password'),
            variant: AppToastVariant.destructive,
          ),
        );
        return;
      }

      final user = _currentMode == AuthMode.signIn
          ? await AuthService.signInWithEmailPassword(
              email: email, password: password)
          : await AuthService.signUpWithEmailPassword(
              email: email,
              password: password,
              displayName: displayName.isEmpty ? null : displayName,
            );

      if (user != null && mounted) {
        logPrint('✅ Email auth successful, closing dialog');
        Navigator.of(context).pop(true);

        // Show success toast
        AppSonnar.of(context).show(
          AppToast(
            title: Text(
                _currentMode == AuthMode.signIn ? 'Welcome back!' : 'Welcome!'),
            description: Text(_currentMode == AuthMode.signIn
                ? 'Successfully signed in'
                : 'Account created successfully'),
            variant: AppToastVariant.primary,
          ),
        );
      }
    } catch (e) {
      logPrint('❌ Email auth error: $e');
      if (mounted) {
        String errorMessage = 'Authentication failed';

        // Handle common Firebase Auth errors
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'No account found with this email';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'Incorrect password';
        } else if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'An account already exists with this email';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'Password should be at least 6 characters';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Please enter a valid email address';
        }

        AppSonnar.of(context).show(
          AppToast(
            title: Text('Authentication Failed'),
            description: Text(errorMessage),
            variant: AppToastVariant.destructive,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _switchMode() {
    setState(() {
      _currentMode =
          _currentMode == AuthMode.signIn ? AuthMode.signUp : AuthMode.signIn;
      // Clear form when switching modes
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topRight,
      insetPadding: const EdgeInsets.only(top: 80, right: 20),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Text(
                    _currentMode == AuthMode.signIn
                        ? 'Sign In'
                        : 'Create Account',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Google Sign-In Button
                    InkWell(
                      onTap: _isLoading ? null : _handleGoogleSignIn,
                      borderRadius: BorderRadius.circular(50),
                      child: Opacity(
                        opacity: _isLoading ? 0.5 : 1,
                        child: Image.asset(
                          _currentMode == AuthMode.signIn
                              ? 'assets/images/google_sign_in${Theme.of(context).brightness == Brightness.dark ? '_dark' : ''}.png'
                              : 'assets/images/google_sign_up${Theme.of(context).brightness == Brightness.dark ? '_dark' : ''}.png',
                          height: 46,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider with "OR"
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Email/Password Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Name field (only for sign up)
                          if (_currentMode == AuthMode.signUp) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name (Optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon:
                                    const Icon(Icons.person_outline_rounded),
                                prefixIconColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              style: Theme.of(context).textTheme.bodyMedium,
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon:
                                  const Icon(Icons.alternate_email_rounded),
                              prefixIconColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),

                          const SizedBox(height: 12),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (_currentMode == AuthMode.signUp &&
                                  value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              prefixIconColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),

                          // Confirm password field (only for sign up)
                          if (_currentMode == AuthMode.signUp) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (_currentMode == AuthMode.signUp &&
                                    value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                prefixIconColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleEmailAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    )
                                  : Text(
                                      _currentMode == AuthMode.signIn
                                          ? 'Sign In'
                                          : 'Create Account',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Forgot password (only for sign in)
                          if (_currentMode == AuthMode.signIn)
                            TextButton(
                              onPressed:
                                  _isLoading ? null : _showForgotPasswordDialog,
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentMode == AuthMode.signIn
                        ? "Don't have an account?"
                        : "Already have an account?",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isLoading ? null : _switchMode,
                    child: Text(
                      _currentMode == AuthMode.signIn ? 'Sign Up' : 'Sign In',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter your email address to receive a password reset link.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                final success = await AuthService.resetPassword(email);
                Navigator.of(context).pop(success);
              }
            },
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      AppSonnar.of(context).show(
        AppToast(
          title: Text('Reset Email Sent'),
          description: Text('Check your email for password reset instructions'),
          variant: AppToastVariant.primary,
        ),
      );
    }

    emailController.dispose();
  }
}
