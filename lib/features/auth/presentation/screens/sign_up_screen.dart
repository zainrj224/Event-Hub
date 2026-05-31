import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return e.message ?? 'Sign up failed (${e.code})';
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      setState(
          () => _errorMessage = 'Please agree to the Terms & Privacy Policy.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      try {
        await cred.user?.updateDisplayName(_nameController.text.trim());
      } catch (_) {}
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = _friendlyError(e));
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Sign up failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Google sign-in failed.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF0F0F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Back arrow ───────────────────────────────────────────
                GestureDetector(
                  onTap: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: Icon(
                    Icons.arrow_back,
                    color: isDark ? AppColors.darkText : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Heading ──────────────────────────────────────────────
                Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? AppColors.darkText : AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Provide your full name, email, and password to\ncreate your account and get started.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Google button ────────────────────────────────────────
                SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _isGoogleLoading ? null : _signUpWithGoogle,
                    style: OutlinedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.darkSurface : Colors.white,
                      side: BorderSide(
                        color: isDark
                            ? AppColors.darkOutline
                            : const Color(0xFFE5E5E5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isGoogleLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Replace with SvgPicture.asset later
                              const Icon(Icons.g_mobiledata,
                                  size: 26, color: Color(0xFF4285F4)),
                              const SizedBox(width: 10),
                              Text(
                                'Google',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkText
                                      : AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Divider ──────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                        child: Divider(
                            color: isDark ? Colors.white12 : Colors.black12)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'or',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.outline,
                        ),
                      ),
                    ),
                    Expanded(
                        child: Divider(
                            color: isDark ? Colors.white12 : Colors.black12)),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Full Name ────────────────────────────────────────────
                _fieldLabel('Full Name', isDark),
                const SizedBox(height: 8),
                _buildField(
                  controller: _nameController,
                  isDark: isDark,
                  hint: 'Ethan Miller',
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your name';
                    if (v.trim().length < 2) return 'Name is too short';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Email ────────────────────────────────────────────────
                _fieldLabel('Email Address', isDark),
                const SizedBox(height: 8),
                _buildField(
                  controller: _emailController,
                  isDark: isDark,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Enter your email';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Password ─────────────────────────────────────────────
                _fieldLabel('Password', isDark),
                const SizedBox(height: 8),
                _buildField(
                  controller: _passwordController,
                  isDark: isDark,
                  hint: '••••••••••••',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signUp(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.outline,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (v.length < 6)
                      return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ── Terms toggle ─────────────────────────────────────────
                GestureDetector(
                  onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46,
                        height: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          color: _agreedToTerms
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.darkOutline
                                  : const Color(0xFFDDDDDD)),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: _agreedToTerms
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.onSurfaceVariant,
                            ),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkText
                                      : AppColors.onSurface,
                                ),
                              ),
                              const TextSpan(text: ' & '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkText
                                      : AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Error banner ─────────────────────────────────────────
                if (_errorMessage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade700, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Sign Up button ───────────────────────────────────────
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.lime : AppColors.primary,
                      foregroundColor:
                          isDark ? AppColors.primary : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: isDark ? AppColors.primary : Colors.white,
                            ),
                          )
                        : Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.primary : Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Sign in link ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    GestureDetector(
                      onTap:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.lime : AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _fieldLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color:
            isDark ? AppColors.darkTextSecondary : AppColors.onSurfaceVariant,
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required bool isDark,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: TextStyle(
        fontSize: 15,
        color: isDark ? AppColors.darkText : AppColors.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextSecondary : AppColors.outline,
          fontSize: 15,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? AppColors.darkBackground : const Color(0xFFF7F7F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.lime : AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }
}
