import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../models/medication.dart';
import '../repositories/home_repository.dart';
import '../repositories/reminder_repository.dart';
import '../services/notification_service.dart';
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

  Future<void> _load({bool silent = false}) async {
    if (mounted && !silent) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final values = await repository.loadAll();
      try {
        await NotificationService.syncReminders(values);
      } catch (_) {}
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
      await _load(silent: true);
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
      await _load(silent: true);
    } catch (_) {
      _message(appText('Could not update reminder.', 'تعذر تحديث التذكير.'));
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    try {
      await repository.delete(row['id'].toString());
      await _load(silent: true);
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

  List<Map<String, dynamic>> get _sorted {
    final list = [...reminders];
    list.sort(
      (a, b) => _time(a['time_of_day']).compareTo(_time(b['time_of_day'])),
    );
    return list;
  }

  /// "17:05:00" -> ("5:05", "PM")
  (String, String) _clock(dynamic value) {
    final parts = value?.toString().split(':') ?? const [];
    if (parts.length < 2) return ('--:--', '');
    final h = int.tryParse(parts[0]) ?? 0;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return ('$h12:${parts[1]}', h < 12 ? appText('AM', 'ص') : appText('PM', 'م'));
  }

  Widget _summary() {
    final active = reminders.where((r) => r['enabled'] == true).length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.mint,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appText('Daily reminders', 'التذكيرات اليومية'),
                  style: const TextStyle(
                    color: AppColors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appText(
                    '$active of ${reminders.length} active',
                    '$active من ${reminders.length} مفعّل',
                  ),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(Map<String, dynamic> row) {
    final on = row['enabled'] == true;
    final (hm, suffix) = _clock(row['time_of_day']);
    return AppCard(
      onTap: () => _edit(row),
      child: Row(
        children: [
          Opacity(
            opacity: on ? 1 : .5,
            child: Container(
              width: 82,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: on ? AppColors.softGreen : AppColors.grey,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  children: [
                    Text(
                      hm,
                      style: TextStyle(
                        color: on ? AppColors.green : AppColors.darkGreen,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      suffix,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Opacity(
              opacity: on ? 1 : .5,
              child: Text(
                row['title']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Switch(value: on, onChanged: (value) => _toggle(row, value)),
          PopupMenuButton<String>(
            tooltip: '',
            icon: const Icon(Icons.more_vert, color: AppColors.muted),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) =>
                value == 'edit' ? _edit(row) : _delete(row),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 20),
                    const SizedBox(width: 10),
                    Text(appText('Edit', 'تعديل')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      appText('Delete', 'حذف'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => AppCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.softOcean,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.green,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            appText('No reminders yet', 'لا توجد تذكيرات بعد'),
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            appText(
              'Add a reminder so you never miss your medicine or daily check.',
              'أضف تذكيراً حتى لا تنسى دواءك أو فحصك اليومي.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PageFrame(
    title: appText('Reminders', 'التذكيرات'),
    subtitle: appText('Manage daily reminders', 'إدارة التذكيرات اليومية'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loading)
          const Padding(
            padding: EdgeInsets.all(60),
            child: Center(child: CircularProgressIndicator()),
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
        else ...[
          if (reminders.isNotEmpty) ...[
            _summary(),
            const SizedBox(height: 14),
          ],
          PrimaryButton(
            key: const ValueKey('add_reminder'),
            text: appText('Add reminder', 'إضافة تذكير'),
            icon: Icons.add,
            onPressed: saving ? null : () => _edit(),
          ),
          const SizedBox(height: 18),
          if (reminders.isEmpty)
            _emptyState()
          else
            ..._sorted.map(_tile),
        ],
      ],
    ),
  );
}