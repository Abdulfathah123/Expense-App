import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:int_tst/Home_page.dart';
import 'package:int_tst/expense_section/botton_nav.dart';
import 'package:int_tst/login_section/firebase_signin.dart';
import 'package:int_tst/expense_section/model/user_model.dart';
import 'package:int_tst/login_section/sign_in.dart';

import 'forget_password.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final formkey = GlobalKey<FormState>();
  final _box = GetStorage();
  final _email = TextEditingController();
  final _passwordController = TextEditingController();
  // List<UserModel> _getUser() {
  //   final usrDetails = _box.read<List>('userDetails') ?? [];
  //   return usrDetails
  //       .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
  //       .toList();
  // }

  bool _isPasswordHidden = true;
  String _storedPassword = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEEEEEE),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formkey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 100),
                Image.asset(
                  'Assets/FinTrack.png',
                  height: 150,
                  width: 150,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _email,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email cannot be empty';
                    }
                    return null;
                    // Regex for email validation
                    final emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email';
                    }

                    // Checking if email exists in data
                    //   final data = _getUser();
                    //   final emailExists = data.any((user) {
                    //     pswrd = user.password;
                    //     print(pswrd);
                    //     return user.email == value;
                    //   });
                    //   if (emailExists) {
                    //     return null;
                    //   }
                    //
                    //   return 'Enter Valid email'; // Valid email
                  },
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return null;
                    }
                    return 'Enter a valid password';
                  },
                  obscureText: _isPasswordHidden,
                  controller: _passwordController,
                  decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16)),
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordHidden
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _isPasswordHidden = !_isPasswordHidden;
                          });
                        },
                      )),
                ),

                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ForgotPswrd()),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Forgot Password',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size(250, 50),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    // padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    if (formkey.currentState!.validate()) {
                      FirebaseService().signIn(
                          _email.text, _passwordController.text, context);
                    }
                  },
                  child: const Text(
                    'Log in',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                // Reduced gap between login and signup
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Signin()),
                        );
                      },
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
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
