import 'package:flutter/material.dart'; // Import AuthController
import 'package:sample/src/providers/login_controller.dart';
import 'package:sample/src/widgets/curve_painter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Text controllers
  final TextEditingController _emailController = TextEditingController(
    text: 'faris@watanafghan.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'asdf1234',
  );

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Auth controller
  final AuthController _authController = AuthController();

  // Loading state
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validate and submit login
  void _submitLogin() {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      _authController.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6366F1), // Indigo-like color at the top
              Color(0xFF818CF8), // Slightly lighter at the bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(top: 50, left: 60, child: _buildLamp()),
              Positioned(top: 30, right: 100, child: _buildLamp()),
              // Bottom curved shape
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 100,
                  child: CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, 100),
                    painter: CurvePainter(),
                  ),
                ),
              ),
              // Plant illustration
              Positioned(
                bottom: 20,
                right: MediaQuery.of(context).size.width / 2 - 40,
                child: _buildPlant(),
              ),
              // Main content
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 60),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Email/Phone input
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'Email or Phone number',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email or phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Password input
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  hintText: 'Password',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              // Login button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _submitLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF818CF8),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Forgot Password
                              // TextButton(
                              //   onPressed: () {},
                              //   child: const Text(
                              //     'Forgot Password?',
                              //     style: TextStyle(color: Colors.white70),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100), // Space for bottom elements
                    ],
                  ),
                ),
              ),
              // Bottom navigation indicator
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLamp() {
    return Column(
      children: [
        Container(height: 40, width: 2, color: Colors.white.withOpacity(0.7)),
        Container(
          height: 30,
          width: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(100),
              topRight: Radius.circular(100),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlant() {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: Colors.indigo[300],
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pot
          Positioned(
            bottom: 10,
            child: Container(
              height: 25,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Leaves
          Positioned(
            top: 15,
            child: Icon(
              Icons.eco,
              size: 40,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
