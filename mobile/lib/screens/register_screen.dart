import 'package:flutter/material.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng ký")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const TextField(decoration: InputDecoration(labelText: "Email")),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: "Mật khẩu"),
            ),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: "Xác nhận mật khẩu"),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // quay lại login
              },
              child: const Text("Đăng ký"),
            ),
          ],
        ),
      ),
    );
  }
}
