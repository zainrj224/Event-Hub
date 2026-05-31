import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/inputs/custom_text_field.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _friendlyError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          return 'Invalid email or password. Please check your credentials.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled in Firebase Console.';
        case 'network-request-failed':
          return 'Network error. Check your internet connection.';
        default:
          return 'Sign-in failed (${e.code}): ${e.message}';
      }
    }
    return 'Unexpected error: $e';
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      if (mounted) setState(() => _errorMessage = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    } catch (e) {
      if (mounted) {
        final msg = _friendlyError(e);
        if (!msg.contains('cancelled')) setState(() => _errorMessage = msg);
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() =>
          _errorMessage = 'Enter your email first, then tap Forgot Password.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password reset email sent. Check your inbox.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = _friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : const Color(0xFFF0F0F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 24,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Back arrow ───────────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Icon(
                          Icons.arrow_back,
                          color:
                              isDark ? AppColors.darkText : AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Heading ──────────────────────────────────────────
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color:
                            isDark ? AppColors.darkText : AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Stay connected by signing in with your email\nand password to access your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Google button ────────────────────────────────────
                    _GoogleSignInButton(
                      onPressed: _signInWithGoogle,
                      isLoading: _isGoogleLoading,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // ── Divider ──────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color:
                                    isDark ? Colors.white12 : Colors.black12)),
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
                                color:
                                    isDark ? Colors.white12 : Colors.black12)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Email label + field ──────────────────────────────
                    _fieldLabel('Email Address', isDark),
                    const SizedBox(height: 8),
                    _emailField(isDark),
                    const SizedBox(height: 20),

                    // ── Password label + field ───────────────────────────
                    _fieldLabel('Password', isDark),
                    const SizedBox(height: 8),
                    _passwordField(isDark),
                    const SizedBox(height: 16),

                    // ── Remember me + Forgot password ────────────────────
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () =>
                              setState(() => _rememberMe = !_rememberMe),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 42,
                                height: 24,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: _rememberMe
                                      ? AppColors.lime
                                      : (isDark
                                          ? AppColors.darkOutline
                                          : const Color(0xFFDDDDDD)),
                                ),
                                child: AnimatedAlign(
                                  duration: const Duration(milliseconds: 200),
                                  alignment: _rememberMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.all(3),
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Remember me',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _forgotPassword,
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Error banner ─────────────────────────────────────
                    if (_errorMessage != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              AppColors.errorContainer.withValues(alpha: 0.5),
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
                                    height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ── Sign In button ───────────────────────────────────
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
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
                                  color:
                                      isDark ? AppColors.primary : Colors.white,
                                ),
                              )
                            : Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isDark ? AppColors.primary : Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Sign up link ─────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const SignUpScreen()),
                          ),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color:
                                  isDark ? AppColors.lime : AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

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

  Widget _emailField(bool isDark) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: TextStyle(
        fontSize: 15,
        color: isDark ? AppColors.darkText : AppColors.onSurface,
      ),
      decoration: _inputDecoration(isDark),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Enter your email';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim()))
          return 'Enter a valid email';
        return null;
      },
    );
  }

  Widget _passwordField(bool isDark) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _signIn(),
      style: TextStyle(
        fontSize: 15,
        color: isDark ? AppColors.darkText : AppColors.onSurface,
      ),
      decoration: _inputDecoration(isDark).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: isDark ? AppColors.darkTextSecondary : AppColors.outline,
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Enter your password';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(bool isDark) {
    return InputDecoration(
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

// ─── Google Sign-In Button ────────────────────────────────────────────────────
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDark;

  const _GoogleSignInButton({
    required this.onPressed,
    required this.isLoading,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
          side: BorderSide(
            color: isDark ? AppColors.darkOutline : const Color(0xFFE5E5E5),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleLogo(),
                  const SizedBox(width: 10),
                  Text(
                    'Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Google Logo Painter (unchanged) ─────────────────────────────────────────
class _GoogleLogo extends StatelessWidget {
  static const String _svg =
      '<svg viewBox="-3 0 262 262" xmlns="http://www.w3.org/2000/svg">'
      '<path d="M255.878 133.451c0-10.734-.871-18.567-2.756-26.69H130.55v48.448h71.947c-1.45 12.04-9.283 30.172-26.69 42.356l-.244 1.622 38.755 30.023 2.685.268c24.659-22.774 38.875-56.282 38.875-96.027" fill="#4285F4"/>'
      '<path d="M130.55 261.1c35.248 0 64.839-11.605 86.453-31.622l-41.196-31.913c-11.024 7.688-25.82 13.055-45.257 13.055-34.523 0-63.824-22.773-74.269-54.25l-1.531.13-40.298 31.187-.527 1.465C35.393 231.798 79.49 261.1 130.55 261.1" fill="#34A853"/>'
      '<path d="M56.281 156.37c-2.756-8.123-4.351-16.827-4.351-25.82 0-8.994 1.595-17.697 4.206-25.82l-.073-1.73L15.26 71.312l-1.335.635C5.077 89.644 0 109.517 0 130.55s5.077 40.905 13.925 58.602l42.356-32.782" fill="#FBBC05"/>'
      '<path d="M130.55 50.479c24.514 0 41.05 10.589 50.479 19.438l36.844-35.974C195.245 12.91 165.798 0 130.55 0 79.49 0 35.393 29.301 13.925 71.947l42.211 32.783c10.59-31.477 39.891-54.251 74.414-54.251" fill="#EB4335"/>'
      '</svg>';

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 22, height: 22, child: SvgPicture.string(_svg));
  }
}
