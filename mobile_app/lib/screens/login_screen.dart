import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile_app/services/firebase_service.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kBg = Color(0xFFF4F3F0);
const _kPurple = Color(0xFF4F46E5);
const _kPurpleLight = Color(0xFFEEEDF8);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _obscurePassword = true;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _animCtrl.reset();
    setState(() => _isLoginMode = !_isLoginMode);
    _animCtrl.forward();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isLoginMode) {
        await FirebaseService().signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await FirebaseService().signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final credentials = await FirebaseService().signInWithGoogle();
    if (mounted && credentials == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Failed to sign in with Google. Please try again.',
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── Background blobs ──────────────────────────────────────
          RepaintBoundary(
            child: Stack(
              children: [
                Positioned(
                  top: -80,
                  right: -60,
                  child: IgnorePointer(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x504F46E5),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 160,
                  left: -60,
                  child: IgnorePointer(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x306352D2),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -60,
                  right: -40,
                  child: IgnorePointer(
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0x284F46E5),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────────────────
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: _isLoginMode ? 60 : 32),
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Column(
                              children: [
                                // App icon
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: _isLoginMode ? 80 : 60,
                                  height: _isLoginMode ? 80 : 60,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF5B52F0),
                                        Color(0xFF3730C8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _kPurple.withOpacity(0.35),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.sparkles,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Wardrobe Master AI',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                    letterSpacing: -1.0,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Your personal AI stylist & digital closet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black.withOpacity(0.45),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: _isLoginMode ? 48 : 24),

                        // ── Form card ────────────────────────────────────
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: SlideTransition(
                            position: _slideAnim,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.06),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(24),
                              child: _isLoading
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 32,
                                      ),
                                      child: Column(
                                        children: [
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                width: 64,
                                                height: 64,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: _kPurple.withOpacity(
                                                    0.07,
                                                  ),
                                                  border: Border.all(
                                                    color: _kPurple.withOpacity(
                                                      0.15,
                                                    ),
                                                    width: 1.5,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 44,
                                                height: 44,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: _kPurple
                                                          .withOpacity(0.25),
                                                      strokeWidth: 1.5,
                                                    ),
                                              ),
                                              const SizedBox(
                                                width: 30,
                                                height: 30,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: _kPurple,
                                                      strokeWidth: 2.5,
                                                    ),
                                              ),
                                              const Icon(
                                                CupertinoIcons.lock_shield,
                                                color: _kPurple,
                                                size: 14,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            _isLoginMode
                                                ? 'Signing in…'
                                                : 'Creating account…',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black87,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Form(
                                      key: _formKey,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          // Tab switcher
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.04,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: _TabButton(
                                                    label: 'Sign In',
                                                    isActive: _isLoginMode,
                                                    onTap: () {
                                                      if (!_isLoginMode)
                                                        _toggleMode();
                                                    },
                                                  ),
                                                ),
                                                Expanded(
                                                  child: _TabButton(
                                                    label: 'Sign Up',
                                                    isActive: !_isLoginMode,
                                                    onTap: () {
                                                      if (_isLoginMode)
                                                        _toggleMode();
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(height: 24),

                                          // Name field (sign up only)
                                          if (!_isLoginMode) ...[
                                            _buildField(
                                              controller: _nameController,
                                              label: 'Full Name',
                                              icon: CupertinoIcons.person,
                                              capitalization:
                                                  TextCapitalization.words,
                                              validator: (v) =>
                                                  v == null || v.trim().isEmpty
                                                  ? 'Please enter your full name'
                                                  : null,
                                            ),
                                            const SizedBox(height: 14),
                                          ],

                                          // Email field
                                          _buildField(
                                            controller: _emailController,
                                            label: 'Email',
                                            icon: CupertinoIcons.mail,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            validator: (v) {
                                              if (v == null || v.isEmpty) {
                                                return 'Please enter your email';
                                              }
                                              if (!v.contains('@')) {
                                                return 'Please enter a valid email';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 14),

                                          // Password field
                                          _buildField(
                                            controller: _passwordController,
                                            label: 'Password',
                                            icon: CupertinoIcons.lock,
                                            obscureText: _obscurePassword,
                                            suffixIcon: GestureDetector(
                                              onTap: () => setState(
                                                () => _obscurePassword =
                                                    !_obscurePassword,
                                              ),
                                              child: Icon(
                                                _obscurePassword
                                                    ? CupertinoIcons.eye
                                                    : CupertinoIcons.eye_slash,
                                                color: Colors.black38,
                                                size: 18,
                                              ),
                                            ),
                                            validator: (v) {
                                              if (v == null || v.isEmpty) {
                                                return 'Please enter your password';
                                              }
                                              if (v.length < 6) {
                                                return 'Password must be at least 6 characters';
                                              }
                                              return null;
                                            },
                                          ),

                                          const SizedBox(height: 24),

                                          // Primary button
                                          _ScaleButton(
                                            onTap: _submitForm,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF5B52F0),
                                                    Color(0xFF3730C8),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _kPurple.withOpacity(
                                                      0.35,
                                                    ),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                _isLoginMode
                                                    ? 'Sign In'
                                                    : 'Create Account',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  letterSpacing: 0.1,
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 20),

                                          // Divider
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  height: 1,
                                                  color: Colors.black
                                                      .withOpacity(0.07),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                    ),
                                                child: Text(
                                                  'or',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black
                                                        .withOpacity(0.35),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  height: 1,
                                                  color: Colors.black
                                                      .withOpacity(0.07),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 20),

                                          // Google button
                                          _ScaleButton(
                                            onTap: _handleGoogleSignIn,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.black
                                                      .withOpacity(0.10),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.05),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: const [
                                                  FaIcon(
                                                    FontAwesomeIcons.google,
                                                    size: 16,
                                                    color: Colors.black87,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    'Continue with Google',
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        SizedBox(height: _isLoginMode ? 60 : 32),
                      ], // Column children
                    ), // Column
                  ), // Padding
                ), // SliverFillRemaining
              ], // slivers
            ), // CustomScrollView
          ), // SafeArea
        ], // Stack children
      ), // Stack (body)
    ); // Scaffold
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      obscureText: obscureText,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.black.withOpacity(0.45),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, size: 18, color: Colors.black38),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.black.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kPurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
      ),
      validator: validator,
    );
  }
}

// ─── Tab button ───────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.black87 : Colors.black.withOpacity(0.40),
          ),
        ),
      ),
    );
  }
}

// ─── Scale button ─────────────────────────────────────────────────────────────

class _ScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _ScaleButton({required this.onTap, required this.child});

  @override
  State<_ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<_ScaleButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
