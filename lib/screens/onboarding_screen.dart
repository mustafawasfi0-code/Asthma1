import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_state.dart';
import '../core/onboarding_medication_state.dart';
import '../models/emergency_contact.dart';
import '../models/medication.dart';
import '../models/profile.dart';
import '../repositories/onboarding_repository.dart';
import '../repositories/profile_repository.dart';
import '../services/supabase_service.dart';
import '../widgets/common.dart';
import '../repositories/health_repository.dart'; // أو حسب المسار الخاص بالملف لديك

/// Single progress scale shared by every onboarding screen so the bar reads
/// as one continuous journey instead of resetting between sections.
///
/// Units: 4 profile steps (name, city, age/sex, height) + medications
/// selection + medication info (interpolated across however many medicines
/// were selected) + triggers + emergency contact = 7 total units.
const int _onboardingTotalSteps = 7;

double _onboardingProgress(int completedSteps, {double fraction = 0}) =>
    (completedSteps + fraction) / _onboardingTotalSteps;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int step = 0;
  bool loading = false;
  String? error;
  String? city;
  String? sex;

  final TextEditingController name = TextEditingController();
  final TextEditingController age = TextEditingController();
  final TextEditingController height = TextEditingController();

  final List<String> cities = const [
    'Baghdad',
    'Basra',
    'Mosul',
    'Erbil',
    'Kirkuk',
    'Najaf',
    'Karbala',
    'Sulaymaniyah',
    'Nasiriyah',
    'Amarah',
    'Hillah',
    'Diwaniyah',
    'Kut',
    'Dohuk',
    'Ramadi',
    'Baqubah',
    'Samawah',
  ];

  final Map<String, String> localizedCities = const {
    'Baghdad': 'بغداد',
    'Basra': 'البصرة',
    'Mosul': 'الموصل',
    'Erbil': 'أربيل',
    'Kirkuk': 'كركوك',
    'Najaf': 'النجف',
    'Karbala': 'كربلاء',
    'Sulaymaniyah': 'السليمانية',
    'Nasiriyah': 'الناصرية',
    'Amarah': 'العمارة',
    'Hillah': 'الحلة',
    'Diwaniyah': 'الديوانية',
    'Kut': 'الكوت',
    'Dohuk': 'دهوك',
    'Ramadi': 'الرمادي',
    'Baqubah': 'بعقوبة',
    'Samawah': 'السماوة',
  };

  final Map<String, String> localizedsex = const {
    'Male': 'ذكر',
    'Female': 'أنثى',
    'Other': 'آخر',
  };

  @override
  void dispose() {
    name.dispose();
    age.dispose();
    height.dispose();
    super.dispose();
  }

  int? _normalizedAge() {
    final value = int.tryParse(age.text.trim());
    if (value == null) return null;
    final currentYear = DateTime.now().year;
    if (value >= 1900 && value <= currentYear) return currentYear - value;
    return value;
  }

  int? _estimatedPef() {
    final parsedHeight = double.tryParse(height.text.trim());
    final normalizedAge = _normalizedAge();
    if (parsedHeight == null ||
        parsedHeight < 50 ||
        parsedHeight > 250 ||
        normalizedAge == null ||
        sex == null) {
      return null;
    }
    final value = sex == 'Female'
        ? parsedHeight * 3.72 + normalizedAge * 2.24 - 232
        : parsedHeight * 5.48 - normalizedAge * 1.93 - 367;
    return value.clamp(1, 1000).round();
  }

  void next() async {
    final a = AppState.instance.arabic;
    setState(() => error = null);

    if (step == 0 && name.text.trim().isEmpty) {
      setState(
        () => error = a ? 'يرجى إدخال اسمك' : 'Please enter your name',
      );
      return;
    }

    if (step == 1 && city == null) {
      setState(
        () => error = a ? 'يرجى اختيار مدينتك' : 'Please select your city',
      );
      return;
    }

    final normalizedAge = _normalizedAge();
    if (step == 2 &&
        (normalizedAge == null ||
            normalizedAge < 1 ||
            normalizedAge > 120 ||
            sex == null)) {
      setState(
        () => error = a
            ? 'أدخل عمراً صحيحاً بين 1 و120 واختر الجنس'
            : 'Enter a valid age from 1 to 120 and select sex',
      );
      return;
    }

    final parsedHeight = double.tryParse(height.text.trim());
    if (step == 3 &&
    (parsedHeight == null || parsedHeight < 50 || parsedHeight > 250)) {
      setState(
        () => error = a
            ? 'أدخل طولاً صحيحاً بين 50 و250 سم'
            : 'Enter a valid height from 50 to 250 cm',
      );
      return;
    }

    if (step < 3) {
      setState(() => step++);
      return;
    }
    setState(() => loading = true);
    try {
      await ProfileRepository().save(
        Profile(
          name: name.text.trim(),
          city: city!,
          age: normalizedAge!,
          sex: sex!,
          heightCm: parsedHeight!,
        ),
      );
      if (mounted) context.push('/onboarding/medications');
    } on FormatException {
      if (mounted) {
        setState(
          () => error = a
              ? 'تأكد من الاسم والعمر والطول ثم حاول مجدداً'
              : 'Check your name, age, and height, then try again',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = a
              ? 'تعذر حفظ البيانات. تحقق من الإنترنت وحاول مجدداً'
              : 'Could not save your data. Check the internet and try again',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = AppState.instance.arabic;
    final icons = const [
      Icons.favorite,
      Icons.location_on,
      Icons.person,
      Icons.straighten,
    ];
    final pages = [
      (
        a ? 'مرحباً بك في AsthmaCare' : 'Welcome to AsthmaCare',
        a
            ? 'لنقم بإعداد ملفك الشخصي لتخصيص خطة إدارة الربو الخاصة بك.'
            : "Let's set up your profile to personalize your asthma management plan.",
        _field(
          a ? 'بماذا نناديك؟' : 'What should we call you?',
          a ? 'أدخل اسمك' : 'Enter your name',
          name,
        ),
      ),
      (
        a ? 'الموقع' : 'Location',
        a
            ? 'نحتاج إلى معرفة مدينتك في العراق لتقديم تنبيهات دقيقة عن الطقس والعواصف الترابية.'
            : 'We need your city in Iraq to provide accurate weather and dust storm alerts.',
        DropdownButtonFormField<String>(
          initialValue: city,
          decoration: InputDecoration(
            labelText: a ? 'اختر مدينتك في العراق' : 'Select your city in Iraq',
          ),
          items: cities
              .map(
                (x) => DropdownMenuItem(
                  value: x,
                  child: Text(a ? localizedCities[x]! : x),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => city = v),
        ),
      ),
      (
        a ? 'معلومات عنك' : 'About You',
        a
            ? 'نحتاج إلى بعض التفاصيل الأساسية لحساب مؤشراتك الصحية.'
            : 'We need some basic details to calculate your health metrics.',
        Column(
          children: [
            _field(
              a ? 'العمر' : 'Age',
              a ? 'بالسنوات' : 'Years',
              age,
              number: true,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: sex,
              decoration: InputDecoration(labelText: a ? 'الجنس' : 'sex'),
              items: const ['Male', 'Female', 'Other']
                  .map(
                    (x) => DropdownMenuItem(
                      value: x,
                      child: Text(a ? localizedsex[x]! : x),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => sex = v),
            ),
          ],
        ),
      ),
      (
        a ? 'القياسات' : 'Measurements',
        a
            ? 'طولك مهم لحساب قيمة ذروة تدفق الهواء المتوقعة.'
            : 'Your height is important for calculating your predicted peak flow.',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(
              a ? 'الطول (سم)' : 'Height (cm)',
              a ? 'مثال: 175' : 'e.g., 175',
              height,
              number: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text(
              a
                  ? 'يُستخدم لحساب ذروة تدفق الزفير المتوقعة (PEF).'
                  : 'Used to calculate your predicted Peak Expiratory Flow (PEF).',
            ),
            const SizedBox(height: 12),
            _pefPreviewCard(a),
          ],
        ),
      ),
    ];

    final p = pages[step];
    return _OnboardingFrame(
      progress: _onboardingProgress(step + 1),
      icon: icons[step],
      title: p.$1,
      subtitle: p.$2,
      showBack: step > 0,
      back: () => setState(() => step--),
      continueAction: next,
      continueText: step == 3
          ? (a ? 'إكمال الإعداد' : 'Complete Setup')
          : (a ? 'متابعة' : 'Continue'),
      loading: loading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          p.$3,
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    String hint,
    TextEditingController c, {
    bool number = false,
    ValueChanged<String>? onChanged,
  }) =>
      TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : null,
        decoration: InputDecoration(labelText: label, hintText: hint),
        onChanged: onChanged,
      );

  Widget _pefPreviewCard(bool a) {
    final estimated = _estimatedPef();
    if (estimated == null) return const SizedBox.shrink();
    return AppCard(
      color: const Color(0xFFF0FDF4),
      child: Row(
        children: [
          const Icon(Icons.speed, color: Colors.green),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a ? 'ذروة التدفق المتوقعة' : 'Estimated Peak Flow',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$estimated L/min',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

bool isValidEmergencyPhone(String value) {
  final phone = value.replaceAll(RegExp(r'[ -]'), '');
  return RegExp(r'^07\d{9}$').hasMatch(phone) ||
      RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone);
}
class MedicationSelectionScreen extends StatefulWidget {
  const MedicationSelectionScreen({super.key});

  @override
  State<MedicationSelectionScreen> createState() =>
      _MedicationSelectionScreenState();
}

class _MedicationSelectionScreenState
    extends State<MedicationSelectionScreen> {
  final repository = OnboardingRepository();
  bool loading = true;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        repository.loadMedications(),
        repository.loadSelectedMedicationCodes(),
      ]);
      OnboardingMedicationState.instance
        ..setCatalog(results[0] as List<Medication>)
        ..setSelected(results[1] as Set<String>);
    } catch (e) {
      error = SupabaseService.readableError(e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _continue() async {
    if (saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await repository.saveSelectedMedicationCodes(
        OnboardingMedicationState.instance.selectedCodes,
      );
      if (!mounted) return;
      if (OnboardingMedicationState.instance.selectedCodes.isEmpty) {
  // 👈 قم بتغيير السطر الموجود هنا إلى:
  context.push('/onboarding/triggers'); 
} else {
  context.push('/onboarding/medications/info/0');
}
    } catch (e) {
      setState(() => error = SupabaseService.readableError(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = AppState.instance.arabic;
    return _OnboardingFrame(
      progress: _onboardingProgress(5),
      icon: Icons.medication_outlined,
      title: appText('Medications', 'الأدوية'),
      subtitle: appText(
        'Select the medicines you currently use to see suitable instructions.',
        'حدد الأدوية التي تستخدمها حالياً ليتم عرض التعليمات المناسبة.',
      ),
      back: () => context.pop(),
      continueAction: _continue,
      loading: saving,
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: OnboardingMedicationState.instance,
              builder: (context, _) => Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F6FF),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            appText(
                              '${OnboardingMedicationState.instance.selectedCodes.length} of ${OnboardingMedicationState.instance.medications.length} selected',
                              'تم اختيار ${OnboardingMedicationState.instance.selectedCodes.length} من ${OnboardingMedicationState.instance.medications.length}',
                            ),
                            style: const TextStyle(
                              color: Color(0xFF4F6599),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          key: const ValueKey('select_all_medications'),
                          onPressed: () {
                            final state = OnboardingMedicationState.instance;
                            state.allSelected
                                ? state.clearSelection()
                                : state.selectAll();
                          },
                          icon: Icon(
                            OnboardingMedicationState.instance.allSelected
                                ? Icons.remove_done
                                : Icons.done_all,
                          ),
                          label: Text(
                            OnboardingMedicationState.instance.allSelected
                                ? appText('Clear all', 'إلغاء الكل')
                                : appText('Select all', 'اختيار الكل'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...OnboardingMedicationState.instance.medications.map(
                    (medication) => _MedicationChoice(
                      medication: medication,
                      selected: OnboardingMedicationState.instance.selectedCodes
                          .contains(medication.code),
                      onTap: () => OnboardingMedicationState.instance.toggle(
                        medication.code,
                      ),
                    ),
                  ),
                  if (error != null) _ErrorText(error!),
                  Text(
                    a
                        ? 'يمكنك المتابعة بدون اختيار دواء.'
                        : 'You can continue without choosing a medication.',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MedicationChoice extends StatelessWidget {
  const _MedicationChoice({
    required this.medication,
    required this.selected,
    required this.onTap,
  });

  final Medication medication;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = AppState.instance.arabic;
    final colors = const [
      Color(0xFF0EA5E9),
      Color(0xFFD97706),
      Color(0xFFEF4444),
      Color(0xFFC026D3),
      Color(0xFF14B8A6),
    ];
    final color = colors[(medication.sortOrder - 1) % colors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected ? const Color(0xFFEFF6FF) : Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected ? const Color(0xFF1677F2) : const Color(0xFFE5E7EB),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(bottom: BorderSide(color: color, width: 4)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: medication.imagePath.isEmpty
                          ? Icon(
                              medication.isEmergency
                                  ? Icons.medication_liquid_outlined
                                  : Icons.medication_outlined,
                              color: color,
                              size: 31,
                              )
                          : Image.asset(
                              medication.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                medication.isEmergency
                                    ? Icons.medication_liquid_outlined
                                    : Icons.medication_outlined,
                                color: color,
                                size: 31,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a ? medication.nameAr : medication.nameEn,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        a
                            ? medication.descriptionAr
                            : medication.descriptionEn,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                Checkbox(value: selected, onChanged: (_) => onTap()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MedicationInfoScreen extends StatelessWidget {
  const MedicationInfoScreen({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final selected = OnboardingMedicationState.instance.selectedMedications;
    if (selected.isEmpty || index < 0 || index >= selected.length) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.go('/onboarding/triggers'),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final medication = selected[index];
    final a = AppState.instance.arabic;
    final warning = a ? medication.warningAr : medication.warningEn;
    final hasNext = index + 1 < selected.length;
    final nextMedication = hasNext ? selected[index + 1] : null;

    return _OnboardingFrame(
      progress: _onboardingProgress(5, fraction: (index + 1) / selected.length),
      icon: Icons.schedule_outlined,
      title:
          appText('Information about ', 'معلومات ') +
          (a ? medication.nameAr : medication.nameEn),
      subtitle: a ? medication.instructionsAr : medication.instructionsEn,
      back: () => index == 0
          ? context.pop()
          : context.go('/onboarding/medications/info/${index - 1}'),
      continueText: hasNext
          ? appText(
              'Next medicine (${index + 2} of ${selected.length})',
              'الدواء التالي (${index + 2} من ${selected.length})',
            )
          : appText('Continue', 'استمرار'),
      continueAction: () => hasNext
          ? context.go('/onboarding/medications/info/${index + 1}')
          : context.push('/onboarding/triggers'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selected.length > 1) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                appText(
                  'Medicine ${index + 1} of ${selected.length}',
                  'الدواء ${index + 1} من ${selected.length}',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF0969E8),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (warning != null && warning.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFE7A3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFB7791F)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medication.isEmergency
                              ? appText('Emergency medicine', 'علاج طارئ')
                              : appText(
                                  'Important instructions',
                                  'تعليمات مهمة',
                                ),
                          style: const TextStyle(
                            color: Color(0xFF925B10),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          warning,
                          style: const TextStyle(color: Color(0xFF925B10)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (nextMedication != null) ...[
            const SizedBox(height: 14),
            Text(
              appText(
                'Next: ${nextMedication.nameEn}',
                'التالي: ${nextMedication.nameAr}',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EmergencyContactScreen extends StatefulWidget {
  const EmergencyContactScreen({super.key, this.onboarding = true});
  final bool onboarding;

  @override
  State<EmergencyContactScreen> createState() =>
      _EmergencyContactScreenState();
}

class _EmergencyContactScreenState extends State<EmergencyContactScreen> {
  final repository = OnboardingRepository();
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();

  String relationship = 'Family';
  bool loading = true;
  bool saving = false;
  bool hasexisting = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final contact = await repository.loadEmergencyContact();
      if (contact != null) {
        name.text = contact.contactName;
        phone.text = contact.phoneNumber;
        relationship = contact.relationship;
        hasexisting = true;
      }
    } catch (_) {
      // A missing optional contact is shown as an empty form.
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _finish() async {
    if (widget.onboarding) {
      await AppState.instance.finishOnboarding();
      if (mounted) context.go('/');
    } else if (mounted) {
      context.pop();
    }
  }
  Future<void> _save() async {
    final a = AppState.instance.arabic;
    if (name.text.trim().isEmpty) {
      setState(
        () => error = a ? 'أدخل اسم جهة الاتصال' : 'Enter a contact name',
      );
      return;
    }
    if (!isValidEmergencyPhone(phone.text)) {
      setState(
        () => error = a
            ? 'أدخل رقماً عراقياً يبدأ بـ 07 ويتكون من 11 رقماً، أو رقماً دولياً يبدأ بـ +'
            : 'Enter an 11-digit Iraqi 07 number or an international + number',
      );
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await repository.saveEmergencyContact(
        EmergencyContact(
          contactName: name.text,
          relationship: relationship,
          phoneNumber: phone.text.replaceAll(RegExp(r'[ -]'), ''),
        ),
      );
      await _finish();
    } catch (e) {
      if (mounted) setState(() => error = SupabaseService.readableError(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => saving = true);
    try {
      await repository.deleteEmergencyContact();
      name.clear();
      phone.clear();
      hasexisting = false;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => error = SupabaseService.readableError(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _OnboardingFrame(
      progress: _onboardingProgress(7),
      icon: Icons.emergency_outlined,
      title: appText('Emergency Contact', 'جهة اتصال الطوارئ'),
      subtitle: appText(
        'Add someone we can help you call during an asthma emergency. This is optional.',
        'أضف شخصاً يمكن الاتصال به عند طوارئ الربو. هذه الخطوة اختيارية.',
      ),
      back: () => context.pop(),
      continueAction: _save,
      continueText: appText('Save and continue', 'حفظ ومتابعة'),
      loading: saving,
      secondaryAction: _finish,
      secondaryText: appText('Skip', 'تخطي'),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: appText('Contact name', 'اسم جهة الاتصال'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: relationship,
                  decoration: InputDecoration(
                    labelText: appText('Relationship', 'صلة القرابة'),
                    prefixIcon: const Icon(Icons.people_outline),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Family',
                      child: Text('Family / العائلة'),
                    ),
                    DropdownMenuItem(
                      value: 'Friend',
                      child: Text('Friend / صديق'),
                    ),
                    DropdownMenuItem(
                      value: 'Doctor',
                      child: Text('Doctor / طبيب'),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text('Other / أخرى'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => relationship = value ?? 'Other'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: appText('Phone number', 'رقم الهاتف'),
                    hintText: '07XXXXXXXXX / +964...',
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                if (error != null) _ErrorText(error!),
                if (!widget.onboarding && hasexisting)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: OutlinedButton.icon(
                      onPressed: saving ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(
                        appText('Delete contact', 'حذف جهة الاتصال'),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _OnboardingFrame extends StatelessWidget {
  const _OnboardingFrame({
    required this.progress,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.back,
    required this.continueAction,
    required this.child,
    this.continueText,
    this.loading = false,
    this.secondaryAction,
    this.secondaryText,
    this.showBack = true,
  });

  final double progress;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback back;
  final VoidCallback continueAction;
  final Widget child;
  final String? continueText;
  final bool loading;
  final VoidCallback? secondaryAction;
  final String? secondaryText;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final a = AppState.instance.arabic;
    return Directionality(
      textDirection: a ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: Column(
                      children: [
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: AppState.instance.toggleLanguage,
                            icon: const Icon(Icons.language, size: 18),
                            label: Text(a ? 'English' : 'العربية'),
                          ),
                        ),
                        LinearProgressIndicator(
                          value: progress.clamp(0, 1),
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F6FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                icon,
                                size: 39,
                                color: const Color(0xFF0969E8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.55,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 28),
                          child,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            text: loading
                                ? appText('Saving...', 'جارٍ الحفظ...')
                                : (continueText ??
                                      appText('Continue', 'استمرار')),
                            onPressed: loading ? null : continueAction,
                            icon: Icons.arrow_forward_ios,
                          ),
                        ),
                        if (showBack || secondaryAction != null) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: loading
                                  ? null
                                  : (secondaryAction ?? back),
                              child: secondaryAction == null
                                  ? const Icon(Icons.arrow_back_ios_new)
                                  : Text(
                                      secondaryText ?? appText('Skip', 'تخطي'),
                                    ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.value);
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(value, style: const TextStyle(color: Colors.red)),
      );
}
class TriggerItem {
  final String id;
  final String nameEn;
  final String nameAr;
  final IconData icon;

  const TriggerItem({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
  });
}

class TriggersScreen extends StatefulWidget {
  const TriggersScreen({super.key});

  @override
  State<TriggersScreen> createState() => _TriggersScreenState();
}

class _TriggersScreenState extends State<TriggersScreen> {
  final Set<String> selectedTriggers = {};
  final TextEditingController _customController = TextEditingController();
  bool saving = false;

  final List<TriggerItem> triggersList = const [
    TriggerItem(
      id: 'dust',
      nameEn: 'Dust & Sandstorms',
      nameAr: 'الغبار والعواصف الترابية',
      icon: Icons.air,
    ),
    TriggerItem(
      id: 'smoke',
      nameEn: 'Smoke & Tobacco',
      nameAr: 'الدخان والتدخين',
      icon: Icons.smoking_rooms,
    ),
    TriggerItem(
      id: 'exercise',
      nameEn: 'Exercise & Effort',
      nameAr: 'الجهد البدني والرياضة',
      icon: Icons.fitness_center,
    ),
    TriggerItem(
      id: 'cold_air',
      nameEn: 'Cold Air',
      nameAr: 'الهواء البارد والتغير الجوي',
      icon: Icons.ac_unit,
    ),
    TriggerItem(
      id: 'perfumes',
      nameEn: 'Strong Scents',
      nameAr: 'العطور والروائح القوية',
      icon: Icons.sanitizer,
    ),
    TriggerItem(
      id: 'pets',
      nameEn: 'Pets',
      nameAr: 'الحيوانات الأليفة',
      icon: Icons.pets,
    ),
    TriggerItem(
      id: 'pollen',
      nameEn: 'Pollen',
      nameAr: 'حبوب اللقاح والنباتات',
      icon: Icons.yard,
    ),
    TriggerItem(
      id: 'stress',
      nameEn: 'Stress & Emotions',
      nameAr: 'التوتر والمشاعر القوية',
      icon: Icons.psychology,
    ),
  ];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (selectedTriggers.contains(id)) {
        selectedTriggers.remove(id);
      } else {
        selectedTriggers.add(id);
      }
    });
  }

  Future<void> _continue() async {
  setState(() => saving = true);
  try {
    final customText = _customController.text.trim();
    if (customText.isNotEmpty) {
      selectedTriggers.add(customText);
    }

    // تحويل الـ IDs المختارة إلى أسمائها النصية لتتوافق مع MonitoringScreen
    final List<String> formattedTriggers = selectedTriggers.map((id) {
      final found = triggersList.where((item) => item.id == id);
      if (found.isNotEmpty) {
        // يحفظ الاسم العربي أو الإنجليزي ليظهر مباشرة في الشاشة
        return AppState.instance.arabic ? found.first.nameAr : found.first.nameEn;
      }
      return id; // إذا كان نصاً مخصصاً أُضيف من حقل TextField
    }).toList();

    if (formattedTriggers.isNotEmpty) {
      await HealthRepository().addTriggersLog(
        triggers: formattedTriggers,
      );
    }

    if (mounted) context.push('/onboarding/emergency-contact');
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appText('Failed to save triggers', 'فشل حفظ المثيرات'))),
      );
    }
  } finally {
    if (mounted) setState(() => saving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final a = AppState.instance.arabic;
    return _OnboardingFrame(
      progress: _onboardingProgress(6),
      icon: Icons.warning_amber_rounded,
      title: appText('Asthma Triggers', 'مثيرات الربو'),
      subtitle: appText(
        'Select the triggers that usually excite or worsen your asthma symptoms.',
        'حدد العوامل والمثيرات التي تحفّز نوبات أو أعراض الربو لديك عادةً.',
      ),
      back: () => context.pop(),
      continueAction: _continue,
      loading: saving,
      continueText: appText('Continue', 'متابعة'),
      secondaryAction: () => context.push('/onboarding/emergency-contact'),
      secondaryText: appText('Skip', 'تخطي'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemCount: triggersList.length,
            itemBuilder: (context, index) {
              final item = triggersList[index];
              final isSelected = selectedTriggers.contains(item.id);
              return Material(
                color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF1677F2)
                        : const Color(0xFFE5E7EB),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => _toggle(item.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.icon,
                          size: 30,
                          color: isSelected
                              ? const Color(0xFF1677F2)
                              : const Color(0xFF6B7280),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a ? item.nameAr : item.nameEn,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF1677F2)
                                : const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // 👈 حقل المثير الآخَر
          TextField(
            controller: _customController,
            decoration: InputDecoration(
              hintText: a ? 'أضف مثيراً آخر' : 'Add another trigger',
              prefixIcon: const Icon(Icons.add, color: Color(0xFF6B7280)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1677F2), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}