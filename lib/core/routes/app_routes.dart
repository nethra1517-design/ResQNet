import 'package:flutter/material.dart';

import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/home/presentation/home_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/';

  static Map<String, WidgetBuilder> routes = {
    login: (_) => const LoginPage(),
    register: (_) => const RegisterPage(),
    home: (_) => const HomePage(),
  };
}