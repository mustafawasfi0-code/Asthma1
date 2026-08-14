import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../core/localized_values.dart';
import '../models/monitoring.dart';
import '../repositories/health_repository.dart';
import '../repositories/profile_repository.dart';
import '../widgets/common.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({
    super.key,
    this.initialTab = 0,
    this.previewReadings,
  });
  final int initialTab;
  final List<int>? previewReadings;
  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  final repository = HealthRepository();
  final readings = List.generate(3, (_) => TextEditingController());
  final symptomNote = TextEditingController();
  final customTrigger = TextEditingController();
  final pageScroll = ScrollController();
  late int tab;
  double severity = 0;
  bool saving = false, loading = true;
  bool _showForm = false;
  String? error;
  int? currentPersonalBest;
  final selectedSymptoms = <String>{};
  final selectedTriggers = <String>{};
  List<Map<String, dynamic>> peakLogs = [], symptomLogs = [], triggerLogs = [];

  static const symptoms = {
    'Cough': 'سعال',
    'Wheezing': 'صفير',
    'Shortness of breath': 'ضيق نفس',
    'Night waking': 'استيقاظ ليلاً',
    'Fatigue': 'تعب',
    'Chest pain': 'ألم صدر',
    'Other': 'أخرى',
  };
  static const triggers = {
    'Dust & Sandstorms': 'الغبار والعواصف الترابية',
    'Smoke & Tobacco': 'الدخان والتدخين',
    'Exercise & Effort': 'الجهد البدني والرياضة',
    'Cold Air': 'الهواء البارد والتغير الجوي',
    'Strong Scents': 'العطور والروائح القوية',
    'Pets': 'الحيوانات الأليفة',
    'Pollen': 'حبوب اللقاح والنباتات',
    'Stress & Emotions': 'التوتر والمشاعر القوية',
  };

  @override
  void initState() {
    super.initState();
    tab = widget.initialTab;
    final preview = widget.previewReadings;
    if (preview != null && preview.length == 3) {
      for (var index = 0; index < 3; index++) {
        readings[index].text = preview[index].toString();
      }
      loading = false;
    } else {
      _refresh();
    }
  }

  @override
  void didUpdateWidget(covariant MonitoringScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      setState(() => tab = widget.initialTab);
    }
  }

  @override
  void dispose() {
    for (final c in readings) {
      c.dispose();
    }
    symptomNote.dispose();
    customTrigger.dispose();
    pageScroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final best = await repository.personalBest();
      final values = await Future.wait([
        repository.recentPeakFlows(),
        repository.recentSymptoms(),
        repository.recentTriggers(),
      ]);
      if (!mounted) return;
      setState(() {
        currentPersonalBest = best;
        peakLogs = values[0];
        symptomLogs = values[1];
        triggerLogs = values[2];
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => error = appText(
            'Could not load records. Check your connection.',
            'تعذر تحميل السجلات. تحقق من الاتصال.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _save(Future<void> Function() action) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await action();
      await _refresh();
    } on FormatException catch (e) {
      _message(e.message);
    } catch (_) {
      _message(
        appText(
          'Could not save. Check your connection.',
          'تعذر الحفظ. تحقق من الاتصال.',
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  String _date(dynamic value) {
    final d = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (d == null) return '';
    String n(int v) => v.toString().padLeft(2, '0');
    return '${d.year}/${n(d.month)}/${n(d.day)}  ${n(d.hour)}:${n(d.minute)}';
  }

  List<String> _list(dynamic value) =>
      value is List ? value.map((e) => e.toString()).toList() : <String>[];

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: AppState.instance.arabic
        ? TextDirection.rtl
        : TextDirection.ltr,
    child: Scaffold(
      backgroundColor: const Color(0xFFF3F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const AppBackButton(),
        elevation: 0,
        title: Text(
          appText('Monitoring', 'المراقبة'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: TextButton.icon(
              onPressed: () => context.push('/monitoring/report'),
              icon: const Icon(Icons.description_outlined),
              label: Text(appText('Doctor report', 'تقرير الطبيب')),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEAF4FF),
                foregroundColor: const Color(0xFF087CF0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                controller: pageScroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
                child: Column(
                  children: [
                    _tabs(),
                    const SizedBox(height: 24),
                    if (error != null) _errorCard(),
                    if (tab == 0)
                      _pefTab()
                    else if (tab == 1)
                      _symptomsTab()
                    else
                      _triggersTab(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppNav(),
    ),
  );

  Widget _tabs() => Container(
    height: 56,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE3E8EF)),
    ),
    child: Row(
      children: List.generate(3, (i) {
        final labels = [
          appText('Peak Flow', 'تدفق النفس'),
          appText('Symptoms', 'الأعراض'),
          appText('Triggers', 'المثيرات'),
        ];
        return Expanded(
          child: InkWell(
            key: ValueKey('monitoring_tab_$i'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => tab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: tab == i ? const Color(0xFFDCEEFF) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: tab == i ? const Color(0xFF006DD7) : AppColors.muted,
                  fontSize: 16,
                  fontWeight: tab == i ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
  Widget _errorCard() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1F1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFC9C9)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red),
        const SizedBox(width: 10),
        Expanded(child: Text(error!)),
        TextButton(
          onPressed: _refresh,
          child: Text(appText('Retry', 'إعادة المحاولة')),
        ),
      ],
    ),
  );

  Widget _pefTab() => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appText('Peak Flow', 'ذروة التدفق'),
                  style: const TextStyle(
                    color: Color(0xFF080D18),
                    fontSize: 27,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  appText('Monitor lung function', 'راقب وظائف الرئة'),
                  style: const TextStyle(
                    color: Color(0xFF626A76),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: const Color(0xFF087CF0),
            shape: const CircleBorder(),
            elevation: 5,
            shadowColor: const Color(0x55087CF0),
            child: InkWell(
              key: const ValueKey('new_pef_entry'),
              customBorder: const CircleBorder(),
              onTap: () {
                setState(() {
                  _showForm = true;
                });
              },
              child: const SizedBox(
                width: 58,
                height: 58,
                child: Icon(Icons.add, color: Colors.white, size: 35),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      if (_showForm) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(15, 16, 15, 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8EDF2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12101828),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appText('Record a peak flow reading', 'سجل قراءة ذروة التدفق'),
                style: const TextStyle(
                  color: Color(0xFF10131A),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                appText(
                  'Enter 3 readings - the highest will be saved',
                  'أدخل 3 قراءات - سيتم حفظ الأعلى',
                ),
                style: const TextStyle(
                  color: Color(0xFF69717D),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < 3; index++) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.content_paste_outlined,color: Color(0xFF8B7154),
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      appText('Reading ${index + 1}', 'القراءة ${index + 1}'),
                      style: const TextStyle(
                        color: Color(0xFF333943),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 42,
                  child: TextField(
                    key: ValueKey('pef_reading_$index'),
                    controller: readings[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: Color(0xFF0A0D12),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(color: Color(0xFFDDE2E8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(
                          color: Color(0xFF087CF0),
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
              ],
              _highestPreview(),
              const SizedBox(height: 11),
              _zonesHelp(),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        key: const ValueKey('cancel_pef'),
                        onPressed: () {
                          setState(() {
                            _showForm = false;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF111318),
                          side: const BorderSide(color: Color(0xFFCDD2D8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: Text(
                          appText('Cancel', 'إلغاء'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: FilledButton(
                        key: const ValueKey('save_pef'),
                        onPressed: saving ? null : () async {
                          await _savePef();
                          setState(() {_showForm = false;
                          });
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF087CF0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        child: Text(
                          saving
                              ? appText('Saving…', 'جارٍ الحفظ…')
                              : appText('Save', 'حفظ'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
      _logTitle(appText('Reading history', 'سجل القراءات')),
      _logs(
        peakLogs,
        (row) => _peakRow(row),
        onDelete: repository.deletePeakFlow,
        onEdit: _editPeakFlow,
      ),
    ],
  );

  Widget _highestPreview() {
    final values = readings
        .map((controller) => int.tryParse(controller.text.trim()))
        .whereType<int>()
        .toList();
    final highest = values.isEmpty
        ? null
        : values.reduce((first, second) => first > second ? first : second);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEDFFF7),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFF9DECCA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up, color: Color(0xFF00A85A), size: 23),
          const SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: Color(0xFF087C47),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(text: appText('Highest reading: ', 'أعلى قراءة: ')),
                  TextSpan(
                    text: highest == null
                        ? '--'
                        : appText('$highest L/min', '$highest L/min'),
                    style: const TextStyle(
                      color: Color(0xFF008A4B),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePef() async {
    var saved = false;
    await _save(() async {
      final values = readings.map((c) => int.tryParse(c.text.trim())).toList();
      if (values.any((v) => v == null) || values.length != 3) {
        throw FormatException(
          appText(
            'Enter exactly three valid readings',
            'أدخل ثلاث قراءات صحيحة بالضبط',
          ),
        );
      }
      final assessment = await repository.addPeakFlowSession(
        values.cast<int>(),
      );
      for (final c in readings) {
        c.clear();
      }
      if (!mounted) return;
      saved = true;
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: .58),
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (dialogContext, animation, secondaryAnimation) =>
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4.5, sigmaY: 4.5),
              child: PeakFlowResultDialog(assessment: assessment),),
        transitionBuilder:
            (dialogContext, animation, secondaryAnimation, child) =>
                FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: .96, end: 1).animate(animation),
                    child: child,
                  ),
                ),
      );
    });
    if (!mounted || !saved) {
      return;
    }
    _message(
      appText(
        'Saved in Reading history below.',
        'تم الحفظ في سجل القراءات أسفل الصفحة.',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (mounted && pageScroll.hasClients) {
      await pageScroll.animateTo(
        pageScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _zonesHelp() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF3FF),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF087CF0), size: 20),
            const SizedBox(width: 7),
            Text(
              appText('Peak flow zones:', 'مناطق ذروة التدفق:'),
              style: const TextStyle(
                color: Color(0xFF173E83),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _zoneLine(
          const Color(0xFF00BF36),
          appText('Green (80-100%): Good control', 'أخضر (80-100%): تحكم جيد'),
        ),
        _zoneLine(
          const Color(0xFFFFD400),
          appText('Yellow (50-80%): Caution', 'أصفر (50-80%): يحتاج حذر'),
        ),
        _zoneLine(
          const Color(0xFFF00013),
          appText('Red (<50%): Medical alert', 'أحمر (<50%): تنبيه طبي'),
        ),
      ],
    ),
  );

  Widget _zoneLine(Color color, String text) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: .22), blurRadius: 3),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF173E83),
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _symptomsTab() => Column(
    children: [
      _sectionHeader(
        Icons.sick_outlined,
        appText('Symptoms', 'الأعراض'),
        appText('Record how you feel', 'سجل حالتك الصحية'),
      ),
      const SizedBox(height: 18),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appText('Select all symptoms', 'اختر جميع الأعراض'),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _choiceWrap(symptoms, selectedSymptoms),
            const SizedBox(height: 20),
            Text(
              appText(
                'Severity: ${severity.round()}/10',
                'الشدة: ${severity.round()}/10',
              ),
              style: const TextStyle(fontWeight: FontWeight.w800),),
            Slider(
              key: const ValueKey('symptom_severity'),
              value: severity,
              min: 0,
              max: 10,
              divisions: 10,
              label: severity.round().toString(),
              onChanged: (v) => setState(() => severity = v),
            ),
            TextField(
              controller: symptomNote,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: appText('Optional note', 'ملاحظة اختيارية'),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              key: const ValueKey('save_symptoms'),
              text: appText('Save symptoms', 'حفظ الأعراض'),
              onPressed: saving ? null : _saveSymptoms,
            ),
          ],
        ),
      ),
      _logTitle(appText('Symptom history', 'سجل الأعراض')),
      _logs(
        symptomLogs,
        _symptomRow,
        onDelete: repository.deleteSymptom,
        onEdit: _editSymptom,
      ),
    ],
  );

  Future<void> _saveSymptoms() => _save(() async {
    await repository.addSymptomLog(
      symptoms: selectedSymptoms.toList(),
      severity: severity.round(),
      notes: symptomNote.text,
    );
    selectedSymptoms.clear();
    severity = 0;
    symptomNote.clear();
    if (mounted) setState(() {});
  });

  Widget _triggersTab() => Column(
    children: [
      _sectionHeader(
        Icons.warning_amber_rounded,
        appText('Triggers', 'المثيرات'),
        appText('Record what triggered symptoms', 'سجل مسببات الأعراض'),
      ),
      const SizedBox(height: 18),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appText('Select triggers', 'اختر المثيرات'),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _choiceWrap(triggers, selectedTriggers),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('custom_trigger'),
              controller: customTrigger,
              decoration: InputDecoration(
                labelText: appText('Add another trigger', 'أضف مثيراً آخر'),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              key: const ValueKey('save_triggers'),
              text: appText('Save triggers', 'حفظ المثيرات'),
              onPressed: saving ? null : _saveTriggers,
            ),
          ],
        ),
      ),
      _logTitle(appText('Trigger history', 'سجل المثيرات')),
      _logs(
        triggerLogs,
        _triggerRow,
        onDelete: repository.deleteTrigger,
        onEdit: _editTrigger,
      ),
    ],
  );

  Widget _choiceWrap(Map<String, String> choices, Set<String> selected) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: choices.entries.map((e) {
      final active = selected.contains(e.key);
      return FilterChip(
        selected: active,
        label: Text(AppState.instance.arabic ? e.value : e.key),
        onSelected: (_) => setState(
          () => active ? selected.remove(e.key) : selected.add(e.key),
        ),
        selectedColor: const Color(0xFFDCEEFF),
        checkmarkColor: const Color(0xFF087CF0),
      );
    }).toList(),
  );

  Widget _sectionHeader(IconData icon, String title, String subtitle) => Row(
    children: [
      Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFE7F2FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: const Color(0xFF087CF0), size: 34),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 15),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _logTitle(String value) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        value,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
      ),
    ),
  );

  Widget _logs(
    List<Map<String, dynamic>> rows,
    Widget Function(Map<String, dynamic>) tile, {
    required Future<void> Function(String) onDelete,
    Future<void> Function(Map<String, dynamic>)? onEdit,
  }) {
    if (loading) {
      return const AppCard(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (rows.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: Text(
              appText('No records yet', 'لا توجد سجلات بعد'),
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
        ),
      );
    }
    return Column(
      children: rows
          .map(
            (row) => AppCard(
              child: Column(
                children: [
                  tile(row),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          tooltip: appText('Edit', 'تعديل'),
                          onPressed: () => onEdit(row),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      IconButton(
                        tooltip: appText('Delete', 'حذف'),
                        onPressed: () =>
                            _confirmDelete(row['id'].toString(), onDelete),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _peakRow(Map<String, dynamic> row) {
    int highestOf(Map<String, dynamic> value) =>
        ((value['highest_reading'] ?? value['reading']) as num).toInt();

    final highest = highestOf(row);
    final index = peakLogs.indexWhere((item) => item['id'] == row['id']);
    final older = index >= 0 && index + 1 < peakLogs.length
        ? highestOf(peakLogs[index + 1])
        : null;
    final firstReading = (row['reading_1'] as num?)?.toInt();
    final lastReading = (row['reading_3'] as num?)?.toInt();
    final hasSessionDirection = firstReading != null && lastReading != null;
    final comparisonBase = older ?? (hasSessionDirection ? firstReading : null);
    final difference = older != null
        ? highest - older
        : hasSessionDirection
        ? lastReading - firstReading
        : null;
    final changePercent = comparisonBase == null || comparisonBase == 0
        ? null
        : (difference!.abs() / comparisonBase * 100).round();
    final trendColor = difference == null || difference == 0
        ? const Color(0xFF64748B)
        : difference > 0
        ? const Color(0xFF08A85A)
        : const Color(0xFFE5484D);
    final trendIcon = difference == null || difference == 0? Icons.trending_flat
        : difference > 0
        ? Icons.trending_up
        : Icons.trending_down;
    final trendText = difference == null
        ? appText('First reading', 'القراءة الأولى')
        : difference == 0
        ? appText('No change', 'ثابتة')
        : difference > 0
        ? appText(
            'Up ${difference.abs()}${changePercent == null ? '' : ' ($changePercent%)'}',
            'صاعدة ${difference.abs()}${changePercent == null ? '' : ' ($changePercent%)'}',
          )
        : appText(
            'Down ${difference.abs()}${changePercent == null ? '' : ' ($changePercent%)'}',
            'نازلة ${difference.abs()}${changePercent == null ? '' : ' ($changePercent%)'}',
          );

    final calculatedZone = PeakFlowAssessment.calculate([
      highest,
      highest,
      highest,
    ], currentPersonalBest).zone;
    final zoneColor = switch (calculatedZone) {
      PeakFlowZone.green => const Color(0xFF08A85A),
      PeakFlowZone.yellow => const Color(0xFFD89A00),
      PeakFlowZone.red => const Color(0xFFE11D35),
      PeakFlowZone.unavailable => const Color(0xFF64748B),
    };
    final zoneText = switch (calculatedZone) {
      PeakFlowZone.green => appText('Green zone', 'المنطقة الخضراء'),
      PeakFlowZone.yellow => appText('Yellow zone', 'المنطقة الصفراء'),
      PeakFlowZone.red => appText('Red zone', 'المنطقة الحمراء'),
      PeakFlowZone.unavailable => appText('Not calculated', 'غير محسوبة'),
    };
    final values = [
      row['reading_1'],
      row['reading_2'],
      row['reading_3'],
    ].where((e) => e != null).join('، ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: trendColor.withValues(alpha: .12),
        child: Icon(trendIcon, color: trendColor),
      ),
      title: Text(
        '$highest ${appText('L/min', 'لتر/دقيقة')}',
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${values.isEmpty ? '' : '$values\n'}${_date(row['measured_at'])}',
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: zoneColor.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              zoneText,
              style: TextStyle(
                color: zoneColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(trendIcon, size: 16, color: trendColor),
              const SizedBox(width: 3),
              Text(
                trendText,
                style: TextStyle(
                  color: trendColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _symptomRow(Map<String, dynamic> row) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const CircleAvatar(child: Icon(Icons.sick_outlined)),
    title: Text(
      _list(
        row['symptoms'],
      ).map((value) => localizedStoredValue(value, symptoms)).join('، '),
      style: const TextStyle(fontWeight: FontWeight.w800),
    ),
    subtitle: Text(
      '${appText('Severity', 'الشدة')}: ${row['severity']}/10\n${_date(row['occurred_at'])}${row['notes'] == null ? '' : '\n${row['notes']}'}',
    ),
  );

  Widget _triggerRow(Map<String, dynamic> row) => ListTile(contentPadding: EdgeInsets.zero,
    leading: const CircleAvatar(
      backgroundColor: Color(0xFFFFF1DC),
      child: Icon(Icons.warning_amber, color: Colors.orange),
    ),
    title: Text(
      _list(
        row['triggers'],
      ).map((value) => localizedStoredValue(value, triggers)).join('، '),
      style: const TextStyle(fontWeight: FontWeight.w800),
    ),
    subtitle: Text(_date(row['occurred_at'])),
  );

  Future<void> _editPeakFlow(Map<String, dynamic> row) async {
    final controllers = [
      TextEditingController(
        text: (row['reading_1'] ?? row['reading']).toString(),
      ),
      TextEditingController(
        text: (row['reading_2'] ?? row['reading']).toString(),
      ),
      TextEditingController(
        text: (row['reading_3'] ?? row['reading']).toString(),
      ),
    ];
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          appText('Edit peak flow readings', 'تعديل قراءات ذروة التدفق'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: controllers[index],
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: appText(
                    'Reading ${index + 1}',
                    'القراءة ${index + 1}',
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(appText('Cancel', 'إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(appText('Save', 'حفظ')),
          ),
        ],
      ),
    );
    if (save == true) {
      final values = controllers
          .map((controller) => int.tryParse(controller.text.trim()))
          .toList();
      if (values.any((value) => value == null)) {
        _message(
          appText('Enter three valid readings', 'أدخل ثلاث قراءات صحيحة'),
        );
      } else {
        await _save(
          () => repository.updatePeakFlowSession(
            row['id'].toString(),
            values.cast<int>(),
          ),
        );
      }
    }
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  Future<void> _confirmDelete(
    String id,
    Future<void> Function(String) remove,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(appText('Delete record?', 'حذف السجل؟')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(appText('Cancel', 'إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(appText('Delete', 'حذف')),
          ),
        ],
      ),
    );
    if (yes == true) await _save(() => remove(id));
  }

  Future<void> _editSymptom(Map<String, dynamic> row) async {
    final note = TextEditingController(text: row['notes']?.toString() ?? '');
    double value = (row['severity'] as num).toDouble();final chosen = _list(row['symptoms']).toSet();
    final save = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(appText('Edit symptoms', 'تعديل الأعراض')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogChoices(symptoms, chosen, set),
                Slider(
                  value: value,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  onChanged: (v) => set(() => value = v),
                ),
                TextField(
                  controller: note,
                  decoration: InputDecoration(
                    labelText: appText('Note', 'ملاحظة'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(appText('Cancel', 'إلغاء')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(appText('Save', 'حفظ')),
            ),
          ],
        ),
      ),
    );
    if (save == true) {
      await _save(
        () => repository.updateSymptom(
          row['id'].toString(),
          symptoms: chosen.toList(),
          severity: value.round(),
          notes: note.text,
        ),
      );
    }
    note.dispose();
  }

  Future<void> _editTrigger(Map<String, dynamic> row) async {
    final controller = TextEditingController(
      text: _list(row['triggers']).join('، '),
    );
    final save = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(appText('Edit triggers', 'تعديل المثيرات')),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(appText('Cancel', 'إلغاء')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(appText('Save', 'حفظ')),
          ),
        ],
      ),
    );
    if (save == true) {
      await _save(
        () => repository.updateTrigger(
          row['id'].toString(),
          triggers: controller.text
              .split(RegExp(r'[,،]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
        ),
      );
    }
    controller.dispose();
  }

  Widget _dialogChoices(
    Map<String, String> choices,
    Set<String> selected,
    StateSetter set,
  ) => Wrap(
    children: choices.entries
        .map(
          (e) => FilterChip(
            label: Text(AppState.instance.arabic ? e.value : e.key),
            selected: selected.contains(e.key),
            onSelected: (_) => set(
              () => selected.contains(e.key)
                  ? selected.remove(e.key)
                  : selected.add(e.key),
            ),
          ),
        )
        .toList(),
  );

  Future<void> _saveTriggers() async {
    final List<String> values = [...selectedTriggers];
    if (customTrigger.text.trim().isNotEmpty) {
      values.add(customTrigger.text.trim());
    }

    if (values.isEmpty) return;

    await _save(() async {
      await repository.addTriggersLog(triggers: values);
      selectedTriggers.clear();
      customTrigger.clear();
      if (mounted) setState(() {});
    });
  }
}

class PeakFlowResultDialog extends StatefulWidget {
  const PeakFlowResultDialog({super.key, required this.assessment});

  final PeakFlowAssessment assessment;

  @override
  State<PeakFlowResultDialog> createState() => _PeakFlowResultDialogState();
}

class _PeakFlowResultDialogState extends State<PeakFlowResultDialog> {
  late PeakFlowAssessment assessment;
  bool savingPersonalBest = false;

  @override
  void initState() {
    super.initState();
    assessment = widget.assessment;
  }Future<void> _enterPersonalBest() async {
    final controller = TextEditingController();
    String? validationError;
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(appText('Enter personal best', 'أدخل أفضل قراءة شخصية')),
          content: TextField(
            key: const ValueKey('dialog_personal_best_field'),
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: appText('Personal best', 'أفضل قراءة شخصية'),
              suffixText: 'L/min',
              errorText: validationError,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(appText('Cancel', 'إلغاء')),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null || parsed < 1 || parsed > 900) {
                  setDialogState(
                    () => validationError = appText(
                      'Enter a number from 1 to 900',
                      'أدخل رقماً من 1 إلى 900',
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, parsed);
              },
              child: Text(appText('Save', 'حفظ')),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (value == null || !mounted) return;
    setState(() => savingPersonalBest = true);
    try {
      await ProfileRepository().setPersonalBest(value);
      if (!mounted) return;
      setState(() {
        assessment = PeakFlowAssessment.calculate(assessment.readings, value);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appText(
              'Personal best saved and zone recalculated.',
              'تم حفظ أفضل قراءة وإعادة حساب المنطقة.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appText(
              'Could not save personal best.',
              'تعذر حفظ أفضل قراءة شخصية.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => savingPersonalBest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zone = assessment.zone;
    final color = switch (zone) {
      PeakFlowZone.green => const Color(0xFF0BA957),
      PeakFlowZone.yellow => const Color(0xFFF2B400),
      PeakFlowZone.red => const Color(0xFFF0000B),
      PeakFlowZone.unavailable => const Color(0xFF526AA0),
    };
    final pale = switch (zone) {
      PeakFlowZone.green => const Color(0xFFE6FAEF),
      PeakFlowZone.yellow => const Color(0xFFFFF7DA),
      PeakFlowZone.red => const Color(0xFFFFE5E8),
      PeakFlowZone.unavailable => const Color(0xFFEDF1FA),
    };
    final title = switch (zone) {
      PeakFlowZone.green => appText(
        'Green Zone - Doing well',
        'المنطقة الخضراء - تحكم جيد',
      ),
      PeakFlowZone.yellow => appText(
        'Yellow Zone - Caution',
        'المنطقة الصفراء - حذر',
      ),
      PeakFlowZone.red => appText(
        'Red Zone - Medical danger',
        '🚨 المنطقة الحمراء - خطر طبي',
      ),
      PeakFlowZone.unavailable => appText(
        'Personal best required',
        'أفضل رقم شخصي مطلوب',
      ),
    };
    final message = switch (zone) {
      PeakFlowZone.green => appText('Your breathing is stable. Continue your prescribed treatment.',
        'تنفسك مستقر. استمر على العلاج الموصوف.',
      ),
      PeakFlowZone.yellow => appText(
        'Your breathing needs attention. Follow your rescue plan.',
        'تنفسك يحتاج إلى الانتباه. اتبع خطة الإنقاذ.',
      ),
      PeakFlowZone.red => appText(
        'Severe symptoms! You need immediate medical care.',
        'أعراض حادة! تحتاج إلى عناية طبية فورية.',
      ),
      PeakFlowZone.unavailable => appText(
        'Set your personal best to calculate your peak flow zone.',
        'أدخل أفضل رقم شخصي لحساب منطقة ذروة التدفق.',
      ),
    };
    final action = switch (zone) {
      PeakFlowZone.green => appText(
        'Continue your prescribed medicines and monitor your readings.',
        'استمر على أدويتك الموصوفة وراقب قراءاتك.',
      ),
      PeakFlowZone.yellow => appText(
        'Use your rescue inhaler as prescribed and repeat the reading.',
        'استخدم بخاخ الإنقاذ حسب الوصفة وأعد القياس.',
      ),
      PeakFlowZone.red => appText(
        'Use your rescue inhaler now. Contact your doctor or go to the emergency room immediately. Do not delay!',
        'استخدم البخاخ الاسعافي الآن. اتصل بطبيبك أو اذهب لغرفة الطوارئ فوراً. لا تتأخر!',
      ),
      PeakFlowZone.unavailable => appText(
        'Open Profile and enter a valid personal best.',
        'افتح الملف الشخصي وأدخل أفضل رقم شخصي صحيح.',
      ),
    };
    final percentage = assessment.percentage?.round();

    return Directionality(
      textDirection: AppState.instance.arabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(23),
          side: BorderSide(color: color.withValues(alpha: .46), width: 1.5),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 17),
            child: Column(
              mainAxisSize: computationLimits,
              children: [
                SizedBox(
                  height: 78,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          key: const ValueKey('close_pef_dialog'),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF555D67),
                            size: 25,
                          ),
                        ),
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: pale,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          zone == PeakFlowZone.green
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          color: color,
                          size: 50,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (zone == PeakFlowZone.red) ...[Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(
                          Icons.priority_high,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 7),
                    ],
                    Flexible(
                      child: Text(
                        title.replaceFirst('🚨 ', ''),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: zone == PeakFlowZone.red
                              ? const Color(0xFFAD0010)
                              : color,
                          fontSize: 22,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Container(
                  width: double.infinity,
                  height: 164,
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F7FA),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: const Color(0xFFD9E1E6)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.monitor_heart_outlined,
                            color: Color(0xFF626A75),
                            size: 25,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            appText('Peak flow reading', 'قراءة ذروة التدفق'),
                            style: const TextStyle(
                              color: Color(0xFF59616C),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Text(
                                'L/min',
                                style: TextStyle(
                                  color: Color(0xFF4B535E),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${assessment.highest}',
                              style: const TextStyle(
                                color: Color(0xFF0A0F19),
                                fontSize: 44,
                                height: 1,
                                fontWeight: FontWeight.w900,),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 7),
                      if (percentage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: pale,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            appText(
                              '$percentage% of personal best',
                              '$percentage% من أفضل رقم',
                            ),
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      const SizedBox(height: 3),
                      Text(
                        '${appText('Personal best', 'أفضل رقم شخصي')}: '
                        '${assessment.personalBest ?? appText('Not set', 'غير محدد')} L/min',
                        style: const TextStyle(
                          color: Color(0xFF606873),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: zone == PeakFlowZone.red
                        ? const Color(0xFF9D0615)
                        : color,
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 11),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 96),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: pale,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: color.withValues(alpha: .22)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.content_paste_outlined,
                            color: Color(0xFF8B7154),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            appText('Actions:', 'الإجراءات:'),
                            style: TextStyle(
                              color: zone == PeakFlowZone.red
                                  ? const Color(0xFF8F0010)
                                  : color,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        action,
                        textAlign: TextAlign.center,style: const TextStyle(
                          color: Color(0xFF202630),
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (zone == PeakFlowZone.unavailable) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      key: const ValueKey('set_personal_best_from_pef'),
                      onPressed: savingPersonalBest ? null : _enterPersonalBest,
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: savingPersonalBest
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.edit_outlined),
                      label: Text(
                        appText(
                          'Enter personal best here',
                          'أدخل أفضل قراءة من هنا',
                        ),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 9),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton.icon(
                    key: const ValueKey('open_action_plan_from_pef'),
                    onPressed: () {
                      final router = GoRouter.of(context);
                      Navigator.pop(context);
                      router.go('/action-plan');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      elevation: 7,
                      shadowColor: color.withValues(alpha: .30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Transform.flip(
                      flipX: AppState.instance.arabic,
                      child: const Icon(Icons.arrow_back, size: 23),
                    ),
                    label: Text(
                      appText('View full action plan', 'عرض خطة العمل الكاملة'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    appText('I understand / Close', 'فهمت/ إغلاق'),
                    style: const TextStyle(
                      color: Color(0xFF4B535D),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const computationLimits = MainAxisSize.min;