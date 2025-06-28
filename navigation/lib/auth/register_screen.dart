import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:navigation/auth/auth_service.dart';
import 'package:navigation/auth/login_screen.dart';
import 'package:navigation/pages/home_screen.dart';
import 'package:navigation/widgets/button.dart';
import 'package:navigation/widgets/textfield.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _auth = AuthService();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isPasswordVisible = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _signup() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms & Conditions')),
      );
      return;
    }
    try {
      final user = await _auth.createUserWithEmailAndPassword(
        _email.text.trim(),
        _password.text,
        _fullName.text.trim(), // ✅ pass full name here
      );

      if (user != null) {
        log("User Signed Up: ${user.uid}");
        goToHome(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final user = await _auth.signInWithGoogle();
      if (user != null) {
        log("User Signed Up with Google: ${user.uid}");
        goToHome(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void goToLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void goToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F1E4), // Soft whitish-brown
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background transparent UDSM logo
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/image/udsm_logo.png',
                alignment: Alignment.center,
                fit: BoxFit.none,
              ),
            ),
          ),

          // Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 60,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Sign up to get started",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 30),
                        CustomTextField(
                          hint: "Enter Full Name",
                          label: "Full Name",
                          controller: _fullName,
                          prefixIcon: const Icon(Icons.person),
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          hint: "Enter Email",
                          label: "Email",
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email),
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          hint: "Enter Password",
                          label: "Password",
                          controller: _password,
                          obscureText: !_isPasswordVisible,
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreeToTerms = value!;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text('I agree to the Terms & Conditions'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        CustomButton(
                          label: "Sign Up",
                          onPressed: _signup,
                          color: Colors.brown, // Set button to brown
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account? "),
                            InkWell(
                              onTap: () => goToLogin(context),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.brown,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Or sign up with "),
                            IconButton(
                              icon: Image.asset(
                                'assets/image/google.png',
                                height: 24,
                              ),
                              onPressed: _signInWithGoogle,
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
        ],
      ),
    );
  }
}
