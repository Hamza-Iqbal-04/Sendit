import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_provider.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true; // Toggle between Login and Signup
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _nameController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      if (!_isLogin) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus(); // Hide keyboard

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (_isLogin) {
        await auth.login(_emailController.text.trim(), _passController.text.trim());
      } else {
        await auth.signUp(_emailController.text.trim(), _passController.text.trim(), _nameController.text.trim());
      }

      if (mounted) {
        // Navigation is handled by the stream in main.dart, but we can be explicit to be safe
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.shopping_basket_rounded, size: 64, color: Color(0xFF1B5E20)),
                  const SizedBox(height: 24),
                  Text(
                    _isLogin ? "Welcome Back" : "Create Account",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? "Login to continue shopping" : "Sign up to get started",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  // Name Field (Animated visibility)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: _isLogin ? const SizedBox.shrink() : Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (val) => !_isLogin && (val == null || val.length < 2)
                              ? "Please enter a valid name" : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (val) => val != null && val.contains('@')
                        ? null : "Please enter a valid email",
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) => val != null && val.length >= 6
                        ? null : "Password must be at least 6 characters",
                  ),

                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Implement Forgot Password
                        },
                        child: const Text("Forgot Password?"),
                      ),
                    )
                  else
                    const SizedBox(height: 24),

                  const SizedBox(height: 8),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isLogin ? "LOGIN" : "SIGN UP"),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isLogin ? "Don't have an account? " : "Already have an account? "),
                      TextButton(
                        onPressed: _toggleAuthMode,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: Text(
                          _isLogin ? "Sign Up" : "Login",
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}