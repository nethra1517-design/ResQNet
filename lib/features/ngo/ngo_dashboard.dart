import 'package:flutter/material.dart';
import '../../core/widgets/logout_button.dart';
class NgoDashboard extends StatelessWidget {
  const NgoDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Dashboard'),
        actions: const [
           LogoutButton(),
        ],
      ),
      body: const Center(
        child: Text(
          'NGO Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}