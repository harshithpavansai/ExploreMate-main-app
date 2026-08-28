import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRememberedUser();
  }

  Future<void> _loadRememberedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? true;
      final savedEmail = prefs.getString('saved_email');
      if (mounted) {
        setState(() {
          _rememberMe = rememberMe;
          if (rememberMe && savedEmail != null) {
            _emailController.text = savedEmail;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading remembered user: $e');
    }
  }


  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final error = await AuthService.instance.signIn(email, password);
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      if (error == null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('remember_me', _rememberMe);
          if (_rememberMe) {
            await prefs.setString('saved_email', email);
          } else {
            await prefs.remove('saved_email');
          }
        } catch (e) {
          debugPrint('Error saving remember_me preference: $e');
        }
        if (!mounted) return;
        try {
          await Provider.of<AppState>(context, listen: false).loadUserData();
        } catch (e) {
          debugPrint('Error loading user data after login: $e');
        }
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred')),
      );
    }
  }



  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/mountain_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A1628), Color(0xFF1A2940)],
                  ),
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Image
                    Image.asset(
                      'assets/images/logo.png',
                      height: 130,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.explore_rounded,
                        size: 90,
                        color: Color(0xFF5D9CEC),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ExploreMate',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your AI-Powered Travel Companion',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(height: 32),
                    // Glassmorphism Container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(28.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Sign in to continue exploring',
                                style: TextStyle(color: Colors.white60, fontSize: 13),
                              ),
                              const SizedBox(height: 24),
                              // Email Field
                              _buildTextField(
                                hint: 'Email address',
                                controller: _emailController,
                                icon: null,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),
                              // Password Field
                              _buildTextField(
                                hint: 'Password',
                                controller: _passwordController,
                                isPassword: true,
                                icon: _obscureText
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                onIconTap: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              // Remember Me & Forgot Password
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          checkColor: Colors.white,
                                          activeColor: const Color(0xFF5D9CEC),
                                          side: const BorderSide(color: Colors.white54),
                                          onChanged: (val) {
                                            setState(() {
                                              _rememberMe = val ?? false;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Remember Me',
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const ForgotPasswordScreen()),
                                    ),
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Color(0xFF5D9CEC),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Sign In Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5D9CEC),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    elevation: 8,
                                    shadowColor:
                                        const Color(0xFF5D9CEC).withValues(alpha: 0.5),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2.5))
                                      : const Text(
                                          'SIGN IN',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                ),
                              ),
                                  const SizedBox(height: 18),
                              // Signup Redirect
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                    style: TextStyle(color: Colors.white60, fontSize: 13),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        Navigator.pushReplacementNamed(context, '/signup'),
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: Color(0xFF5D9CEC),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    IconData? icon,
    VoidCallback? onIconTap,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: icon != null
              ? IconButton(
                  icon: Icon(icon, color: Colors.white54, size: 20),
                  onPressed: onIconTap,
                )
              : null,
        ),
      ),
    );
  }

}

// ─────────────────────────────────────────────────────────────
// Forgot Password Screen
// ─────────────────────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) setState(() { _sent = true; _loading = false; });
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error sending reset email')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A1628), Color(0xFF1A2940)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  const Icon(Icons.lock_reset_rounded, color: Color(0xFF5D9CEC), size: 56),
                  const SizedBox(height: 20),
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your email and we\'ll send you a link to reset your password.',
                    style: TextStyle(color: Colors.white60, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  if (_sent)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.green),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Reset link sent! Check your inbox (and spam folder).',
                              style: TextStyle(color: Colors.white, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Email address',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.email_rounded, color: Colors.white38),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _sendReset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D9CEC),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Text(
                                'SEND RESET LINK',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

