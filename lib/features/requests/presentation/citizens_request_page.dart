import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CitizenRequestsPage extends StatelessWidget {
  const CitizenRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in again.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF102A43),
        elevation: 0,
        title: const Text(
          'My Requests',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emergency_sos')
            .where(
              'citizenId',
              isEqualTo: user.uid,
            )
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to load your requests.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final requests = snapshot.data!.docs.toList();

          // Sort newest first without requiring a Firestore index.
          requests.sort((a, b) {
            final aData =
                a.data() as Map<String, dynamic>;

            final bData =
                b.data() as Map<String, dynamic>;

            final aTime =
                aData['createdAt'] as Timestamp?;

            final bTime =
                bData['createdAt'] as Timestamp?;

            if (aTime == null && bTime == null) {
              return 0;
            }

            if (aTime == null) {
              return 1;
            }

            if (bTime == null) {
              return -1;
            }

            return bTime.compareTo(aTime);
          });

          return RefreshIndicator(
            onRefresh: () async {
              // StreamBuilder updates automatically.
              await Future.delayed(
                const Duration(milliseconds: 300),
              );
            },

            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                30,
              ),
              children: [
                _buildHeader(requests.length),

                const SizedBox(height: 18),

                ...requests.map(
                  (document) {
                    final data =
                        document.data()
                            as Map<String, dynamic>;

                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 14,
                      ),
                      child: _RequestCard(
                        requestId: document.id,
                        data: data,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(int requestCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF087F8C),
              size: 26,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Requests',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF102A43),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  requestCount == 1
                      ? '1 request submitted'
                      : '$requestCount requests submitted',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_outlined,
                size: 42,
                color: Color(0xFF087F8C),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No Requests Yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF102A43),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Your submitted requests will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// REQUEST CARD
// ================================================================

class _RequestCard extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> data;

  const _RequestCard({
    required this.requestId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final emergencyType =
        data['emergencyType']?.toString() ??
            'Emergency';

    final description =
        data['description']?.toString() ?? '';

    final status =
        data['status']?.toString() ?? 'received';

    final severity =
        data['severity']?.toString() ?? 'Normal';

    final assignedDepartment =
        data['assignedDepartment']?.toString() ??
            'Not assigned';

    final priorityData =
        data['priority'];

    String priorityLevel = severity;
    int? priorityScore;

    if (priorityData is Map) {
      priorityLevel =
          priorityData['level']?.toString() ??
              severity;

      final score =
          priorityData['score'];

      if (score is int) {
        priorityScore = score;
      } else if (score != null) {
        priorityScore =
            int.tryParse(score.toString());
      }
    }

    final createdAt =
        data['createdAt'] as Timestamp?;

    final affectedPerson =
        data['affectedPerson'];

    String affectedText = 'Not specified';

    if (affectedPerson is Map) {
      final type =
          affectedPerson['type']?.toString();

      final name =
          affectedPerson['name']?.toString();

      if (type == 'citizen') {
        affectedText = 'Myself';
      } else if (type == 'family_member' &&
          name != null &&
          name.isNotEmpty) {
        affectedText = name;
      } else if (type == 'entire_family') {
        affectedText = 'Entire Family';
      } else if (type == 'none') {
        affectedText = 'None';
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // TOP ROW
          // ------------------------------------------------------

          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: Color(0xFFEF4444),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      emergencyType,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      createdAt == null
                          ? 'Date unavailable'
                          : _formatDate(
                              createdAt.toDate(),
                            ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              _PriorityBadge(
                level: priorityLevel,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ------------------------------------------------------
          // DESCRIPTION
          // ------------------------------------------------------

          if (description.isNotEmpty) ...[
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 14),
          ],

          // ------------------------------------------------------
          // AFFECTED PERSON
          // ------------------------------------------------------

          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Affected',
            value: affectedText,
          ),

          const SizedBox(height: 9),

          // ------------------------------------------------------
          // DEPARTMENT
          // ------------------------------------------------------

          _InfoRow(
            icon: Icons.account_balance_outlined,
            label: 'Department',
            value: assignedDepartment,
          ),

          if (priorityScore != null) ...[
            const SizedBox(height: 9),

            _InfoRow(
              icon: Icons.analytics_outlined,
              label: 'Priority Score',
              value: priorityScore.toString(),
            ),
          ],

          const SizedBox(height: 16),

          // ------------------------------------------------------
          // STATUS
          // ------------------------------------------------------

          const Divider(
            height: 1,
            color: Color(0xFFE2E8F0),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              const Text(
                'Current Status',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),

              const Spacer(),

              _StatusBadge(
                status: status,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final year = date.year.toString();

    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year  $hour:$minute';
  }
}

// ================================================================
// PRIORITY BADGE
// ================================================================

class _PriorityBadge extends StatelessWidget {
  final String level;

  const _PriorityBadge({
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical =
        level.toLowerCase() == 'critical';

    final isHigh =
        level.toLowerCase() == 'high';

    Color background;
    Color foreground;

    if (isCritical) {
      background = const Color(0xFFFFE4E6);
      foreground = const Color(0xFFBE123C);
    } else if (isHigh) {
      background = const Color(0xFFFFF7ED);
      foreground = const Color(0xFFC2410C);
    } else {
      background = const Color(0xFFFEFCE8);
      foreground = const Color(0xFFA16207);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: foreground,
        ),
      ),
    );
  }
}

// ================================================================
// STATUS BADGE
// ================================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized =
        status.toLowerCase();

    Color background;
    Color foreground;
    String displayText;

    switch (normalized) {
      case 'received':
      case 'submitted':
        background =
            const Color(0xFFEFF6FF);
        foreground =
            const Color(0xFF1D4ED8);
        displayText = 'RECEIVED';
        break;

      case 'verified':
        background =
            const Color(0xFFF0FDFA);
        foreground =
            const Color(0xFF0F766E);
        displayText = 'VERIFIED';
        break;

      case 'assigned':
        background =
            const Color(0xFFF5F3FF);
        foreground =
            const Color(0xFF6D28D9);
        displayText = 'ASSIGNED';
        break;

      case 'in_progress':
      case 'in progress':
        background =
            const Color(0xFFFFF7ED);
        foreground =
            const Color(0xFFC2410C);
        displayText = 'IN PROGRESS';
        break;

      case 'resolved':
      case 'completed':
        background =
            const Color(0xFFECFDF5);
        foreground =
            const Color(0xFF047857);
        displayText = 'RESOLVED';
        break;

      case 'rejected':
        background =
            const Color(0xFFFFE4E6);
        foreground =
            const Color(0xFFBE123C);
        displayText = 'REJECTED';
        break;

      default:
        background =
            const Color(0xFFF1F5F9);
        foreground =
            const Color(0xFF475569);
        displayText =
            status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: foreground,
        ),
      ),
    );
  }
}

// ================================================================
// INFO ROW
// ================================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: const Color(0xFF087F8C),
        ),

        const SizedBox(width: 9),

        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),

        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}