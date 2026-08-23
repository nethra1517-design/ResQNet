import 'package:flutter/material.dart';

import '../../core/widgets/logout_button.dart';

class VolunteerDashboard extends StatelessWidget {
  const VolunteerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Dashboard'),
        actions: const [
          LogoutButton(),
        ],
      ),
      body: const Center(
        child: Text(
          'Volunteer Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}