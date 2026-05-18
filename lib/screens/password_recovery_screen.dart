import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quickfix/services/supabase_service.dart';
import 'package:quickfix/theme/app_theme.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  final String? token;

  const PasswordRecoveryScreen({super.key, this.token});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isRestoringSession = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _restoreRecoverySession();
  }

  void _restoreRecoverySession() async {
    if (SupabaseService.currentUser != null) return;
    final uri = Uri.base;
    final fragment = uri.fragment;
    final normalizedFragment = fragment.startsWith('/') ? fragment : '/$fragment';
    final hasRecoveryToken = fragment.contains('type=recovery') ||
        uri.queryParameters['type'] == 'recovery' ||
        normalizedFragment.contains('/password-recovery') ||
        uri.path == '/password-recovery';
    if (!hasRecoveryToken) return;

    setState(() {
      _isRestoringSession = true;
      _errorMessage = null;
    });

    try {
      await SupabaseService.recoverSessionFromUrl(uri);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Could not restore your reset link session. Please request a new password reset email.';
        });
      }
      debugPrint('[PasswordRecovery] Recovery restoration error: $e');
    } finally {
      if (mounted) {
        setState(() => _isRestoringSession = false);
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    setState(() => _errorMessage = null);
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() =>
            _errorMessage = 'Passwords do not match. Please try again.');
        return;
      }

      setState(() => _isLoading = true);
      try {
        if (SupabaseService.currentUser == null) {
          debugPrint(
              '[PasswordRecovery] No current user; retrying recovery session from URL.');
          try {
            await SupabaseService.recoverSessionFromUrl(Uri.base);
          } catch (recoverError) {
            debugPrint(
                '[PasswordRecovery] Retry recovery session failed: $recoverError');
          }
        }

        if (SupabaseService.currentUser == null) {
          setState(() {
            _errorMessage =
                'No active reset session was found. Please use the reset link from your email again.';
          });
          return;
        }

        debugPrint('[PasswordRecovery] Attempting password reset...');
        await SupabaseService.updatePassword(_passwordController.text);
        debugPrint('[PasswordRecovery] Password reset successful');
        if (mounted) {
          setState(() => _isSuccess = true);
        }
      } on AuthException catch (e) {
        debugPrint('[PasswordRecovery] AuthException: ${e.message}');
        if (mounted) setState(() => _errorMessage = e.message);
      } catch (e) {
        debugPrint('[PasswordRecovery] Exception: $e');
        if (mounted) setState(() => _errorMessage = e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Logo
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_open,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Create a new password for your account',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              if (_isRestoringSession) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 24),
                const Text(
                  'Restoring your reset session. Please wait...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
              ] else if (_isSuccess) ...[
                // Success state
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 32,
                          color: AppTheme.success,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Password Reset Successful',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your password has been updated. You can now log in with your new password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text(
                            'Back to Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Form state
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // New Password
                      const Text(
                        'New Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onChanged: (_) => setState(() => _errorMessage = null),
                        decoration: InputDecoration(
                          hintText: 'Enter your new password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Confirm Password
                      const Text(
                        'Confirm Password',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        onChanged: (_) => setState(() => _errorMessage = null),
                        decoration: InputDecoration(
                          hintText: 'Confirm your new password',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Error message
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.error.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppTheme.error, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.error,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _errorMessage = null),
                                child: const Icon(Icons.close,
                                    color: AppTheme.error, size: 18),
                              ),
                            ],
                          ),
                        ),

                      // Reset button
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _resetPassword,
                                child: const Text(
                                  'Reset Password',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text(
                            'Back to Login',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
