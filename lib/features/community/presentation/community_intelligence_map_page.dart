import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class CommunityIntelligenceMapPage extends StatefulWidget {
  const CommunityIntelligenceMapPage({super.key});

  @override
  State<CommunityIntelligenceMapPage> createState() =>
      _CommunityIntelligenceMapPageState();
}

class _CommunityIntelligenceMapPageState
    extends State<CommunityIntelligenceMapPage> {
  final MapController _mapController = MapController();

  static const LatLng _defaultCenter =
      LatLng(20.5937, 78.9629);

  static const double _defaultZoom = 5;

  LatLng? _currentLocation;

  bool _locationLoading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _getCurrentLocation();
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    final messenger = ScaffoldMessenger.of(context);

    if (!mounted) return;

    setState(() {
      _locationLoading = true;
    });

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          _locationLoading = false;
        });

        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Please turn on Location Services on your phone.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );

        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _locationLoading = false;
        });

        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission is required to center the map on your location.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );

        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final LatLng location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = location;
        _locationLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        try {
          _mapController.move(
            location,
            14,
          );
        } catch (_) {}
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _locationLoading = false;
      });

      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to get your current location.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ============================================================
  // FIRESTORE STREAM
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _blockedRoadReportsStream() {
    return FirebaseFirestore.instance
        .collection('blocked_road_reports')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots();
  }

  // ============================================================
  // CONVERT FIRESTORE DATA
  // ============================================================

  List<_BlockedRoadReport> _getReports(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List<_BlockedRoadReport> reports = [];

    for (final document in snapshot.docs) {
      final Map<String, dynamic> data =
          document.data();

      final double? latitude =
          _toDouble(data['latitude']);

      final double? longitude =
          _toDouble(data['longitude']);

      if (latitude == null || longitude == null) {
        continue;
      }

      if (latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        continue;
      }

      reports.add(
        _BlockedRoadReport(
          id: document.id,
          latitude: latitude,
          longitude: longitude,
          description:
              data['description']?.toString() ??
                  'Blocked road reported.',
          status:
              data['status']?.toString() ??
                  'reported',
          photoAttached:
              data['photoAttached'] == true,
          citizenId: data['citizenId']?.toString() ?? '',
          confirmedBy: List<String>.from(data['confirmedBy'] ?? const []),
          confirmationCount: (data['confirmationCount'] as num?)?.toInt() ?? 0,
        ),
      );
    }

    return reports;
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  // ============================================================
  // MOVE TO CURRENT LOCATION
  // ============================================================

  void _moveToCurrentLocation() {
    if (_currentLocation == null) {
      _getCurrentLocation();
      return;
    }

    try {
      _mapController.move(
        _currentLocation!,
        15,
      );
    } catch (_) {}
  }

  // ============================================================
  // MOVE TO BLOCKED ROAD
  // ============================================================

  void _moveToReport(
    BuildContext context,
    _BlockedRoadReport report,
  ) {
    final LatLng reportLocation = LatLng(
      report.latitude,
      report.longitude,
    );

    try {
      _mapController.move(
        reportLocation,
        17,
      );
    } catch (_) {}

    _showReportDetails(
      context,
      report,
    );
  }

  // ============================================================
  // MARKER
  // ============================================================

  Marker _buildMarker(
    BuildContext context,
    _BlockedRoadReport report,
  ) {
    return Marker(
      point: LatLng(
        report.latitude,
        report.longitude,
      ),
      width: 56,
      height: 56,
      child: GestureDetector(
        onTap: () {
          _moveToReport(
            context,
            report,
          );
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: report.status == 'verified'
                ? const Color(0xFF16834A)
                : const Color(0xFF7027A0),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.warning_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CURRENT LOCATION MARKER
  // ============================================================

  Marker? _buildCurrentLocationMarker() {
    if (_currentLocation == null) {
      return null;
    }

    return Marker(
      point: _currentLocation!,
      width: 50,
      height: 50,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3)
              .withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: Color(0xFF2196F3),
              shape: BoxShape.circle,
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyReport(_BlockedRoadReport report) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (user.uid == report.citizenId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot verify your own report.')),
        );
      }
      return;
    }

    final reportRef = FirebaseFirestore.instance
        .collection('blocked_road_reports')
        .doc(report.id);

    try {
      // Use the citizen's saved profile/home location, not live phone GPS.
      final profileSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final profile = profileSnapshot.data();
      final double? profileLatitude =
          _toDouble(profile?['profileLatitude']) ??
          _toDouble(profile?['latitude']);
      final double? profileLongitude =
          _toDouble(profile?['profileLongitude']) ??
          _toDouble(profile?['longitude']);

      if (profileLatitude == null || profileLongitude == null ||
          profileLatitude < -90 || profileLatitude > 90 ||
          profileLongitude < -180 || profileLongitude > 180) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please save your address location in My Profile before verifying hazards.'),
            ),
          );
        }
        return;
      }

      final distance = Geolocator.distanceBetween(
        profileLatitude,
        profileLongitude,
        report.latitude,
        report.longitude,
      );

      if (distance > 3000) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Your saved profile location is ${(distance / 1000).toStringAsFixed(1)} km away. Verification is allowed within 3 km.',
              ),
            ),
          );
        }
        return;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(reportRef);
        if (!snapshot.exists) throw Exception('This report no longer exists.');
        final data = snapshot.data()!;
        final confirmedBy = List<String>.from(data['confirmedBy'] ?? const []);
        if (confirmedBy.contains(user.uid)) {
          throw Exception('You have already verified this report.');
        }
        if ((data['citizenId'] ?? '') == user.uid) {
          throw Exception('You cannot verify your own report.');
        }
        if ((data['status'] ?? '') == 'verified') {
          throw Exception('This report is already verified.');
        }
        confirmedBy.add(user.uid);
        transaction.update(reportRef, {
          'confirmedBy': confirmedBy,
          'confirmationCount': confirmedBy.length,
          'status': confirmedBy.length >= 3 ? 'verified' : 'unverified',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you. Your verification was recorded.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _deleteReport(_BlockedRoadReport report) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != report.citizenId) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete report?'),
        content: const Text('This will remove the report from the Community Intelligence Map for everyone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FirebaseFirestore.instance.collection('blocked_road_reports').doc(report.id).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report deleted.')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete report: $e')),
      );
    }
  }

  // ============================================================
  // REPORT DETAILS
  // ============================================================

  void _showReportDetails(
    BuildContext context,
    _BlockedRoadReport report,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            28,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ==================================================
                // HANDLE
                // ==================================================

                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFD5DCE3),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // TITLE
                // ==================================================

                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration:
                          BoxDecoration(
                        color: report.status == 'verified'
                            ? const Color(0xFFE0F5E8)
                            : const Color(0xFFF3E9FA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_rounded,
                        color: report.status == 'verified'
                            ? const Color(0xFF16834A)
                            : const Color(0xFF7027A0),
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 13),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Blocked Road',
                            style: TextStyle(
                              color:
                                  Color(0xFF102A43),
                              fontSize: 19,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Community Report',
                            style: TextStyle(
                              color:
                                  Color(0xFF7B8794),
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFFFF3D6),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Text(
                        report.status.toUpperCase(),
                        style: const TextStyle(
                          color:
                              Color(0xFF9A6700),
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ==================================================
                // DESCRIPTION
                // ==================================================

                const Text(
                  'Description',
                  style: TextStyle(
                    color:
                        Color(0xFF102A43),
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 7),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFF5F7FA),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Text(
                    report.description,
                    style: const TextStyle(
                      color:
                          Color(0xFF52606D),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                Text(
                  '${report.confirmationCount}/3 citizens confirmed',
                  style: const TextStyle(
                    color: Color(0xFF087F8C),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 15),

                // ==================================================
                // LOCATION
                // ==================================================

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color:
                          Color(0xFF087F8C),
                      size: 21,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        'Lat: ${report.latitude.toStringAsFixed(6)}\n'
                        'Lng: ${report.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          color:
                              Color(0xFF64748B),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                // ==================================================
                // PHOTO
                // ==================================================

                if (report.photoAttached) ...[
                  const SizedBox(height: 13),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .photo_camera_rounded,
                        color:
                            Color(0xFF087F8C),
                        size: 20,
                      ),

                      const SizedBox(width: 8),

                      const Text(
                        'Photo evidence attached',
                        style: TextStyle(
                          color:
                              Color(0xFF52606D),
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                if (FirebaseAuth.instance.currentUser?.uid != null &&
                    FirebaseAuth.instance.currentUser!.uid != report.citizenId &&
                    report.status != 'verified' &&
                    !report.confirmedBy.contains(FirebaseAuth.instance.currentUser!.uid)) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _verifyReport(report);
                      },
                      icon: const Icon(Icons.verified_rounded),
                      label: const Text('CONFIRM THIS HAZARD'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF087F8C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (FirebaseAuth.instance.currentUser?.uid == report.citizenId) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _deleteReport(report);
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('DELETE OUTDATED REPORT'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // ==================================================
                // CLOSE
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF087F8C),
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'CLOSE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor:
            Colors.transparent,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color:
                Color(0xFF102A43),
          ),
        ),

        title: const Text(
          'Community Intelligence Map',
          style: TextStyle(
            color:
                Color(0xFF102A43),
            fontSize: 19,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream:
            _blockedRoadReportsStream(),

        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.hasError) {
            return _buildErrorState(
              snapshot.error.toString(),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFF087F8C),
              ),
            );
          }

          final List<_BlockedRoadReport>
              reports =
              _getReports(
            snapshot.data!,
          );

          final List<Marker> markers = [];

          // ========================================================
          // CURRENT LOCATION MARKER
          // ========================================================

          final Marker? currentMarker =
              _buildCurrentLocationMarker();

          if (currentMarker != null) {
            markers.add(currentMarker);
          }

          // ========================================================
          // BLOCKED ROAD MARKERS
          // ========================================================

          markers.addAll(
            reports.map(
              (report) => _buildMarker(
                context,
                report,
              ),
            ),
          );

          return Stack(
            children: [
              // ====================================================
              // MAP
              // ====================================================

              FlutterMap(
                mapController:
                    _mapController,

                options:
                    const MapOptions(
                  initialCenter:
                      _defaultCenter,
                  initialZoom:
                      _defaultZoom,
                  minZoom: 2,
                  maxZoom: 19,
                ),

                children: [
                  // ==================================================
                  // OPENSTREETMAP
                  // ==================================================

                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName:
                        'com.resqnet.app',
                  ),

                  // ==================================================
                  // MARKERS
                  // ==================================================

                  MarkerLayer(
                    markers: markers,
                  ),

                  // ==================================================
                  // ATTRIBUTION
                  // ==================================================

                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                      ),
                    ],
                  ),
                ],
              ),

              // ====================================================
              // TOP REPORT COUNT
              // ====================================================

              Positioned(
                top: 15,
                left: 15,
                right: 15,

                child: Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),

                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withValues(
                      alpha: 0.95,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(
                          alpha: 0.10,
                        ),
                        blurRadius: 12,
                        offset:
                            const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,

                        decoration:
                            const BoxDecoration(
                          color:
                              Color(0xFFF3E9FA),
                          shape:
                              BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons
                              .warning_rounded,
                          color:
                              Color(0xFF7027A0),
                          size: 21,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            const Text(
                              'Blocked Road Reports',
                              style: TextStyle(
                                color:
                                    Color(
                                  0xFF102A43,
                                ),
                                fontSize: 13,
                                fontWeight:
                                    FontWeight
                                        .w900,
                              ),
                            ),

                            const SizedBox(
                              height: 2,
                            ),

                            Text(
                              '${reports.length} active '
                              '${reports.length == 1 ? 'report' : 'reports'}',
                              style:
                                  const TextStyle(
                                color:
                                    Color(
                                  0xFF7B8794,
                                ),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons
                            .radio_button_checked,
                        color:
                            Color(0xFF16A34A),
                        size: 12,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color:
                              Color(0xFF16833B),
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ====================================================
              // LOCATION LOADING
              // ====================================================

              if (_locationLoading)
                Positioned(
                  top: 95,
                  left: 0,
                  right: 0,

                  child: Center(
                    child: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),

                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(
                              alpha: 0.10,
                            ),
                            blurRadius: 10,
                          ),
                        ],
                      ),

                      child: const Row(
                        mainAxisSize:
                            MainAxisSize.min,

                        children: [
                          SizedBox(
                            width: 15,
                            height: 15,

                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Color(
                                0xFF087F8C,
                              ),
                            ),
                          ),

                          SizedBox(width: 8),

                          Text(
                            'Getting your location...',
                            style: TextStyle(
                              color:
                                  Color(
                                0xFF52606D,
                              ),
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ====================================================
              // MAP CONTROLS
              // ====================================================

              Positioned(
                right: 15,
                bottom: 25,

                child: Column(
                  children: [
                    // ==================================================
                    // CURRENT LOCATION
                    // ==================================================

                    _MapControlButton(
                      icon:
                          Icons.my_location_rounded,
                      onPressed:
                          _moveToCurrentLocation,
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ==================================================
                    // ZOOM IN
                    // ==================================================

                    _MapControlButton(
                      icon:
                          Icons.add_rounded,
                      onPressed: () {
                        try {
                          _mapController.move(
                            _mapController
                                .camera.center,
                            _mapController
                                    .camera.zoom +
                                1,
                          );
                        } catch (_) {}
                      },
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    // ==================================================
                    // ZOOM OUT
                    // ==================================================

                    _MapControlButton(
                      icon:
                          Icons.remove_rounded,
                      onPressed: () {
                        try {
                          _mapController.move(
                            _mapController
                                .camera.center,
                            _mapController
                                    .camera.zoom -
                                1,
                          );
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
              ),

              // ====================================================
              // EMPTY STATE
              // ====================================================

              if (reports.isEmpty)
                Positioned(
                  left: 25,
                  right: 25,
                  bottom: 25,

                  child: Container(
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),

                    decoration:
                        BoxDecoration(
                      color: Colors.white
                          .withValues(
                        alpha: 0.96,
                      ),

                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(
                            alpha: 0.10,
                          ),
                          blurRadius: 15,
                        ),
                      ],
                    ),

                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,

                          decoration:
                              const BoxDecoration(
                            color:
                                Color(0xFFEAF7F8),
                            shape:
                                BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.map_rounded,
                            color:
                                Color(0xFF087F8C),
                            size: 24,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              Text(
                                'No blocked road reports',
                                style: TextStyle(
                                  color:
                                      Color(
                                    0xFF102A43,
                                  ),
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                ),
                              ),

                              SizedBox(height: 3),

                              Text(
                                'New community reports will appear here in real time.',
                                style:
                                    TextStyle(
                                  color:
                                      Color(
                                    0xFF7B8794,
                                  ),
                                  fontSize: 11,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(
    String error,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color:
                  Color(0xFFEF4444),
              size: 48,
            ),

            const SizedBox(height: 14),

            const Text(
              'Unable to load community reports.',
              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color:
                    Color(0xFF102A43),
                fontSize: 16,
                fontWeight:
                    FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Please check your connection and Firebase permissions.',
              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color:
                    Color(0xFF7B8794),
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              error,
              textAlign:
                  TextAlign.center,
              maxLines: 3,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                color:
                    Color(0xFF9AA5B1),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// MAP CONTROL BUTTON
// ==================================================================

class _MapControlButton
    extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapControlButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius:
          BorderRadius.circular(13),

      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(13),

        child: SizedBox(
          width: 48,
          height: 48,

          child: Icon(
            icon,
            color:
                const Color(0xFF102A43),
            size: 25,
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// BLOCKED ROAD REPORT MODEL
// ==================================================================

class _BlockedRoadReport {
  final String id;
  final double latitude;
  final double longitude;
  final String description;
  final String status;
  final bool photoAttached;
  final String citizenId;
  final List<String> confirmedBy;
  final int confirmationCount;

  const _BlockedRoadReport({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.status,
    required this.photoAttached,
    required this.citizenId,
    required this.confirmedBy,
    required this.confirmationCount,
  });
}