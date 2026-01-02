import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool agreeTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: 40),

                  // ===== Title =====
                  const Center(
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      "Create an account to unlock exclusive features.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ===== Full Name =====
                  const Text("Full Name"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    decoration: _inputDecoration("Enter your Name"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Vui lòng nhập họ tên";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // ===== Email =====
                  const Text("Email"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailController,
                    decoration: _inputDecoration("Enter your Email"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Vui lòng nhập email";
                      }
                      if (!value.contains("@")) {
                        return "Email không hợp lệ";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // ===== Password =====
                  const Text("Password"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: _inputDecoration(
                      "Enter your Password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Vui lòng nhập mật khẩu";
                      }
                      if (value.length < 6) {
                        return "Mật khẩu ít nhất 6 ký tự";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // ===== Terms =====
                  Row(
                    children: [
                      Checkbox(
                        value: agreeTerms,
                        onChanged: (value) {
                          setState(() {
                            agreeTerms = value!;
                          });
                        },
                      ),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(text: "I agree with "),
                              TextSpan(
                                text: "Terms of Use",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: " and "),
                              TextSpan(
                                text: "Privacy Policy",
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (!agreeTerms)
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Text(
                        "Bạn cần đồng ý điều khoản",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ===== Sign Up Button =====
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CD080),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate() && agreeTerms) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Đăng ký thành công"),
                            ),
                          );
                          Navigator.pop(context); // quay lại Login
                        }
                      },
                      child: const Text("Sign Up"),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===== OR =====
                  Row(
                    children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("OR"),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ===== Google =====
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Image.network(
                        "https://upload.wikimedia.org/wikipedia/commons/0/09/IOS_Google_icon.png",
                        height: 20,
                      ),
                      label: const Text("Sign up with Google"),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===== Login =====
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint,
      {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
