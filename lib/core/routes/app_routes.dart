import 'package:flutter/material.dart';
import '../../features/home/presentation/home_page.dart';

class AppRoutes {
  AppRoutes._();

  static const String home = '/';

  static Map<String, WidgetBuilder> routes = {
    home: (_) => const HomePage(),
  };
}