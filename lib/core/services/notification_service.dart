
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static StreamSubscription<User?>? _authSubscription;
  static StreamSubscription<String>? _tokenSubscription;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _officialAlertsSubscription;
  static StreamSubscription<User?>? _officialAuthSubscription;

  static final Set<String> _shownAlertIds = {};

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'resqnet_hazards',
    'Nearby hazard alerts',
    description: 'Alerts about hazards and official government warnings.',
    importance: Importance.max,
  );

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _local.initialize(settings);

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    await _authSubscription?.cancel();
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(_handleUser);

    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen(_saveToken);

    await _officialAuthSubscription?.cancel();
    _officialAuthSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        _listenForOfficialAlerts(user);
      },
    );

    final user = FirebaseAuth.instance.currentUser;
    await _handleUser(user);
    _listenForOfficialAlerts(user);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {}
  }

  static Future<void> _handleUser(User? user) async {
    if (user == null) {
      await _officialAlertsSubscription?.cancel();
      _officialAlertsSubscription = null;
      return;
    }

    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);
  }

  static Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static void _listenForOfficialAlerts(User? user) {
    _officialAlertsSubscription?.cancel();
    _officialAlertsSubscription = null;

    if (user == null) return;

    _officialAlertsSubscription = FirebaseFirestore.instance
        .collection('official_alerts')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          if (change.type != DocumentChangeType.added) continue;

          final doc = change.doc;
          final data = doc.data();

          // Do not show old alerts when the listener first starts.
          final createdAt = data['createdAt'];
          if (createdAt is! Timestamp) continue;

          final age = DateTime.now().difference(createdAt.toDate());
          if (age.isNegative || age.inMinutes > 2) continue;

          if (_shownAlertIds.contains(doc.id)) continue;
          _shownAlertIds.add(doc.id);

          await _showOfficialAlert(doc.id, data);
        }
      },
      onError: (Object error) {},
    );
  }

  static Future<void> _showOfficialAlert(
    String id,
    Map<String, dynamic> data,
  ) async {
    final title = (data['title'] ?? 'Official ResQNet Alert').toString();
    final type = (data['type'] ?? 'Disaster').toString();
    final severity = (data['severity'] ?? 'Information').toString();
    final area = (data['affectedArea'] ?? 'Not specified').toString();
    final message = (data['message'] ?? '').toString();

    await _local.show(
      id.hashCode,
      '$type Alert: $title',
      '$severity • $area\n$message',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: id,
    );
  }

  static Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      message.hashCode,
      notification.title ?? 'ResQNet Alert',
      notification.body ?? 'A hazard has been reported near you.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['reportId']?.toString(),
    );
  }

  static Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _officialAlertsSubscription?.cancel();
    await _officialAuthSubscription?.cancel();
  }
}
