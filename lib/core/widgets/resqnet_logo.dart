import 'package:flutter/material.dart';

class ResQNetLogo extends StatelessWidget {
  final double size;

  const ResQNetLogo({
    super.key,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/resqnet_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}