class PriorityPredictionResult {
  final String level;
  final int score;
  final List<String> reasons;

  const PriorityPredictionResult({
    required this.level,
    required this.score,
    required this.reasons,
  });
}

class PriorityPredictionService {
  // ============================================================
  // CALCULATE PRIORITY
  // ============================================================

  static PriorityPredictionResult calculate({
    required String emergencySeverity,
    required String affectedPersonType,
    int? age,
    String? healthCondition,
    String? pregnancyStatus,
    List<Map<String, dynamic>> familyMembers = const [],
  }) {
    int score = 0;
    final List<String> reasons = [];

    // ----------------------------------------------------------
    // 1. EMERGENCY SEVERITY
    // ----------------------------------------------------------

    switch (emergencySeverity) {
      case 'Critical':
        score += 60;
        reasons.add('Critical emergency severity');
        break;

      case 'High':
        score += 40;
        reasons.add('High emergency severity');
        break;

      case 'Normal':
        score += 20;
        break;
    }

    // ----------------------------------------------------------
    // 2. NONE
    // ----------------------------------------------------------

    if (affectedPersonType == 'None') {
      return _buildResult(
        score,
        reasons,
      );
    }

    // ----------------------------------------------------------
    // 3. MYSELF
    // ----------------------------------------------------------

    if (affectedPersonType == 'Myself') {
      _applyVulnerabilityFactors(
        age: age,
        healthCondition: healthCondition,
        pregnancyStatus: pregnancyStatus,
        score: (value) {
          score += value;
        },
        reasons: reasons,
      );

      return _buildResult(
        score,
        reasons,
        forceCritical:
            emergencySeverity == 'Critical',
      );
    }

    // ----------------------------------------------------------
    // 4. FAMILY MEMBER
    // ----------------------------------------------------------

    if (affectedPersonType == 'Family Member') {
      _applyVulnerabilityFactors(
        age: age,
        healthCondition: healthCondition,
        pregnancyStatus: pregnancyStatus,
        score: (value) {
          score += value;
        },
        reasons: reasons,
      );

      return _buildResult(
        score,
        reasons,
        forceCritical:
            emergencySeverity == 'Critical',
      );
    }

    // ----------------------------------------------------------
    // 5. ENTIRE FAMILY
    // ----------------------------------------------------------

    if (affectedPersonType == 'Entire Family') {
      int highestVulnerabilityScore = 0;

      String? mostImportantReason;

      for (final member in familyMembers) {
        int memberScore = 0;

        final memberAge = _toInt(
          member['age'],
        );

        final health =
            member['healthCondition']?.toString() ?? '';

        final pregnancy =
            member['pregnancyStatus']?.toString() ??
                'Not Applicable';

        // Age
        if (memberAge != null) {
          if (memberAge < 12) {
            memberScore += 15;

            mostImportantReason =
                'Family includes a child below 12';
          } else if (memberAge >= 65) {
            memberScore += 15;

            mostImportantReason =
                'Family includes an elderly member';
          }
        }

        // Health
        if (_hasHealthCondition(health)) {
          memberScore += 15;

          mostImportantReason =
              'Family includes a member with a health condition';
        }

        // Pregnancy
        if (pregnancy == 'Pregnant') {
          memberScore += 20;

          mostImportantReason =
              'Family includes a pregnant member';
        }

        if (memberScore >
            highestVulnerabilityScore) {
          highestVulnerabilityScore =
              memberScore;
        }
      }

      score += highestVulnerabilityScore;

      if (mostImportantReason != null) {
        reasons.add(mostImportantReason);
      }

      return _buildResult(
        score,
        reasons,
        forceCritical:
            emergencySeverity == 'Critical',
      );
    }

    return _buildResult(
      score,
      reasons,
    );
  }

  // ============================================================
  // VULNERABILITY FACTORS
  // ============================================================

  static void _applyVulnerabilityFactors({
    required int? age,
    required String? healthCondition,
    required String? pregnancyStatus,
    required void Function(int) score,
    required List<String> reasons,
  }) {
    // Age
    if (age != null) {
      if (age < 12) {
        score(15);
        reasons.add('Affected person is below 12 years');
      } else if (age >= 65) {
        score(15);
        reasons.add('Affected person is 65 years or older');
      }
    }

    // Health condition
    if (_hasHealthCondition(
      healthCondition ?? '',
    )) {
      score(15);
      reasons.add('Existing health condition');
    }

    // Pregnancy
    if (pregnancyStatus == 'Pregnant') {
      score(20);
      reasons.add('Pregnancy-related vulnerability');
    }
  }

  // ============================================================
  // HEALTH CONDITION CHECK
  // ============================================================

  static bool _hasHealthCondition(
    String healthCondition,
  ) {
    final value =
        healthCondition.trim().toLowerCase();

    if (value.isEmpty) {
      return false;
    }

    if (value == 'no known condition') {
      return false;
    }

    return true;
  }

  // ============================================================
  // BUILD RESULT
  // ============================================================

  static PriorityPredictionResult _buildResult(
    int score,
    List<String> reasons, {
    bool forceCritical = false,
  }) {
    String level;

    if (forceCritical || score >= 80) {
      level = 'Critical';
    } else if (score >= 50) {
      level = 'High';
    } else {
      level = 'Medium';
    }

    return PriorityPredictionResult(
      level: level,
      score: score,
      reasons: reasons,
    );
  }

  // ============================================================
  // SAFE INTEGER CONVERSION
  // ============================================================

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }
}