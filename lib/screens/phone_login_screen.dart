import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();
  
  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationId;

  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('remember_me', true);
        } catch (e) {
          debugPrint('Error saving remember_me: $e');
        }
        if (!mounted) return;
        try {
          await Provider.of<AppState>(context, listen: false).loadUserData();
        } catch (e) {
          debugPrint('Error loading user data: $e');
        }
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Verification failed')));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _isLoading = false;
          _codeSent = true;
          _verificationId = verificationId;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty || _verificationId == null) return;

    setState(() => _isLoading = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', true);
      } catch (e) {
        debugPrint('Error saving remember_me: $e');
      }
      if (!mounted) return;
      try {
        await Provider.of<AppState>(context, listen: false).loadUserData();
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        title: const Text('Phone Login', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_codeSent) ...[
              const Text('Enter Phone Number', style: TextStyle(color: Colors.white, fontSize: 22)),
              const SizedBox(height: 20),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '+91 9876543210',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendCode,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Send OTP'),
              ),
            ] else ...[
              const Text('Enter OTP', style: TextStyle(color: Colors.white, fontSize: 22)),
              const SizedBox(height: 20),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '123456',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Verify OTP'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
