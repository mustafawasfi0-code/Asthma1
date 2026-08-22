import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../core/localized_values.dart';
import '../models/monitoring.dart';
import '../repositories/health_repository.dart';
import '../widgets/common.dart';

class DoctorReportScreen extends StatefulWidget {
  const DoctorReportScreen({super.key});
  @override
  State<DoctorReportScreen> createState() => _DoctorReportScreenState();
}

class _DoctorReportScreenState extends State<DoctorReportScreen> {
  final repository = HealthRepository();
  late Future<DoctorReportData> report;
  @override
  void initState() {
    super.initState();
    report = repository.loadDoctorReport();
  }

  void _reload() => setState(() => report = repository.loadDoctorReport());
  String _text(dynamic value) =>
      value == null || value.toString().trim().isEmpty
      ? appText('Not set', 'غير محدد')
      : value.toString();
  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    String n(int v) => v.toString().padLeft(2, '0');
    return '${date.year}/${n(date.month)}/${n(date.day)}  ${n(date.hour)}:${n(date.minute)}';
  }

  List<String> _values(dynamic value) =>
      value is List ? value.map((e) => e.toString()).toList() : const [];

  String _measurement(dynamic value, String englishUnit, String arabicUnit) {
    if (value == null || value.toString().trim().isEmpty) return _text(value);
    return ' ';
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: AppState.instance.arabic
        ? TextDirection.rtl
        : TextDirection.ltr,
    child: Scaffold(
      backgroundColor: const Color(0xFFF3F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const AppBackButton(),
        title: Text(
          appText('Doctor report', 'تقرير الطبيب'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<DoctorReportData>(
          future: report,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return _error();
            final data = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                _reload();
                await report;
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                children: [
                  _patient(data.profile),
                  const SizedBox(height: 14),
                  _medications(data.medications),
                  const SizedBox(height: 14),
                  _section(
                    icon: Icons.air,
                    color: const Color(0xFF087CF0),
                    title: appText('Peak flow readings', 'قراءات ذروة التدفق'),
                    empty: data.peakFlows.isEmpty,
                    children: data.peakFlows.map((row) {
                      final highest = row['highest_reading'] ?? row['reading'];
                      final readings = [
                        row['reading_1'],
                        row['reading_2'],
                        row['reading_3'],
                      ].where((v) => v != null).join('، ');
                      return _row(
                        _measurement(highest, 'L/min', 'لتر/دقيقة'),
                        '${readings.isEmpty ? '' : '$readings\n'}${_date(row['measured_at'])}',
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  _section(
                    icon: Icons.sick_outlined,
                    color: Colors.orange,
                    title: appText('Symptoms', 'الأعراض'),
                    empty: data.symptoms.isEmpty,
                    children: data.symptoms
                        .map(
                          (row) => _row(
                            _values(
                              row['symptoms'],
                            ).map(localizedHealthValue).join('، '),
                            '${appText('Severity', 'الشدة')}: ${row['severity']}/5  •  ${_date(row['occurred_at'])}${row['notes'] == null ? '' : '\n${row['notes']}'}',
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  _section(
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFE2A600),
                    title: appText('Triggers', 'مهيجات الربو'),
                    empty: data.triggers.isEmpty,
                    children: data.triggers
                        .map(
                          (row) => _row(
                            _values(
                              row['triggers'],
                            ).map(localizedHealthValue).join('، '),
                            _date(row['occurred_at']),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  _emergency(data.emergencyContact),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const AppNav(),
    ),
  );

  Widget _error() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, color: Colors.red, size: 46),
          const SizedBox(height: 12),
          Text(
            appText('Could not load the report.', 'تعذر تحميل تقرير المريض.'),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _reload,
            child: Text(appText('Retry', 'إعادة المحاولة')),
          ),
        ],
      ),
    ),
  );

  Widget _patient(Map<String, dynamic>? profile) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          Icons.person,
          const Color(0xFF087CF0),
          appText('Patient details', 'تفاصيل المريض'),
        ),
        const Divider(height: 24),
        _detail(
          appText('Name', 'الاسم'),
          localizedPersonName(_text(profile?['name'])),
        ),
        _detail(
          appText('Age', 'العمر'),
          profile?['age'] == null
              ? _text(null)
              : '${profile!['age']} ${appText('years', 'سنة')}',
        ),
        _detail(
          appText('sex', 'الجنس'),
          localizedHealthValue(_text(profile?['sex'])),
        ),
        _detail(
          appText('City', 'المدينة'),
          localizedCity(_text(profile?['city'])),
        ),
        _detail(
          appText('Height', 'الطول'),
          _measurement(profile?['height_cm'], 'cm', 'سم'),
        ),
        _detail(
          appText('Personal best PEF', 'أفضل قراءة PEF'),
          _measurement(profile?['personal_best_pef'], 'L/min', 'لتر/دقيقة'),
        ),
        _detail(
          appText('Doctor', 'الطبيب'),
          localizedPersonName(_text(profile?['doctor_name'])),
        ),
        _detail(
          appText('Doctor phone', 'هاتف الطبيب'),
          _text(profile?['doctor_phone']),
        ),
      ],
    ),
  );

  Widget _medications(List<Map<String, dynamic>> rows) => _section(
    icon: Icons.medication_outlined,
    color: const Color(0xFFD82BEF),
    title: appText('Current medications', 'الأدوية الحالية'),
    empty: rows.isEmpty,
    children: rows
        .map(
          (row) => _row(
            AppState.instance.arabic
                ? _text(row['name_ar'])
                : _text(row['name_en']),
            row['medication_type'] == 'emergency'
                ? appText('Rescue medicine', 'دواء إسعافي')
                : appText('Controller medicine', 'دواء وقائي'),
          ),
        )
        .toList(),
  );

  Widget _emergency(Map<String, dynamic>? row) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(
          Icons.emergency_outlined,
          Colors.red,
          appText('Emergency contact', 'جهة اتصال الطوارئ'),
        ),
        const Divider(height: 24),
        _detail(
          appText('Name', 'الاسم'),
          localizedPersonName(_text(row?['contact_name'])),
        ),
        _detail(
          appText('Relationship', 'صلة القرابة'),
          localizedHealthValue(_text(row?['relationship'])),
        ),
        _detail(appText('Phone', 'الهاتف'), _text(row?['phone_number'])),
      ],
    ),
  );

  Widget _section({
    required IconData icon,
    required Color color,
    required String title,
    required bool empty,
    required List<Widget> children,
  }) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(icon, color, title),
        const Divider(height: 24),
        if (empty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                appText('No records', 'لا توجد سجلات'),
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          )
        else
          ...children,
      ],
    ),
  );
  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE4EAF0)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10101828),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
  Widget _heading(IconData icon, Color color, String title) => Row(
    children: [
      Icon(icon, color: color, size: 27),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
      ),
    ],
  );
  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
  Widget _row(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.circle, size: 8, color: Color(0xFF087CF0)),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isEmpty ? appText('Not specified', 'غير محدد') : title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
