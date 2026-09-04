import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../core/localized_values.dart';
import '../models/profile.dart';
import '../repositories/health_repository.dart';
import '../repositories/community_repository.dart';
import '../repositories/profile_repository.dart';
import '../services/supabase_service.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final repository = ProfileRepository();
  final doctorName = TextEditingController();
  final doctorPhone = TextEditingController();
  final personalBest = TextEditingController();
  Profile? profile;
  bool loading = true, saving = false;
  String? error;
  String originalDoctorName = '';
  String lastPresentedDoctorName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    doctorName.dispose();
    doctorPhone.dispose();
    personalBest.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final value = await repository.getCurrent();
      if (value != null) {
        originalDoctorName = value.doctorName ?? '';
        lastPresentedDoctorName = localizedPersonName(originalDoctorName);
        doctorName.text = lastPresentedDoctorName;
        doctorPhone.text = value.doctorPhone ?? '';
        personalBest.text = value.personalBest?.toString() ?? '';
      }
      if (mounted) setState(() => profile = value);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = appText(
            'Could not load your profile.',
            'تعذر تحميل ملفك الشخصي.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (doctorName.text == lastPresentedDoctorName) {
      lastPresentedDoctorName = localizedPersonName(originalDoctorName);
      doctorName.text = lastPresentedDoctorName;
    }
  }

  int? get predictedPef {
    final p = profile;
    if (p == null) return null;
    final value = p.sex == 'Female'
        ? p.heightCm * 3.72 + p.age * 2.24 - 232
        : p.heightCm * 5.48 - p.age * 1.93 - 367;
    return value.clamp(1, 1000).round();
  }

  String shown(Object? value) =>
      value == null || value.toString().trim().isEmpty
      ? appText('Not set', 'غير محدد')
      : value.toString();

  Future<void> _save(BuildContext context) async {
    final current = profile;
    if (current == null || saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final personalBestValue = personalBest.text.trim().isEmpty
          ? null
          : int.tryParse(personalBest.text.trim());
      if (personalBestValue == null && personalBest.text.trim().isNotEmpty ||
          personalBestValue != null &&
              (personalBestValue < 1 || personalBestValue > 1000)) {
        throw const FormatException('Invalid personal best');
      }
      final updated = Profile(
        id: current.id,
        name: current.name,
        city: current.city,
        age: current.age,
        sex: current.sex,
        heightCm: current.heightCm,
        personalBest: personalBestValue,
        doctorName: doctorName.text.trim().isEmpty
            ? null
            : doctorName.text.trim() == lastPresentedDoctorName
            ? originalDoctorName
            : doctorName.text.trim(),
        doctorPhone: doctorPhone.text.trim().isEmpty
            ? null
            : doctorPhone.text.trim(),
      );
      await repository.save(updated);
      if (!context.mounted) return;
      setState(() => profile = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appText('Profile updated', 'تم تحديث الملف الشخصي')),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => error = appText(
            'Could not save your profile.',
            'تعذر حفظ الملف الشخصي.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext c) => PageFrame(
    title: appText('Profile', 'الملف الشخصي'),
    subtitle: appText(
      'Manage your health information',
      'إدارة معلوماتك الصحية',
    ),
    child: loading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(50),
              child: CircularProgressIndicator(),
            ),
          )
        : Column(
            children: [
              const CircleAvatar(
                radius: 48,
                backgroundColor: Color(0xFFDBEAFE),
                child: Icon(Icons.person, size: 52, color: AppColors.blue),
              ),
              const SizedBox(height: 10),
              Text(
                profile?.name == null
                    ? appText('Set your name', 'أدخل اسمك')
                    : localizedPersonName(profile!.name),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                profile == null
                    ? appText('Not set', 'غير محدد')
                    : '${localizedCity(profile!.city)} • ${profile!.age} ${appText('years', 'سنة')}',
              ),
              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.speed, color: Colors.green),
                      title: Text(appText('Personal Best', 'أفضل قراءة شخصية')),
                      trailing: SizedBox(
                        width: 115,
                        child: TextField(
                          key: const ValueKey('personal_best_field'),
                          controller: personalBest,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: appText('Enter value', 'أدخل الرقم'),
                            suffixText: 'L/min',
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.analytics_outlined,
                        color: Colors.blue,
                      ),
                      title: Text(
                        appText('Predicted PEF', 'ذروة التدفق المتوقعة'),
                      ),
                      trailing: Text(shown(predictedPef)),
                    ),
                  ],
                ),
              ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appText('Healthcare Provider', 'مقدم الرعاية الصحية'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: doctorName,
                      decoration: InputDecoration(
                        labelText: appText("Doctor's Name", 'اسم الطبيب'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: doctorPhone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: appText("Doctor's Phone", 'هاتف الطبيب'),
                      ),
                    ),
                  ],
                ),
              ),
              AppCard(
                onTap: () => c.push('/profile/emergency-contact'),
                child: ListTile(
                  leading: const Icon(
                    Icons.emergency_outlined,
                    color: Colors.red,
                  ),
                  title: Text(
                    appText('Emergency Contact', 'جهة اتصال الطوارئ'),
                  ),
                  subtitle: Text(
                    appText(
                      'Add or edit your emergency contact',
                      'إضافة أو تعديل جهة اتصال الطوارئ',
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              PrimaryButton(
                text: saving
                    ? appText('Saving...', 'جارٍ الحفظ...')
                    : appText('Save Profile', 'حفظ الملف الشخصي'),
                onPressed: saving ? null : () => _save(c),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => c.go('/report'),
                icon: const Icon(Icons.description_outlined),
                label: Text(appText('Doctor Report', 'تقرير الطبيب')),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                key: const ValueKey('profile_logout_button'),
                onPressed: () => _confirmLogout(c),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(
                  appText('Logout', 'تسجيل الخروج'),
                  style: const TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ),
  );

  Future<void> _confirmLogout(BuildContext context) async {
    final a = AppState.instance.arabic;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(a ? 'تسجيل الخروج' : 'Log out'),
        content: Text(
          a
              ? 'هل تريد تسجيل الخروج من حسابك؟'
              : 'Are you sure you want to log out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(a ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(a ? 'تسجيل الخروج' : 'Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AppState.instance.signOut();
    if (context.mounted) context.go('/auth');
  }
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final repository = CommunityRepository();
  final body = TextEditingController();
  List<Map<String, dynamic>> posts = const [];
  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final values = await repository.loadPosts();
      if (mounted) setState(() => posts = values);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error = appText('Could not load posts.', 'تعذر تحميل المنشورات.'),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submit() async {
    if (saving || body.text.trim().isEmpty) return;
    setState(() => saving = true);
    try {
      await repository.addPost(body.text);
      body.clear();
      await _load();
    } catch (_) {
      _message(appText('Could not publish the post.', 'تعذر نشر المنشور.'));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _edit(Map<String, dynamic> row) async {
    final controller = TextEditingController(
      text: row['body']?.toString() ?? '',
    );
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(appText('Edit post', 'تعديل المنشور')),
        content: TextField(
          controller: controller,
          maxLength: 2000,
          maxLines: 5,
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
    if (accepted == true && controller.text.trim().isNotEmpty) {
      try {
        await repository.updatePost(row['id'].toString(), controller.text);
        await _load();
      } catch (_) {
        _message(appText('Could not update the post.', 'تعذر تعديل المنشور.'));
      }
    }
    controller.dispose();
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    try {
      await repository.deletePost(row['id'].toString());
      await _load();
    } catch (_) {
      _message(appText('Could not delete the post.', 'تعذر حذف المنشور.'));
    }
  }

  void _message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
    }
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final userId = SupabaseService.client?.auth.currentUser?.id;
    return PageFrame(
      title: appText('Asthma Community', 'مجتمع الربو'),
      subtitle: appText('Share experiences safely', 'شارك التجارب بأمان'),
      showNav: false,
      child: Column(
        children: [
          AppCard(
            child: Column(
              children: [
                TextField(
                  key: const ValueKey('community_post_field'),
                  controller: body,
                  maxLength: 2000,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: appText('Write a post…', 'اكتب منشوراً…'),
                  ),
                ),
                PrimaryButton(
                  text: saving
                      ? appText('Publishing…', 'جارٍ النشر…')
                      : appText('Publish', 'نشر'),
                  icon: Icons.send,
                  onPressed: saving ? null : _submit,
                ),
              ],
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
                  TextButton(
                    onPressed: _load,
                    child: Text(appText('Retry', 'إعادة المحاولة')),
                  ),
                ],
              ),
            )
          else if (posts.isEmpty)
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(appText('No posts yet', 'لا توجد منشورات بعد')),
              ),
            )
          else
            ...posts.map((row) {
              final mine = row['user_id']?.toString() == userId;
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.person_outline)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            mine
                                ? appText('You', 'أنت')
                                : appText('Community member', 'عضو في المجتمع'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          _date(row['created_at']),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(row['body']?.toString() ?? ''),
                    if (mine)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => _edit(row),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => _delete(row),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});
  @override
  Widget build(BuildContext c) => PageFrame(
    title: appText('Doctor Report', 'تقرير الطبيب'),
    subtitle: '',
    showNav: false,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: ListTile(
            title: Text(
              appText('Patient Name', 'اسم المريض'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            subtitle: Text(appText('Age: — | sex: —', 'العمر: — | الجنس: —')),
            trailing: Icon(Icons.print, color: AppColors.blue),
          ),
        ),
        SectionTitle(appText('Action Plan Summary', 'ملخص خطة التعامل')),
        Row(
          children: [
            Expanded(
              child: AppCard(
                color: Color(0xFFF0FDF4),
                child: Text(
                  'Green Zone\nPEF >80%',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: AppCard(
                color: Color(0xFFFFFBEB),
                child: Text(
                  'Yellow Zone\nPEF 50–80%',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: AppCard(
                color: Color(0xFFFEF2F2),
                child: Text('Red Zone\nPEF <50%', textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
        SectionTitle(
          appText('Peak Flow Logs (Last 20)', 'سجلات ذروة التدفق (آخر 20)'),
        ),
        AppCard(
          child: Center(
            child: Text(appText('No records found.', 'لا توجد سجلات')),
          ),
        ),
        SectionTitle(appText('Symptom Logs', 'سجلات الأعراض')),
        AppCard(
          child: Center(
            child: Text(appText('No records found.', 'لا توجد سجلات')),
          ),
        ),
        SectionTitle(appText('Medication Logs', 'سجلات الأدوية')),
        AppCard(
          child: Center(
            child: Text(appText('No records found.', 'لا توجد سجلات')),
          ),
        ),
        SizedBox(height: 24),
        Text(
          appText(
            'Generated by Asthma Management App. Data is patient-reported and does not constitute a medical diagnosis.',
            'تم إنشاء التقرير بواسطة تطبيق إدارة الربو. البيانات مقدمة من المريض ولا تمثل تشخيصاً طبياً',
          ),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    ),
  );
}

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final medication = TextEditingController();
  final dosage = TextEditingController();
  final notes = TextEditingController();
  final repository = HealthRepository();
  bool saving = false;

  @override
  void dispose() {
    medication.dispose();
    dosage.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await repository.addMedication(
        medication.text,
        dosage.text,
        notes.text.trim().isEmpty ? null : notes.text,
      );
      medication.clear();
      dosage.clear();
      notes.clear();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appText('Medication saved', '?? ??? ??????'))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(SupabaseService.readableError(e))));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: appText('Medications', 'الأدوية'),
    subtitle: appText(
      'Record your medication and dosage',
      'سجّل الدواء والجرعة',
    ),
    child: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appText('Add Medication', 'إضافة دواء'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          TextField(
            controller: medication,
            decoration: InputDecoration(
              labelText: appText('Medication name', 'اسم الدواء'),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: dosage,
            decoration: InputDecoration(labelText: appText('Dosage', 'الجرعة')),
          ),
          SizedBox(height: 12),
          TextField(
            controller: notes,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: appText('Notes (optional)', 'ملاحظات (اختياري)'),
            ),
          ),
          SizedBox(height: 16),
          PrimaryButton(
            text: saving
                ? appText('Saving…', 'جارٍ الحفظ…')
                : appText('Save Medication', 'حفظ الدواء'),
            onPressed: saving ? null : () => _save(context),
          ),
        ],
      ),
    ),
  );
}
