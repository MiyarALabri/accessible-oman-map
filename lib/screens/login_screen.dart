import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'map_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final supabase = Supabase.instance.client;
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MapScreen()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1482938289607-e9573fc25ebb?auto=format&fit=crop&w=1400&q=80',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFF12372A)),
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.45),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Card(
                    elevation: 10,
                    color: Colors.white.withOpacity(0.96),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        size.width < 360 ? 20 : 28,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 92,
                              width: 92,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9F5EC),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: const Icon(
                                Icons.accessible_forward,
                                size: 58,
                                color: Color(0xFF12372A),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Accessible Oman Map',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF12372A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Find wheelchair-friendly places around Oman.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 26),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';

                                if (email.isEmpty || !email.contains('@')) {
                                  return 'Enter a valid email';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 14),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon:
                                    const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword =
                                          !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if ((value ?? '').trim().length < 6) {
                                  return 'Password must be at least 6 characters';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(height: 22),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _loading ? null : _submit,
                                icon: _loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child:
                                            CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.login),
                                label: const Text('Login'),
                              ),
                            ),
                          ],
                        ),
                      ),
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