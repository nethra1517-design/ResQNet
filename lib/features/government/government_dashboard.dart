
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/logout_button.dart';

class GovernmentDashboard extends StatefulWidget {
  const GovernmentDashboard({super.key});

  @override
  State<GovernmentDashboard> createState() => _GovernmentDashboardState();
}

class _GovernmentDashboardState extends State<GovernmentDashboard> {
  final db = FirebaseFirestore.instance;
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  final areaController = TextEditingController();

  String type = 'Disaster';
  String severity = 'High';
  bool publishing = false;

  static const navy = Color(0xFF18334D);
  static const teal = Color(0xFF008C95);
  static const bg = Color(0xFFF4F7FA);

  Future<void> publishAlert() async {
    if (!formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => publishing = true);

    try {
      await db.collection('official_alerts').add({
        'title': titleController.text.trim(),
        'message': messageController.text.trim(),
        'type': type,
        'severity': severity,
        'affectedArea': areaController.text.trim(),
        'status': 'active',
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      titleController.clear();
      messageController.clear();
      areaController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Official alert published successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not publish alert: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => publishing = false);
    }
  }

  Future<void> deactivateAlert(String id) async {
    try {
      await db.collection('official_alerts').doc(id).update({
        'status': 'inactive',
        'deactivatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert deactivated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not deactivate alert: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    messageController.dispose();
    areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(
          'Government Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [LogoutButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.campaign, color: Colors.white, size: 36),
                SizedBox(height: 12),
                Text(
                  'Official Alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Publish weather updates and disaster warnings for ResQNet users.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Create New Alert',
            style: TextStyle(
              color: navy,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Alert title',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Enter an alert title'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'Alert type',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Weather',
                          child: Text('Weather'),
                        ),
                        DropdownMenuItem(
                          value: 'Disaster',
                          child: Text('Disaster'),
                        ),
                        DropdownMenuItem(
                          value: 'Safety',
                          child: Text('Public Safety'),
                        ),
                        DropdownMenuItem(
                          value: 'Evacuation',
                          child: Text('Evacuation'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => type = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: severity,
                      decoration: const InputDecoration(
                        labelText: 'Severity',
                        prefixIcon: Icon(Icons.warning_amber),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Information',
                          child: Text('Information'),
                        ),
                        DropdownMenuItem(
                          value: 'Moderate',
                          child: Text('Moderate'),
                        ),
                        DropdownMenuItem(
                          value: 'High',
                          child: Text('High'),
                        ),
                        DropdownMenuItem(
                          value: 'Critical',
                          child: Text('Critical'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => severity = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: areaController,
                      decoration: const InputDecoration(
                        labelText: 'Affected area',
                        hintText: 'e.g. Tambaram or All areas',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Enter the affected area'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: messageController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Alert message and instructions',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.message_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Enter the alert message'
                              : null,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: publishing ? null : publishAlert,
                        icon: publishing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.publish),
                        label: Text(
                          publishing ? 'Publishing...' : 'Publish Official Alert',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Published Alerts',
            style: TextStyle(
              color: navy,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: db
                .collection('official_alerts')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Unable to load alerts. Check Firestore rules.'),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final alerts = snapshot.data!.docs;

              if (alerts.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No alerts published yet.'),
                  ),
                );
              }

              return Column(
                children: alerts.map((doc) {
                  final data = doc.data();
                  final active = data['status'] == 'active';
                  final level = (data['severity'] ?? 'Information').toString();
                  final color = level == 'Critical'
                      ? Colors.red
                      : level == 'High'
                          ? Colors.deepOrange
                          : level == 'Moderate'
                              ? Colors.orange
                              : teal;

                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.campaign, color: color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  data['title'] ?? 'Official Alert',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Icon(
                                active ? Icons.circle : Icons.check_circle,
                                size: 12,
                                color: active ? color : Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('${data['type'] ?? 'Disaster'} • $level'),
                          const SizedBox(height: 6),
                          Text('${data['message'] ?? ''}'),
                          const SizedBox(height: 8),
                          Text(
                            'Affected area: ${data['affectedArea'] ?? 'Not specified'}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                active ? 'PUBLISHED' : 'INACTIVE',
                                style: TextStyle(
                                  color: active ? teal : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              if (active)
                                TextButton.icon(
                                  onPressed: () => deactivateAlert(doc.id),
                                  icon: const Icon(Icons.visibility_off),
                                  label: const Text('Deactivate'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
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
}
