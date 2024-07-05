import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_app/shared/auth_service.dart';

class CustomLoginDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _formKey1 = GlobalKey<FormState>();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final authService = Provider.of<AuthService>(context);

    return AlertDialog(
      title: Text('Login'),
      content: Form(
        key: _formKey1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                }
                return null;
              },
            ),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: "Password",
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                return null;
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey1.currentState!.validate()) {
                  authService.signInWithEmailAndPassword(
                    context,
                    emailController.text,
                    passwordController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
