import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

enum ForgotStep { email, otp, resetPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();

  ForgotStep currentStep = ForgotStep.email;

  String? resetToken; // ✅ QUAN TRỌNG

  bool isLoading = false;
  bool obscurePassword = true;

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

                  // ===== TITLE =====
                  Center(
                    child: Text(
                      _getTitle(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      _getSubtitle(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ===== STEP 1: EMAIL =====
                  if (currentStep == ForgotStep.email) ...[
                    const Text("Email"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration("Enter your email"),
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
                  ],

                  // ===== STEP 2: OTP =====
                  if (currentStep == ForgotStep.otp) ...[
                    const Text("OTP Code"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Enter OTP"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Vui lòng nhập OTP";
                        }
                        return null;
                      },
                    ),
                  ],

                  // ===== STEP 3: RESET PASSWORD =====
                  if (currentStep == ForgotStep.resetPassword) ...[
                    const Text("New Password"),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscurePassword,
                      decoration: _inputDecoration(
                        "Enter new password",
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
                        if (!RegExp(
                          r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$',
                        ).hasMatch(value)) {
                          return "Mật khẩu ≥8 ký tự, gồm hoa, thường, số & ký tự đặc biệt";
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 30),

                  // ===== MAIN BUTTON =====
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
                      onPressed: isLoading ? null : _handleSubmit,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                        _getButtonText(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===== BACK =====
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Back to Login",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
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

  // ================= LOGIC =================

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      /// STEP 1: SEND OTP
      if (currentStep == ForgotStep.email) {
        await AuthService.forgotPassword(emailController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP đã được gửi tới email")),
        );

        setState(() => currentStep = ForgotStep.otp);
      }

      /// STEP 2: VERIFY OTP
      else if (currentStep == ForgotStep.otp) {
        resetToken = await AuthService.verifyOtp(
          email: emailController.text.trim(),
          otp: otpController.text.trim(),
        );

        otpController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP hợp lệ")),
        );

        setState(() => currentStep = ForgotStep.resetPassword);
      }

      /// STEP 3: RESET PASSWORD
      else if (currentStep == ForgotStep.resetPassword) {
        if (resetToken == null) {
          throw Exception("Thiếu reset token");
        }

        await AuthService.resetPassword(
          resetToken: resetToken!,
          newPassword: newPasswordController.text.trim(),
        );

        newPasswordController.clear();
        resetToken = null;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đổi mật khẩu thành công")),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ================= UI HELPERS =================

  String _getTitle() {
    switch (currentStep) {
      case ForgotStep.email:
        return "Forgot Password";
      case ForgotStep.otp:
        return "Verify OTP";
      case ForgotStep.resetPassword:
        return "Reset Password";
    }
  }

  String _getSubtitle() {
    switch (currentStep) {
      case ForgotStep.email:
        return "Enter your email to receive OTP";
      case ForgotStep.otp:
        return "Enter the OTP sent to your email";
      case ForgotStep.resetPassword:
        return "Create a new password";
    }
  }

  String _getButtonText() {
    switch (currentStep) {
      case ForgotStep.email:
        return "Send OTP";
      case ForgotStep.otp:
        return "Verify OTP";
      case ForgotStep.resetPassword:
        return "Reset Password";
    }
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
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
