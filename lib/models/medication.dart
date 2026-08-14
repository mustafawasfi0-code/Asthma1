class Medication {
  const Medication({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.medicationType,
    required this.instructionsAr,
    required this.instructionsEn,
    this.warningAr,
    this.warningEn,
    required this.imagePath,
    required this.sortOrder,
  });

  final String code;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String medicationType;
  final String instructionsAr;
  final String instructionsEn;
  final String? warningAr;
  final String? warningEn;
  final String imagePath;
  final int sortOrder;

  bool get isEmergency => medicationType == 'emergency';

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    code: json['code'] as String,
    nameAr: json['name_ar'] as String,
    nameEn: (json['name_en'] as String?) ?? json['name_ar'] as String,
    descriptionAr: json['description_ar'] as String,
    descriptionEn:
        (json['description_en'] as String?) ?? json['description_ar'] as String,
    medicationType: json['medication_type'] as String,
    instructionsAr: json['instructions_ar'] as String,
    instructionsEn:
        (json['instructions_en'] as String?) ??
        json['instructions_ar'] as String,
    warningAr: json['warning_ar'] as String?,
    warningEn: json['warning_en'] as String?,
    imagePath: (json['image_path'] as String?) ?? '',
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  );
}

const medicationCatalog = <Medication>[
  Medication(
    code: 'ventolin',
    nameAr: 'فينتولين / بوتالين / سامالير',
    nameEn: 'Ventolin / Butalin / Samaler',
    descriptionAr: 'بخاخ منقذ (أزرق)',
    descriptionEn: 'Rescue inhaler (blue)',
    medicationType: 'emergency',
    instructionsAr: 'يستخدم هذا الدواء عند الحاجة فقط.',
    instructionsEn: 'Use this medicine only when needed.',
    warningAr:
        'لا يوجد جدول زمني ثابت لهذا الدواء. يُستخدم عند الشعور بالأعراض أو قبل ممارسة الرياضة حسب تعليمات الطبيب.',
    warningEn:
        'There is no fixed schedule. Use it when symptoms occur or before exercise as directed by your doctor.',
    imagePath: 'assets/images/medications/ventolin.png',
    sortOrder: 1,
  ),
  Medication(
    code: 'clenil',
    nameAr: 'كلينيل / بيكلوميثازون',
    nameEn: 'Clenil / Beclometasone',
    descriptionAr: 'بخاخ وقائي (بني)',
    descriptionEn: 'Preventer inhaler (brown)',
    medicationType: 'preventer',
    instructionsAr:
        'يُستخدم يومياً حسب وصف الطبيب للسيطرة على التهاب مجاري التنفس.',
    instructionsEn: 'Use daily as prescribed to control airway inflammation.',
    warningAr: 'تمضمض بعد الاستخدام ولا توقفه دون استشارة الطبيب.',
    warningEn:
        'Rinse your mouth after use and do not stop without medical advice.',
    imagePath: 'assets/images/medications/clenil.png',
    sortOrder: 2,
  ),
  Medication(
    code: 'symbicort',
    nameAr: 'سيمبيكورت تيربوهيلر',
    nameEn: 'Symbicort Turbuhaler',
    descriptionAr: 'مسحوق جاف (أبيض/أحمر)',
    descriptionEn: 'Dry powder inhaler (white/red)',
    medicationType: 'preventer',
    instructionsAr: 'استخدم الجرعة الموصوفة بانتظام وبطريقة الاستنشاق الصحيحة.',
    instructionsEn:
        'Use the prescribed dose regularly with correct inhalation technique.',
    warningAr: 'تمضمض بعد كل جرعة.',
    warningEn: 'Rinse your mouth after each dose.',
    imagePath: 'assets/images/medications/symbicort.png',
    sortOrder: 3,
  ),
  Medication(
    code: 'seretide',
    nameAr: 'سيريتايد ديسكاس',
    nameEn: 'Seretide Diskus',
    descriptionAr: 'مسحوق جاف (أرجواني)',
    descriptionEn: 'Dry powder inhaler (purple)',
    medicationType: 'preventer',
    instructionsAr: 'يُستخدم بانتظام صباحاً ومساءً حسب الخطة العلاجية.',
    instructionsEn: 'Use regularly morning and evening according to your plan.',
    warningAr: 'ليس بديلاً عن بخاخ الإنقاذ أثناء النوبة الحادة.',
    warningEn: 'It does not replace a rescue inhaler during an acute attack.',
    imagePath: 'assets/images/medications/seretide.png',
    sortOrder: 4,
  ),
  Medication(
    code: 'foster',
    nameAr: 'فوستر / فوستير',
    nameEn: 'Foster / Fostair',
    descriptionAr: 'بخاخ مركب',
    descriptionEn: 'Combination inhaler',
    medicationType: 'preventer',
    instructionsAr: 'استخدمه حسب الجدول الذي حدده الطبيب.',
    instructionsEn: 'Use according to the schedule set by your doctor.',
    warningAr: 'لا تغيّر الجرعة دون مراجعة الطبيب.',
    warningEn: 'Do not change the dose without consulting your doctor.',
    imagePath: 'assets/images/medications/foster.png',
    sortOrder: 5,
  ),
  Medication(
    code: 'montelukast',
    nameAr: 'مونتيلوكاست',
    nameEn: 'Montelukast',
    descriptionAr: 'أقراص وقائية',
    descriptionEn: 'Preventer tablets',
    medicationType: 'preventer',
    instructionsAr: 'يؤخذ مرة يومياً حسب وصف الطبيب.',
    instructionsEn: 'Take once daily as prescribed.',
    warningAr: 'أبلغ الطبيب عند ظهور تغيرات غير معتادة في المزاج أو النوم.',
    warningEn: 'Tell your doctor about unusual mood or sleep changes.',
    imagePath: 'assets/images/medications/montelukast.png',
    sortOrder: 6,
  ),
  Medication(
    code: 'prednisolone',
    nameAr: 'بريدنيزولون',
    nameEn: 'Prednisolone',
    descriptionAr: 'أقراص للحالات الحادة',
    descriptionEn: 'Tablets for acute flare-ups',
    medicationType: 'emergency',
    instructionsAr: 'يُستخدم فقط للمدة والجرعة التي يحددها الطبيب.',
    instructionsEn:
        'Use only for the dose and duration prescribed by your doctor.',
    warningAr: 'لا تبدأه أو توقفه من نفسك.',
    warningEn: 'Do not start or stop it without medical advice.',
    imagePath: 'assets/images/medications/prednisolone.png',
    sortOrder: 7,
  ),
  Medication(
    code: 'ipratropium',
    nameAr: 'إبراتروبيوم / أتروفنت',
    nameEn: 'Ipratropium / Atrovent',
    descriptionAr: 'بخاخ موسع للشعب',
    descriptionEn: 'Bronchodilator inhaler',
    medicationType: 'emergency',
    instructionsAr: 'يُستخدم حسب تعليمات الطبيب عند ضيق التنفس.',
    instructionsEn: 'Use as directed for breathing difficulty.',
    warningAr: 'تجنب وصول الرذاذ إلى العينين.',
    warningEn: 'Avoid spraying into the eyes.',
    imagePath: 'assets/images/medications/ipratropium.png',
    sortOrder: 8,
  ),
];
