import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'sign_in_page.dart';
import '../widgets/auth_text_field.dart';

class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  final username = TextEditingController();
  final supabaseService = SupabaseService();

  bool loading = false;

  void signUp() async {
    setState(() => loading = true);
    try {
      await supabaseService.signUp(
        email.text,
        password.text,
        username.text,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SignInPage()),
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
              Color(0xFF05000D),
              Color(0xFF140033),
              Color(0xFF080014),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "CREATE ACCOUNT",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.purpleAccent,
                    shadows: [
                      Shadow(
                        color: Colors.purpleAccent.withOpacity(0.8),
                        blurRadius: 20,
                      ),
                      Shadow(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                AuthTextField(
                  controller: username,
                  label: "Username",
                ),

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
                        color: Colors.purpleAccent.withOpacity(0.6),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: loading ? null : signUp,
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors.black)
                        : const Text(
                            "CREATE",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
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
