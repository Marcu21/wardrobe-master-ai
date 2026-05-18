import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_app/services/firebase_service.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'widgets/login_header.dart';
import 'widgets/login_form_card.dart';

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
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          // Background blobs
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

          // Content
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
                        LoginHeader(
                          isLoginMode: _isLoginMode,
                          fadeAnim: _fadeAnim,
                          slideAnim: _slideAnim,
                        ),
                        SizedBox(height: _isLoginMode ? 48 : 24),
                        LoginFormCard(
                          formKey: _formKey,
                          emailController: _emailController,
                          passwordController: _passwordController,
                          nameController: _nameController,
                          isLoading: _isLoading,
                          isLoginMode: _isLoginMode,
                          obscurePassword: _obscurePassword,
                          fadeAnim: _fadeAnim,
                          slideAnim: _slideAnim,
                          onSubmit: _submitForm,
                          onGoogleSignIn: _handleGoogleSignIn,
                          onToggleMode: _toggleMode,
                          onToggleObscure: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        SizedBox(height: _isLoginMode ? 60 : 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
