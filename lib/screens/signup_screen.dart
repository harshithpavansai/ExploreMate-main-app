import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscureText = true;
  bool _isLoading = false;
  bool _verificationSent = false;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final error = await AuthService.instance.signUp(name, email, password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (error == null) {
        // Send email verification
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          setState(() => _verificationSent = true);
        } else {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('remember_me', true);
            await prefs.setString('saved_email', email);
          } catch (e) {
            debugPrint('Error saving remember_me: $e');
          }
          if (!mounted) return;
          try {
            await Provider.of<AppState>(context, listen: false).loadUserData();
          } catch (e) {
            debugPrint('Error loading user data after signup: $e');
          }
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (user != null && user.emailVerified) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('remember_me', true);
          if (user.email != null) {
            await prefs.setString('saved_email', user.email!);
          }
        } catch (e) {
          debugPrint('Error saving remember_me: $e');
        }
        if (!mounted) return;
        try {
          await Provider.of<AppState>(context, listen: false).loadUserData();
        } catch (e) {
          debugPrint('Error loading user data after verification: $e');
        }
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email not verified yet. Check your inbox.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.explore_rounded, size: 80, color: Color(0xFF5D9CEC)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ExploreMate',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 28),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
                          ),
                          child: _verificationSent
                              ? _buildVerificationCard()
                              : _buildSignupForm(),
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

  Widget _buildSignupForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Create Account',
            style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Start your travel journey today',
            style: TextStyle(color: Colors.white60, fontSize: 13)),
        const SizedBox(height: 24),
        _buildField('Full Name', _nameCtrl, icon: Icons.person_rounded),
        const SizedBox(height: 12),
        _buildField('Email address', _emailCtrl,
            icon: Icons.email_rounded, keyboard: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _buildField('Password (min 6 chars)', _passwordCtrl,
            icon: Icons.lock_rounded, isPassword: true),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D9CEC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              elevation: 8,
              shadowColor: const Color(0xFF5D9CEC).withValues(alpha: 0.5),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('CREATE ACCOUNT',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Already have an account? ',
                style: TextStyle(color: Colors.white60, fontSize: 13)),
            GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Sign In',
                  style: TextStyle(color: Color(0xFF5D9CEC), fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerificationCard() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_unread_rounded, size: 64, color: Color(0xFF5D9CEC)),
        const SizedBox(height: 16),
        const Text('Verify Your Email',
            style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(
          'We sent a verification link to ${_emailCtrl.text}. Click the link, then come back here.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _checkVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5D9CEC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text("I'VE VERIFIED — CONTINUE",
                    style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () async {
            await FirebaseAuth.instance.currentUser?.sendEmailVerification();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification email resent!')),
              );
            }
          },
          child: const Text('Resend verification email',
              style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  Widget _buildField(
    String hint,
    TextEditingController ctrl, {
    IconData? icon,
    bool isPassword = false,
    TextInputType? keyboard,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: isPassword && _obscureText,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: icon != null ? Icon(icon, color: Colors.white38, size: 20) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: Colors.white38, size: 20),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                )
              : null,
        ),
      ),
    );
  }
}
