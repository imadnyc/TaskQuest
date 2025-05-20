// lib/screens/authentication_ui.dart

import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // No longer needed here
import 'components/const/colors.dart';
import 'components/button_widget.dart';
import 'sign_up_ui.dart';
import 'task_manager_page.dart';
import '../services/authentication_service.dart';
// import '../services/calendar_service.dart'; // No longer needed here
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';  // for AppTheme

class AuthenticationUI extends StatefulWidget {
  final AppTheme currentTheme;
  final ValueChanged<AppTheme> onThemeChanged;

  const AuthenticationUI({
    Key? key,
    required this.currentTheme,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  _AuthenticationUIState createState() => _AuthenticationUIState();
}

class _AuthenticationUIState extends State<AuthenticationUI> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthenticationService _authService =
  AuthenticationService(FirebaseAuth.instance);
  // final CalendarService _calendarService = CalendarService(); // Removed
  // bool _isSigningInWithGoogle = false; // Removed

  // _signInWithGoogle method removed entirely

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: Text("Sign In"),
        centerTitle: true,
        backgroundColor: primaryGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/green_guy.png',
                  height: 250,
                ),
                SizedBox(height: 30),

                // Email input
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryGreen),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: secondaryGreen),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter your email';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                      return 'Enter a valid email';
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Password input
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryGreen),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: secondaryGreen),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter your password';
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Sign In Button
                ButtonWidget(
                  text: 'Sign In',
                  onPressed: () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      final email = _emailController.text.trim();
                      final password = _passwordController.text;
                      final result = await _authService.signIn(
                        email: email,
                        password: password,
                      );
                      if (result == "Signed in") {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskManagerPage(
                              currentTheme: widget.currentTheme,
                              onThemeChanged: widget.onThemeChanged,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result ?? 'Sign in failed')),
                        );
                      }
                    }
                  },
                ),

                // SizedBox(height: 10), // Removed space for Google button
                // Google Sign-In Button Removed
                // _isSigningInWithGoogle
                //   ? CircularProgressIndicator()
                //   : ButtonWidget(
                //       text: 'Sign In with Google',
                //       onPressed: _signInWithGoogle,
                //     ),
                SizedBox(height: 20),

                // Sign up prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignUpUI(), // removed theme args
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
