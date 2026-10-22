
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OfficialAlertsSection extends StatelessWidget {
  const OfficialAlertsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('official_alerts')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load official alerts.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final alerts = snapshot.data?.docs ?? [];

        if (alerts.isEmpty) {
          return const Center(child: Text('No official alerts at present.'));
        }

        alerts.sort((a, b) {
          final aTime = a.data()['createdAt'] as Timestamp?;
          final bTime = b.data()['createdAt'] as Timestamp?;
          return (bTime?.millisecondsSinceEpoch ?? 0)
              .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
        });

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index].data();
            final severity = (alert['severity'] ?? 'Information').toString();

            final color = severity == 'Critical'
                ? Colors.red
                : severity == 'High'
                    ? Colors.deepOrange
                    : severity == 'Moderate'
                        ? Colors.orange
                        : Colors.teal;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: Icon(Icons.campaign, color: color, size: 30),
                title: Text(
                  (alert['title'] ?? 'Official Alert').toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${alert['type'] ?? 'Disaster'} • $severity\n'
                    '${alert['message'] ?? ''}\n'
                    'Affected area: ${alert['affectedArea'] ?? 'Not specified'}',
                  ),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
