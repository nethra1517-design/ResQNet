import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/widgets/logout_button.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/resqnet_logo.dart';
import '../../citizen/presentation/citizen_profile_page.dart';
import '../../emergency/presentation/emergency_sos_page.dart';
import '../../requests/presentation/citizens_request_page.dart';
import '../../requests/presentation/food_request_page.dart';
import '../../requests/presentation/medicine_request_page.dart';
import '../../requests/presentation/rescue_request_page.dart';
import '../../community/presentation/community_intelligence_map_page.dart';
import '../../community/presentation/blocked_road_report_page.dart';
import '../../community/presentation/missing_person_report_page.dart';

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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationHistoryPage(),
                    ),
                  );
                },
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

          const SizedBox(width: 2),

          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CitizenProfilePage(),
                ),
              );
            },
            icon: const Icon(
              Icons.person_outline_rounded,
              color: AppTheme.navy,
              size: 27,
            ),
            tooltip: 'My Profile',
          ),

          const SizedBox(width: 2),

          const LogoutButton(),

          const SizedBox(width: 5),
        ],
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            30,
          ),
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

              const SizedBox(height: 18),
              const CitizenWeatherCard(),
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

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EmergencySosPage(),
                            ),
                          );
                        },
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AllQuickActionsPage(),
                        ),
                      );
                    },
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MedicineRequestPage(),
                          ),
                        );
                      },
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const FoodRequestPage(),
                          ),
                        );
                      },
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RescueRequestPage(),
                          ),
                        );
                      },
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const BlockedRoadReportPage(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ======================================================
              // MY REQUESTS
              // ======================================================
              InkWell(
                borderRadius: BorderRadius.circular(21),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CitizenRequestsPage(),
                    ),
                  );
                },
                child: Container(
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
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.teal.withValues(alpha: 0.11),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppTheme.teal,
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 13),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Requests',
                              style: TextStyle(
                                color: AppTheme.navy,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'View your submitted requests and current status.',
                              style: TextStyle(
                                color: Color(0xFF7B8794),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9AA5B1),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ======================================================
              // COMMUNITY INTELLIGENCE MAP
              // ======================================================
              InkWell(
                borderRadius: BorderRadius.circular(21),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CommunityIntelligenceMapPage(),
                    ),
                  );
                },
                child: Container(
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
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF7F8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.map_rounded,
                          color: AppTheme.teal,
                          size: 29,
                        ),
                      ),

                      const SizedBox(width: 13),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Community Intelligence Map',
                              style: TextStyle(
                                color: AppTheme.navy,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'View live community reports and blocked road locations.',
                              style: TextStyle(
                                color: Color(0xFF7B8794),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9AA5B1),
                        size: 24,
                      ),
                    ],
                  ),
                ),
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


class CitizenWeatherCard extends StatefulWidget {
  const CitizenWeatherCard({super.key});

  @override
  State<CitizenWeatherCard> createState() => _CitizenWeatherCardState();
}

class _CitizenWeatherCardState extends State<CitizenWeatherCard> {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final Set<String> _notifiedAlerts = {};
  Timer? _refreshTimer;
  bool _loading = true;
  String? _error;
  String _place = 'Your current location';
  double? _temperature;
  double? _humidity;
  double? _wind;
  double? _rainProbability;
  double? _rainfall;
  int? _weatherCode;
  String? _alert;
  bool _severe = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadWeather();
    _refreshTimer = Timer.periodic(const Duration(minutes: 15), (_) => _loadWeather());
  }

  Future<void> _initNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _notifications.initialize(settings);
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _loadWeather() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Turn on location services to view local weather.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Allow location permission to view local weather.');
      }
      final position = await Geolocator.getCurrentPosition();
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'current': 'temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m',
        'hourly': 'precipitation_probability,precipitation,weather_code',
        'forecast_days': '1',
        'timezone': 'auto',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw Exception('Weather service is unavailable.');
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>;
      final hourly = data['hourly'] as Map<String, dynamic>;
      final now = DateTime.tryParse(current['time'].toString());
      final times = (hourly['time'] as List).cast<String>();
      var start = now == null ? 0 : times.indexWhere((t) => !DateTime.parse(t).isBefore(now));
      if (start < 0) start = 0;
      final probabilities = (hourly['precipitation_probability'] as List).skip(start).take(3).whereType<num>().toList();
      final rainfall = (hourly['precipitation'] as List).skip(start).take(3).whereType<num>().toList();
      final probability = probabilities.isEmpty ? 0.0 : probabilities.reduce((a, b) => a > b ? a : b).toDouble();
      final expectedRain = rainfall.isEmpty ? 0.0 : rainfall.reduce((a, b) => a + b).toDouble();
      final code = (current['weather_code'] as num).toInt();
      final severe = code >= 95 || code == 65 || code == 82 || probability >= 90;
      final rainAlert = probability >= 70 || expectedRain >= 5 || [61, 63, 65, 80, 81, 82].contains(code);
      final alert = severe
          ? 'Severe weather risk. Stay indoors if unsafe and follow official local advisories.'
          : rainAlert
              ? 'Rain expected soon (${probability.toStringAsFixed(0)}% chance in the next few hours).'
              : null;
      if (!mounted) return;
      setState(() {
        _temperature = (current['temperature_2m'] as num).toDouble();
        _humidity = (current['relative_humidity_2m'] as num).toDouble();
        _wind = (current['wind_speed_10m'] as num).toDouble();
        _rainProbability = probability;
        _rainfall = expectedRain;
        _weatherCode = code;
        _alert = alert;
        _severe = severe;
        _place = 'Your current location';
        _loading = false;
      });
      if (alert != null) await _sendAlert(alert, severe);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _sendAlert(String message, bool severe) async {
    final key = '${severe ? 'severe' : 'rain'}:$message';
    if (!_notifiedAlerts.add(key)) return;
    const details = AndroidNotificationDetails(
      'resqnet_weather_alerts',
      'Weather and Safety Alerts',
      channelDescription: 'Rain and severe weather alerts for your location',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    final title = severe ? 'Severe Weather Alert' : 'Rain Alert';
    await _notifications.show(
      severe ? 2 : 1,
      title,
      message,
      const NotificationDetails(android: details, iOS: DarwinNotificationDetails()),
    );
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('resqnet_notification_history') ?? [];
    history.insert(0, jsonEncode({
      'title': title,
      'message': message,
      'time': DateTime.now().toIso8601String(),
      'type': severe ? 'severe' : 'rain',
    }));
    if (history.length > 100) history.removeRange(100, history.length);
    await prefs.setStringList('resqnet_notification_history', history);
  }

  String _condition(int? code) {
    if (code == null) return 'Weather';
    if (code == 0) return 'Clear sky';
    if ([1, 2].contains(code)) return 'Mostly clear';
    if (code == 3) return 'Overcast';
    if ([45, 48].contains(code)) return 'Foggy';
    if ([51, 53, 55, 56, 57].contains(code)) return 'Drizzle';
    if ([61, 63, 65, 66, 67].contains(code)) return 'Rain';
    if ([71, 73, 75, 77].contains(code)) return 'Snow';
    if ([80, 81, 82].contains(code)) return 'Rain showers';
    if ([95, 96, 99].contains(code)) return 'Thunderstorm';
    return 'Variable conditions';
  }

  IconData _weatherIcon(int? code) {
    if (code == null) return Icons.cloud_rounded;
    if ([0, 1].contains(code)) return Icons.wb_sunny_rounded;
    if ([2, 3, 45, 48].contains(code)) return Icons.cloud_rounded;
    if ([95, 96, 99].contains(code)) return Icons.thunderstorm_rounded;
    if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].contains(code)) return Icons.umbrella_rounded;
    return Icons.cloud_queue_rounded;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF123B63), Color(0xFF087E8B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [BoxShadow(color: const Color(0xFF123B63).withValues(alpha: 0.16), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.location_on_rounded, color: Colors.white70, size: 17),
          const SizedBox(width: 5),
          Expanded(child: Text(_place, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700))),
          IconButton(onPressed: _loadWeather, tooltip: 'Refresh weather', visualDensity: VisualDensity.compact, icon: const Icon(Icons.refresh_rounded, color: Colors.white)),
        ]),
        if (_loading)
          const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Center(child: CircularProgressIndicator(color: Colors.white)))
        else if (_error != null)
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 13)),
            TextButton(onPressed: _loadWeather, child: const Text('Try again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ])
        else ...[
          Row(children: [
            Icon(_weatherIcon(_weatherCode), color: Colors.white, size: 47),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_temperature!.round()}°C', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              Text(_condition(_weatherCode), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('RAIN CHANCE', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .5)),
              Text('${_rainProbability!.round()}%', style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
            ]),
          ]),
          const SizedBox(height: 17),
          Row(children: [
            Expanded(child: _weatherMetric(Icons.water_drop_rounded, 'Rain (3h)', '${_rainfall!.toStringAsFixed(1)} mm')),
            Expanded(child: _weatherMetric(Icons.water_rounded, 'Humidity', '${_humidity!.round()}%')),
            Expanded(child: _weatherMetric(Icons.air_rounded, 'Wind', '${_wind!.round()} km/h')),
          ]),
          if (_alert != null) ...[
            const SizedBox(height: 14),
            Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _severe ? const Color(0xFFFFE4E6) : const Color(0xFFFFF1CC), borderRadius: BorderRadius.circular(14)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(_severe ? Icons.warning_rounded : Icons.umbrella_rounded, color: _severe ? const Color(0xFFB91C1C) : const Color(0xFF92400E), size: 21),
              const SizedBox(width: 9),
              Expanded(child: Text(_alert!, style: TextStyle(color: _severe ? const Color(0xFF991B1B) : const Color(0xFF78350F), fontSize: 12, fontWeight: FontWeight.w700, height: 1.35))),
            ])),
          ] else ...[
            const SizedBox(height: 13),
            const Row(children: [Icon(Icons.check_circle_outline_rounded, color: Color(0xFFB7F7D5), size: 18), SizedBox(width: 7), Expanded(child: Text('No significant rain alert detected in the near-term forecast.', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)))]),
          ],
          const SizedBox(height: 10),
          const Text('Forecast-based guidance, not an official disaster warning.', style: TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ]),
    );
  }

  Widget _weatherMetric(IconData icon, String label, String value) => Row(children: [
    Icon(icon, color: Colors.white70, size: 17),
    const SizedBox(width: 5),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
    ])),
  ]);
}


// ==================================================================
// ALL QUICK ACTIONS PAGE
// ==================================================================

class AllQuickActionsPage extends StatelessWidget {
  const AllQuickActionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Quick Actions'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All Actions',
                style: TextStyle(
                  color: AppTheme.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Choose an action to request help or report an emergency situation.',
                style: TextStyle(
                  color: Color(0xFF7B8794),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              _FullActionTile(
                icon: Icons.medical_services_rounded,
                title: 'Medical',
                subtitle: 'Request medical assistance or medicine',
                iconColor: const Color(0xFFEF4444),
                backgroundColor: const Color(0xFFFFEEEE),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const MedicineRequestPage(),
                    ),
                  );
                },
              ),

              _FullActionTile(
                icon: Icons.restaurant_rounded,
                title: 'Food',
                subtitle: 'Request food and essential supplies',
                iconColor: const Color(0xFFF2A900),
                backgroundColor: const Color(0xFFFFF6DE),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FoodRequestPage(),
                    ),
                  );
                },
              ),

              _FullActionTile(
                icon: Icons.directions_car_rounded,
                title: 'Rescue',
                subtitle: 'Request rescue or evacuation assistance',
                iconColor: const Color(0xFF2196F3),
                backgroundColor: const Color(0xFFE9F6FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RescueRequestPage(),
                    ),
                  );
                },
              ),

              _FullActionTile(
                icon: Icons.warning_rounded,
                title: 'Blocked Road',
                subtitle: 'Report blocked roads or hazards',
                iconColor: const Color(0xFF7027A0),
                backgroundColor: const Color(0xFFF3E9FA),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const BlockedRoadReportPage(),
                    ),
                  );
                },
              ),

              _FullActionTile(
                icon: Icons.person_search_rounded,
                title: 'Missing Person',
                subtitle: 'Report a missing person and their last known location',
                iconColor: const Color(0xFF0F766E),
                backgroundColor: const Color(0xFFE7F7F5),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const MissingPersonReportPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// FULL ACTION TILE
// ==================================================================

class _FullActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _FullActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7B8794),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9AA5B1),
                size: 25,
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
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
      ),
    );
  }
}

class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  State<NotificationHistoryPage> createState() => _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList('resqnet_notification_history') ?? [];
    final parsed = <Map<String, dynamic>>[];
    for (final item in items) {
      try {
        parsed.add(jsonDecode(item) as Map<String, dynamic>);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _notifications = parsed;
      _loading = false;
    });
  }

  Future<void> _clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('resqnet_notification_history');
    if (!mounted) return;
    setState(() => _notifications = []);
  }

  String _formatTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Time unavailable';
    final now = DateTime.now();
    final sameDay = date.year == now.year && date.month == now.month && date.day == now.day;
    final time = TimeOfDay.fromDateTime(date).format(context);
    if (sameDay) return 'Today, $time';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} • $time';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              tooltip: 'Clear notifications',
              onPressed: _clearNotifications,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 82,
                          height: 82,
                          decoration: BoxDecoration(
                            color: AppTheme.teal.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_none_rounded, size: 42, color: AppTheme.teal),
                        ),
                        const SizedBox(height: 16),
                        const Text('No notifications yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.navy)),
                        const SizedBox(height: 7),
                        const Text(
                          'Rain and severe-weather alerts generated by ResQNet will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF7B8794), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      final severe = item['type'] == 'severe';
                      final color = severe ? const Color(0xFFDC2626) : const Color(0xFFD97706);
                      return Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE3E8ED)),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.10), shape: BoxShape.circle),
                              child: Icon(severe ? Icons.warning_rounded : Icons.umbrella_rounded, color: color, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['title']?.toString() ?? 'ResQNet Alert', style: const TextStyle(color: AppTheme.navy, fontSize: 15, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 5),
                                  Text(item['message']?.toString() ?? '', style: const TextStyle(color: Color(0xFF536273), fontSize: 13, height: 1.4)),
                                  const SizedBox(height: 8),
                                  Text(_formatTime(item['time']), style: const TextStyle(color: Color(0xFF8A96A3), fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
