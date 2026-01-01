import 'dart:math';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'sign_up_page.dart';
import 'home_page.dart';
import '../widgets/auth_text_field.dart';

//Sign in page. You can see dito din ung parang flying text ng app. FLUTTERINGS!
class SignInPage extends StatefulWidget {
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage>
    with SingleTickerProviderStateMixin {
  final email = TextEditingController();
  final password = TextEditingController();
  final supabaseService = SupabaseService();

  bool loading = false;

  late AnimationController _titleController;
  late Animation<double> _tiltAnimation;

  @override
  void initState() {
    super.initState();

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _tiltAnimation = Tween<double>(
      begin: -0.08,
      end: 0.08,
    ).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void signIn() async {
    setState(() => loading = true);
    try {
      await supabaseService.signIn(email.text, password.text);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0B001A),
              Color(0xFF12002F),
              Color(0xFF05000D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _tiltAnimation,
                  builder: (_, child) {
                    return Transform.rotate(
                      angle: _tiltAnimation.value,
                      child: child,
                    );
                  },
                  child: Text(
                    "FLUTTERINGS!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: Colors.cyanAccent,
                      shadows: [
                        Shadow(
                          color: Colors.cyanAccent.withOpacity(0.8),
                          blurRadius: 20,
                        ),
                        Shadow(
                          color: Colors.purpleAccent.withOpacity(0.6),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                AuthTextField(
                  controller: email,
                  label: "Email",
                  keyboardType: TextInputType.emailAddress,
                ),

                AuthTextField(
                  controller: password,
                  label: "Password",
                  obscure: true,
                ),

                const SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.6),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: loading ? null : signIn,
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors.black)
                        : const Text(
                            "SIGN IN",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SignUpPage()),
                  ),
                  child: const Text(
                    "Create an account",
                    style: TextStyle(color: Colors.purpleAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
