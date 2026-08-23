import 'package:flutter/material.dart';

import '../../core/widgets/logout_button.dart';

class ReliefCampDashboard extends StatelessWidget {
  const ReliefCampDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relief Camp Dashboard'),
        actions: const [
          LogoutButton(),
        ],
      ),
      body: const Center(
        child: Text(
          'Relief Camp Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}