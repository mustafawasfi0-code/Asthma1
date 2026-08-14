import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../models/medication.dart';
import '../repositories/home_repository.dart';
import '../repositories/reminder_repository.dart';
import '../widgets/common.dart';

class MedicationDetailsScreen extends StatefulWidget {
  const MedicationDetailsScreen({super.key, required this.code});
  final String code;

  @override
  State<MedicationDetailsScreen> createState() =>
      _MedicationDetailsScreenState();
}

class _MedicationDetailsScreenState extends State<MedicationDetailsScreen> {
  Medication? medication;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final home = await HomeRepository().load();
      medication = home.medications
          .where((item) => item.code == widget.code)
          .firstOrNull;
      medication ??= medicationCatalog
          .where((item) => item.code == widget.code)
          .firstOrNull;
    } catch (_) {
      medication = medicationCatalog
          .where((item) => item.code == widget.code)
          .firstOrNull;
      if (medication == null) {
        error = appText(
          'Could not load medication details.',
          'تعذر تحميل معلومات الدواء.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = medication;
    final arabic = AppState.instance.arabic;
    return PageFrame(
      title: appText('Medication information', 'معلومات الدواء'),
      subtitle: '',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : item == null
          ? AppCard(
              child: Center(
                child: Text(
                  error ?? appText('Medication not found', 'الدواء غير موجود'),
                ),
              ),
            )
          : Column(
              children: [
                AppCard(
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4FF),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.medication_outlined,
                          color: Color(0xFF0787F7),
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        arabic ? item.nameAr : item.nameEn,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        arabic ? item.descriptionAr : item.descriptionEn,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.isEmergency
                            ? appText('Emergency medicine', 'علاج طارئ')
                            : appText('Preventer medicine', 'دواء وقائي'),
                        style: const TextStyle(
                          color: Color(0xFF0787F7),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(arabic ? item.instructionsAr : item.instructionsEn),
                      if ((arabic ? item.warningAr : item.warningEn)
                          case final warning?) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7E6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            warning,
                            style: const TextStyle(color: Color(0xFF92400E)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final repository = ReminderRepository();
  List<Map<String, dynamic>> reminders = const [];
  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final values = await repository.loadAll();
      if (mounted) setState(() => reminders = values);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = appText(
            'Could not load reminders.',
            'تعذر تحميل التذكيرات.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _time(dynamic value) {
    final parts = value?.toString().split(':') ?? const [];
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : '--:--';
  }

  Future<void> _edit([Map<String, dynamic>? row]) async {
    final title = TextEditingController(text: row?['title']?.toString() ?? '');
    final rawTime = _time(row?['time_of_day']);
    final parts = rawTime.split(':');
    var selected = parts.length == 2 && int.tryParse(parts[0]) != null
        ? TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]))
        : TimeOfDay.now();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            row == null
                ? appText('New reminder', 'تذكير جديد')
                : appText('Edit reminder', 'تعديل التذكير'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: appText('Title', 'العنوان'),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(selected.format(dialogContext)),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: dialogContext,
                      initialTime: selected,
                    );
                    if (picked != null) setDialogState(() => selected = picked);
                  },
                  child: Text(appText('Choose time', 'اختيار الوقت')),
                ),
              ),
            ],
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
      ),
    );
    if (accepted != true || saving) {
      title.dispose();
      return;
    }
    if (title.text.trim().isEmpty) {
      title.dispose();
      _message(appText('Enter a reminder title.', 'أدخل عنوان التذكير.'));
      return;
    }
    setState(() => saving = true);
    final value =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}:00';
    try {
      if (row == null) {
        await repository.add(title: title.text, time: value);
      } else {
        await repository.update(
          row['id'].toString(),
          title: title.text,
          time: value,
        );
      }
      await _load();
    } catch (_) {
      _message(
        appText(
          'Could not save. A duplicate reminder may already exist.',
          'تعذر الحفظ. قد يوجد تذكير مطابق مسبقاً.',
        ),
      );
    } finally {
      title.dispose();
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _toggle(Map<String, dynamic> row, bool value) async {
    try {
      await repository.setEnabled(row['id'].toString(), value);
      await _load();
    } catch (_) {
      _message(appText('Could not update reminder.', 'تعذر تحديث التذكير.'));
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    try {
      await repository.delete(row['id'].toString());
      await _load();
    } catch (_) {
      _message(appText('Could not delete reminder.', 'تعذر حذف التذكير.'));
    }
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: appText('Reminders', 'التذكيرات'),
    subtitle: appText('Manage daily reminders', 'إدارة التذكيرات اليومية'),
    child: Column(
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton.icon(
            key: const ValueKey('add_reminder'),
            onPressed: saving ? null : _edit,
            icon: const Icon(Icons.add),
            label: Text(appText('Add reminder', 'إضافة تذكير')),
          ),
        ),
        const SizedBox(height: 12),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          )
        else if (error != null)
          AppCard(
            child: Column(
              children: [
                Text(error!),
                TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: Text(appText('Retry', 'إعادة المحاولة')),
                ),
              ],
            ),
          )
        else if (reminders.isEmpty)
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(appText('No reminders yet', 'لا توجد تذكيرات بعد')),
            ),
          )
        else
          ...reminders.map(
            (row) => AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Switch(
                  value: row['enabled'] == true,
                  onChanged: (value) => _toggle(row, value),
                ),
                title: Text(
                  row['title']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(_time(row['time_of_day'])),
                ),
                trailing: Wrap(
                  spacing: 2,
                  children: [
                    IconButton(
                      tooltip: appText('Edit', 'تعديل'),
                      onPressed: () => _edit(row),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: appText('Delete', 'حذف'),
                      onPressed: () => _delete(row),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
