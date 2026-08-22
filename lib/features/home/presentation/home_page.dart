import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/resqnet_logo.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),

      // ============================================================
      // HEADER
      // ============================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.menu_rounded,
            color: AppTheme.navy,
            size: 28,
          ),
        ),

        title: const Text(
          'ResQNet',
          style: TextStyle(
            color: AppTheme.navy,
            fontSize: 23,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),

        centerTitle: true,

        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppTheme.navy,
                  size: 29,
                ),
              ),

              Positioned(
                right: 9,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 5),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),

          child: Column(
            children: [

              // ======================================================
              // BRANDING
              // ======================================================
              const ResQNetLogo(
                size: 155,
              ),

              const SizedBox(height: 8),

              const Text(
                'CONNECT  •  RESPOND  •  SAVE',
                style: TextStyle(
                  color: Color(0xFF536273),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 24),

              // ======================================================
              // EMERGENCY SOS CARD
              // ======================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  22,
                  20,
                  20,
                ),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF4147),
                      Color(0xFFD91F26),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  borderRadius: BorderRadius.circular(25),

                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE53935)
                          .withValues(alpha: 0.28),
                      blurRadius: 24,
                      spreadRadius: 1,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),

                child: Column(
                  children: [

                    // Emergency icon
                    Container(
                      width: 62,
                      height: 62,

                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      'Need Emergency Help?',
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      'Send an SOS with your location\n'
                      'and emergency details.',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 21),

                    // SOS BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 58,

                      child: ElevatedButton.icon(
                        onPressed: () {},

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFE53935),
                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),

                        icon: const Icon(
                          Icons.send_rounded,
                          size: 22,
                        ),

                        label: const Text(
                          'SEND EMERGENCY SOS',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ======================================================
              // QUICK ACTIONS HEADER
              // ======================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,

                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: AppTheme.navy,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  TextButton(
                    onPressed: () {},

                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),

                    child: const Text(
                      'View All  →',
                      style: TextStyle(
                        color: AppTheme.teal,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ======================================================
              // MEDICAL + FOOD
              // ======================================================
              Row(
                children: [

                  Expanded(
                    child: _ActionCard(
                      icon: Icons.medical_services_rounded,
                      title: 'Medical',
                      subtitle: 'Request help',
                      iconColor: const Color(0xFFEF4444),
                      backgroundColor: const Color(0xFFFFEEEE),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _ActionCard(
                      icon: Icons.restaurant_rounded,
                      title: 'Food',
                      subtitle: 'Request food',
                      iconColor: const Color(0xFFF2A900),
                      backgroundColor: const Color(0xFFFFF6DE),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ======================================================
              // RESCUE + REPORT
              // ======================================================
              Row(
                children: [

                  Expanded(
                    child: _ActionCard(
                      icon: Icons.directions_car_rounded,
                      title: 'Rescue',
                      subtitle: 'Request rescue',
                      iconColor: const Color(0xFF2196F3),
                      backgroundColor: const Color(0xFFE9F6FF),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _ActionCard(
                      icon: Icons.warning_rounded,
                      title: 'Report',
                      subtitle: 'Report hazard',
                      iconColor: const Color(0xFF7027A0),
                      backgroundColor: const Color(0xFFF3E9FA),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ======================================================
              // LOCATION SERVICES
              // ======================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),

                  border: Border.all(
                    color: const Color(0xFFE3E8ED),
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.035),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Row(
                  children: [

                    // Location icon
                    Container(
                      width: 52,
                      height: 52,

                      decoration: BoxDecoration(
                        color: AppTheme.teal.withValues(alpha: 0.11),
                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.teal,
                        size: 29,
                      ),
                    ),

                    const SizedBox(width: 13),

                    // Text
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            'Location Services',
                            style: TextStyle(
                              color: AppTheme.navy,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            'Used during emergencies for faster response.',
                            style: TextStyle(
                              color: Color(0xFF7B8794),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),

                      decoration: BoxDecoration(
                        color: const Color(0xFFE4F8E9),
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Color(0xFF16833B),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    const SizedBox(width: 3),

                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9AA5B1),
                      size: 22,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// ACTION CARD
// ==================================================================

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color backgroundColor;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 145,
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: const Color(0xFFE1E7EC),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // Icon
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),

            child: Icon(
              icon,
              color: iconColor,
              size: 25,
            ),
          ),

          const Spacer(),

          Text(
            title,
            style: const TextStyle(
              color: AppTheme.navy,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF8A96A3),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}