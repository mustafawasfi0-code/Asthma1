import 'medication.dart';
import 'profile.dart';

class HomeReminder {
  const HomeReminder({
    required this.id,
    required this.title,
    required this.time,
  });

  final String id;
  final String title;
  final String time;

  factory HomeReminder.fromJson(Map<String, dynamic> json) => HomeReminder(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    time: _formatTime(json['time_of_day']?.toString() ?? ''),
  );

  static String _formatTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return value;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
}

class HomeData {
  const HomeData({
    required this.profile,
    required this.medications,
    required this.peakFlows,
    required this.reminders,
    required this.hasEmergencyContact,
  });

  final Profile? profile;
  final List<Medication> medications;
  final List<Map<String, dynamic>> peakFlows;
  final List<HomeReminder> reminders;
  final bool hasEmergencyContact;

  int? get latestPeakFlow =>
      peakFlows.isEmpty ? null : (peakFlows.first['reading'] as num?)?.toInt();
}
