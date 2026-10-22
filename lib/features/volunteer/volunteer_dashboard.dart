
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:resqnet/features/home/presentation/home_page.dart';
import '../../core/widgets/logout_button.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  final db = FirebaseFirestore.instance;
  Position? position;
  bool loadingLocation = false;
  bool savingProfile = false;
  final Set<String> accepting = {};

  static const collections = {
    'Emergency SOS': 'emergency_sos',
    'Food Requests': 'food_requests',
    'Medicine Requests': 'medicine_requests',
    'Rescue Requests': 'rescue_requests',
    'Blocked Roads': 'blocked_road_reports',
    'Missing Persons': 'missing_person_reports',
  };

  static const navy = Color(0xFF18334D);
  static const teal = Color(0xFF008C95);
  static const background = Color(0xFFF4F7FA);

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  double distance(double lat, double lon) {
    final p = position!;
    const r = 6371.0;
    final dLat = (lat - p.latitude) * pi / 180;
    final dLon = (lon - p.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p.latitude * pi / 180) *
            cos(lat * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return 2 * r * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Please enable device location.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Please allow ResQNet location permission.');
    }

    return Geolocator.getCurrentPosition();
  }

  Future<void> updateLocation() async {
    setState(() => loadingLocation = true);
    try {
      final p = await getCurrentPosition();
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await db.collection('users').doc(uid).update({
        'latitude': p.latitude,
        'longitude': p.longitude,
      });

      if (!mounted) return;
      setState(() => position = p);
      showMessage('Location updated. Showing requests within 5 km.');
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loadingLocation = false);
    }
  }

  Future<void> editProfile(Map<String, dynamic> user) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: user['name'] ?? '');
    final phone = TextEditingController(text: user['phone'] ?? '');
    final address = TextEditingController(text: user['address'] ?? '');
    final organization =
        TextEditingController(text: user['organization'] ?? '');

    double? lat = (user['latitude'] as num?)?.toDouble();
    double? lon = (user['longitude'] as num?)?.toDouble();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text(
            'Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold, color: navy),
          ),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: teal.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.volunteer_activism,
                        size: 34,
                        color: teal,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Enter your name'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: address,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: organization,
                      decoration: const InputDecoration(
                        labelText: 'Organisation (optional)',
                        prefixIcon: Icon(Icons.groups_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location, color: teal),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              lat == null || lon == null
                                  ? 'Location not set'
                                  : 'Location saved',
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                final p = await getCurrentPosition();
                                setDialogState(() {
                                  lat = p.latitude;
                                  lon = p.longitude;
                                });
                              } catch (e) {
                                showMessage(e
                                    .toString()
                                    .replaceFirst('Exception: ', ''));
                              }
                            },
                            child: const Text('Update'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: teal),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      setState(() => savingProfile = true);
      try {
        await db.collection('users').doc(
          FirebaseAuth.instance.currentUser!.uid,
        ).update({
          'name': name.text.trim(),
          'phone': phone.text.trim(),
          'address': address.text.trim(),
          'organization': organization.text.trim(),
          if (lat != null) 'latitude': lat,
          if (lon != null) 'longitude': lon,
        });

        if (lat != null && lon != null) {
          position = Position(
            latitude: lat!,
            longitude: lon!,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
        showMessage('Profile updated successfully.');
      } catch (e) {
        showMessage('Unable to update profile: $e');
      } finally {
        if (mounted) setState(() => savingProfile = false);
      }
    }

    name.dispose();
    phone.dispose();
    address.dispose();
    organization.dispose();
  }

  Future<void> acceptRequest(
    String collection,
    String requestId,
    String volunteerName,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final key = '$collection/$requestId';
    if (accepting.contains(key)) return;
    setState(() => accepting.add(key));

    try {
      await db.runTransaction((transaction) async {
        final ref = db.collection(collection).doc(requestId);
        final snapshot = await transaction.get(ref);

        if (!snapshot.exists) throw Exception('Request no longer exists.');

        final data = snapshot.data()!;
        final status =
            (data['status'] ?? 'received').toString().toLowerCase();

        if (!['received', 'pending', 'unassigned', 'new']
            .contains(status)) {
          throw Exception('This request has already been claimed or closed.');
        }

        transaction.update(ref, {
          'status': 'accepted',
          'acceptedBy': uid,
          'acceptedByName': volunteerName,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });

      showMessage('Request accepted successfully.');
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => accepting.remove(key));
    }
  }

  Widget requestSection(
    String title,
    String collection,
    String volunteerName,
  ) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(
          side: BorderSide.none,
        ),
        collapsedShape: const RoundedRectangleBorder(
          side: BorderSide.none,
        ),
        iconColor: teal,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db.collection(collection).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Unable to load requests: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final lat = data['latitude'];
                final lon = data['longitude'];
                final status =
                    (data['status'] ?? 'received').toString().toLowerCase();

                if (position == null || lat is! num || lon is! num) {
                  return false;
                }
                if ([
                  'completed',
                  'resolved',
                  'cancelled',
                  'closed',
                ].contains(status)) {
                  return false;
                }
                return distance(lat.toDouble(), lon.toDouble()) <= 5;
              }).toList();

              if (position == null) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Set your location to find nearby requests.'),
                );
              }

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No active requests within 5 km.'),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final status =
                      (data['status'] ?? 'received').toString();
                  final lat = (data['latitude'] as num).toDouble();
                  final lon = (data['longitude'] as num).toDouble();
                  final km = distance(lat, lon);
                  final acceptedBy = data['acceptedBy'];
                  final available = [
                    'received',
                    'pending',
                    'unassigned',
                    'new',
                  ].contains(status.toLowerCase());
                  final description = data['description'] ??
                      data['requestType'] ??
                      data['medicineName'] ??
                      data['foodType'] ??
                      title;
                  final key = '$collection/${doc.id}';

                  return Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: teal,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$description',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (!available)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Status: $status'),
                        Text('Distance: ${km.toStringAsFixed(1)} km'),
                        Text(
                          'Location: ${data['address'] ?? '$lat, $lon'}',
                        ),
                        if (acceptedBy != null)
                          Text(
                            'Accepted by: ${data['acceptedByName'] ?? acceptedBy}',
                          ),
                        if (available) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: teal,
                              ),
                              onPressed: accepting.contains(key)
                                  ? null
                                  : () => acceptRequest(
                                        collection,
                                        doc.id,
                                        volunteerName,
                                      ),
                              icon: accepting.contains(key)
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(
                                accepting.contains(key)
                                    ? 'Accepting...'
                                    : 'Accept Request',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Volunteer Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [LogoutButton()],
      ),
      body: uid == null
          ? const Center(child: Text('Please log in again.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: db.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Profile error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final user = snapshot.data!.data() ?? {};
                final name = (user['name'] ?? 'Volunteer').toString();

                if (position == null &&
                    user['latitude'] is num &&
                    user['longitude'] is num) {
                  position ??= Position(
                    latitude: (user['latitude'] as num).toDouble(),
                    longitude: (user['longitude'] as num).toDouble(),
                    timestamp: DateTime.now(),
                    accuracy: 0,
                    altitude: 0,
                    altitudeAccuracy: 0,
                    heading: 0,
                    headingAccuracy: 0,
                    speed: 0,
                    speedAccuracy: 0,
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    Text(
                      'Welcome, $name',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: navy,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user['email'] ?? ''}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: savingProfile ? null : () => editProfile(user),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(
                          savingProfile ? 'Saving...' : 'Edit Profile',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const CitizenWeatherCard(),
                    const SizedBox(height: 20),
                    Text(
                      'Nearby Citizen Requests',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: navy,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      position == null
                          ? 'Enable location to find requests near you.'
                          : 'Showing active requests within 5 km.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: loadingLocation ? null : updateLocation,
                        icon: loadingLocation
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: Text(
                          loadingLocation
                              ? 'Getting Location...'
                              : 'Find Requests Within 5 km',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...collections.entries.map(
                      (entry) => requestSection(
                        entry.key,
                        entry.value,
                        name,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
