enum PeakFlowZone { green, yellow, red, unavailable }

class PeakFlowAssessment {
  const PeakFlowAssessment({
    required this.readings,
    required this.highest,
    required this.personalBest,
    required this.percentage,
    required this.zone,
  });

  final List<int> readings;
  final int highest;
  final int? personalBest;
  final double? percentage;
  final PeakFlowZone zone;

  factory PeakFlowAssessment.calculate(List<int> readings, int? personalBest) {
    if (readings.length != 3 ||
        readings.any((value) => value < 1 || value > 1000)) {
      throw const FormatException('Exactly three valid readings are required');
    }
    final highest = readings.reduce((a, b) => a > b ? a : b);
    if (personalBest == null || personalBest <= 0 || personalBest > 1000) {
      return PeakFlowAssessment(
        readings: List.unmodifiable(readings),
        highest: highest,
        personalBest: personalBest,
        percentage: null,
        zone: PeakFlowZone.unavailable,
      );
    }
    final percentage = highest / personalBest * 100;
    final zone = percentage >= 80
        ? PeakFlowZone.green
        : percentage >= 50
        ? PeakFlowZone.yellow
        : PeakFlowZone.red;
    return PeakFlowAssessment(
      readings: List.unmodifiable(readings),
      highest: highest,
      personalBest: personalBest,
      percentage: percentage,
      zone: zone,
    );
  }
}

class DoctorReportData {
  const DoctorReportData({
    required this.profile,
    required this.emergencyContact,
    required this.medications,
    required this.peakFlows,
    required this.symptoms,
    required this.triggers,
  });

  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? emergencyContact;
  final List<Map<String, dynamic>> medications;
  final List<Map<String, dynamic>> peakFlows;
  final List<Map<String, dynamic>> symptoms;
  final List<Map<String, dynamic>> triggers;
}
