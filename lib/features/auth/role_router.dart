import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../admin/admin_dashboard.dart';
import '../government/government_dashboard.dart';
import '../ngo/ngo_dashboard.dart';
import '../relief_camp/relief_camp_dashboard.dart';
import '../volunteer/volunteer_dashboard.dart';
import 'role_service.dart';

class RoleRouter {
  static Future<void> navigateByRole(BuildContext context) async {
    final roleService = RoleService();

    final role = await roleService.getUserRole();

    if (!context.mounted) return;

    switch (role) {
      case 'citizen':
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
        break;

      case 'government':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const GovernmentDashboard(),
          ),
          (route) => false,
        );
        break;

      case 'ngo':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const NgoDashboard(),
          ),
          (route) => false,
        );
        break;

      case 'volunteer':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const VolunteerDashboard(),
          ),
          (route) => false,
        );
        break;

      case 'relief_camp':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const ReliefCampDashboard(),
          ),
          (route) => false,
        );
        break;

      case 'admin':
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboard(),
          ),
          (route) => false,
        );
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'User role not configured. Please contact ResQNet Admin.',
            ),
          ),
        );
    }
  }
}