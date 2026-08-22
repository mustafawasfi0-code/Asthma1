class Medication {
  const Medication({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.A1,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.medicationType,
    required this.instructionsAr,
    required this.instructionsEn,
    this.warningAr,
    this.warningEn,
    required this.imagePath,
    required this.sortOrder,
    this.stepsEn = const [],
    this.stepsAr = const [],
    this.videoUrl,
  });

  final String code;
  final String nameAr;
  final String nameEn;
  final String A1;
  final String descriptionAr;
  final String descriptionEn;
  final String medicationType;
  final String instructionsAr;
  final String instructionsEn;
  final String? warningAr;
  final String? warningEn;
  final String imagePath;
  final int sortOrder;

  /// "How to use" steps shown on the how-to-use onboarding page.
  final List<String> stepsEn;
  final List<String> stepsAr;

  /// Optional YouTube URL demonstrating correct technique for this medicine.
  /// If null (or not a valid YouTube link), the how-to-use page shows a
  /// "Video unavailable" placeholder instead of crashing.
  final String? videoUrl;

  bool get isEmergency => medicationType == 'emergency';

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
    code: json['code'] as String,
    nameAr: json['name_ar'] as String,
    nameEn: (json['name_en'] as String?) ?? json['name_ar'] as String,
    A1: json['A1'] as String,
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
    stepsEn: (json['steps_en'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    stepsAr: (json['steps_ar'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    videoUrl: json['video_url'] as String?,
  );
}

const _mdiStepsEn = [
  'Remove the cap and shake the inhaler hard for 5 seconds.',
  'Sit up straight or stand up.',
  'Breathe out all the way to empty your lungs.',
  'Place the inhaler in your mouth between your teeth and close your lips around it.',
  'Press down on the canister once as you start to breathe in slowly.',
  'Keep breathing in slowly and deeply for 3-5 seconds.',
  'Hold your breath for 10 seconds.',
  'Breathe out slowly.',
  'Wait 1 minute before the next puff.',
];
const _mdiStepsAr = [
  'انزع الغطاء ورج البخاخ بقوة لمدة 5 ثوانٍ.',
  'اجلس أو قف باعتدال.',
  'أخرج الزفير بالكامل لإفراغ رئتيك.',
  'ضع البخاخ في فمك بين أسنانك وأغلق شفتيك حوله.',
  'اضغط على العلبة مرة واحدة أثناء بدء الشهيق ببطء.',
  'استمر بالشهيق ببطء وعمق لمدة 3-5 ثوانٍ.',
  'احبس نفسك لمدة 10 ثوانٍ.',
  'أخرج الزفير ببطء.',
  'انتظر دقيقة واحدة قبل النفخة التالية.',
];

const _turbuhalerStepsEn = [
  'Unscrew and remove the white cap.',
  'Hold the inhaler upright with the coloured grip at the bottom.',
  'Twist the grip fully in one direction, then back until it clicks — this loads the dose.',
  'Breathe out gently, away from the inhaler.',
  'Place the mouthpiece between your teeth and close your lips around it.',
  'Breathe in forcefully and deeply through your mouth.',
  'Remove the inhaler and hold your breath for 5-10 seconds.',
  'Breathe out slowly, away from the mouthpiece.',
];
const _turbuhalerStepsAr = [
  'افتح الغطاء الأبيض وانزعه.',
  'أمسك الجهاز عمودياً مع جعل الجزء الملون في الأسفل.',
  'أدر الجزء الملون بالكامل باتجاه واحد ثم أعده حتى تسمع صوت طقة — هذا يجهّز الجرعة.',
  'أخرج الزفير برفق بعيداً عن الجهاز.',
  'ضع الفوهة بين أسنانك وأغلق شفتيك حولها.',
  'استنشق بقوة وعمق من فمك.',
  'انزع الجهاز واحبس نفسك لمدة 5-10 ثوانٍ.',
  'أخرج الزفير ببطء بعيداً عن الفوهة.',
];

const _diskusStepsEn = [
  'Hold the outer case with one hand and push the thumb grip away with the other to open it.',
  'Hold the mouthpiece toward you and slide the lever away until it clicks — this loads the dose.',
  'Breathe out fully, away from the mouthpiece.',
  'Place the mouthpiece between your lips (not your teeth) and breathe in forcefully and deeply.',
  'Remove the Diskus and hold your breath for about 10 seconds.',
  'Breathe out slowly, then slide the thumb grip back to close it.',
];
const _diskusStepsAr = [
  'أمسك الغلاف الخارجي بيد وادفع مسند الإبهام بعيداً باليد الأخرى لفتحه.',
  'وجّه الفوهة نحوك واسحب الذراع بعيداً حتى تسمع طقة — هذا يجهّز الجرعة.',
  'أخرج الزفير بالكامل بعيداً عن الفوهة.',
  'ضع الفوهة بين شفتيك (وليس أسنانك) واستنشق بقوة وعمق.',
  'انزع الجهاز واحبس نفسك لمدة 10 ثوانٍ تقريباً.',
  'أخرج الزفير ببطء، ثم أعد مسند الإبهام إلى الخلف لإغلاقه.',
];

const medicationCatalog = <Medication>[
  Medication(
    code: 'ventolin',
    nameAr: 'فينتولين / بوتالين / سامالير',
    nameEn: 'Ventolin / Butalin / Samaler',
    A1: 'Ventolin' ,
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
    stepsEn: _mdiStepsEn,
    stepsAr: _mdiStepsAr,
    videoUrl: null,
  ),
  Medication(
    code: 'clenil',
    nameAr: 'كلينيل / بيكلوميثازون',
    nameEn: 'Clenil / Beclometasone',
    A1: 'Clenil',
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
    stepsEn: _mdiStepsEn,
    stepsAr: _mdiStepsAr,
    videoUrl: null,
  ),
  Medication(
    code: 'symbicort',
    nameAr: 'سيمبيكورت تيربوهيلر',
    nameEn: 'Symbicort Turbuhaler',
    A1: 'Symbicort Turbuhaler',
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
    stepsEn: _turbuhalerStepsEn,
    stepsAr: _turbuhalerStepsAr,
    videoUrl: null,
  ),
  Medication(
    code: 'seretide',
    nameAr: 'سيريتايد ديسكاس',
    nameEn: 'Seretide Diskus',
    A1: 'Seretide Diskus',
    descriptionAr: 'مسحوق جاف (أرجواني)',
    descriptionEn: 'Dry powder inhaler (purple)',
    medicationType: 'preventer',
    instructionsAr: 'يُستخدم بانتظام صباحاً ومساءً حسب الخطة العلاجية.',
    instructionsEn: 'Use regularly morning and evening according to your plan.',
    warningAr: 'ليس بديلاً عن بخاخ الإنقاذ أثناء النوبة الحادة.',
    warningEn: 'It does not replace a rescue inhaler during an acute attack.',
    imagePath: 'assets/images/medications/seretide.png',
    sortOrder: 4,
    stepsEn: _diskusStepsEn,
    stepsAr: _diskusStepsAr,
    videoUrl: null,
  ),
  Medication(
    code: 'foster',
    nameAr: 'فوستر / فوستير',
    nameEn: 'Foster / Fostair',
    A1: 'Foster',
    descriptionAr: 'بخاخ مركب',
    descriptionEn: 'Combination inhaler',
    medicationType: 'preventer',
    instructionsAr: 'استخدمه حسب الجدول الذي حدده الطبيب.',
    instructionsEn: 'Use according to the schedule set by your doctor.',
    warningAr: 'لا تغيّر الجرعة دون مراجعة الطبيب.',
    warningEn: 'Do not change the dose without consulting your doctor.',
    imagePath: 'assets/images/medications/foster.png',
    sortOrder: 5,
    stepsEn: _mdiStepsEn,
    stepsAr: _mdiStepsAr,
    videoUrl: null,
  ),
  Medication(
    code: 'montelukast',
    nameAr: 'مونتيلوكاست',
    nameEn: 'Montelukast',
    A1: 'Montelukest',
    descriptionAr: 'أقراص وقائية',
    descriptionEn: 'Preventer tablets',
    medicationType: 'preventer',
    instructionsAr: 'يؤخذ مرة يومياً حسب وصف الطبيب.',
    instructionsEn: 'Take once daily as prescribed.',
    warningAr: 'أبلغ الطبيب عند ظهور تغيرات غير معتادة في المزاج أو النوم.',
    warningEn: 'Tell your doctor about unusual mood or sleep changes.',
    imagePath: 'assets/images/medications/montelukast.png',
    sortOrder: 6,
    stepsEn: const [
      'Take one tablet by mouth, with or without food.',
      'Take it at the same time each day as prescribed.',
      'Swallow the tablet whole with water.',
      'Do not stop taking it even if you feel well, unless your doctor advises.',
    ],
    stepsAr: const [
      'خذ قرصاً واحداً عن طريق الفم، مع الطعام أو بدونه.',
      'خذه في نفس الوقت يومياً حسب وصف الطبيب.',
      'ابلع القرص كاملاً مع الماء.',
      'لا تتوقف عن أخذه حتى لو شعرت بتحسن، إلا بنصيحة الطبيب.',
    ],
    videoUrl: null, // tablet — no device technique to demonstrate
  ),
  Medication(
    code: 'prednisolone',
    nameAr: 'بريدنيزولون',
    nameEn: 'Prednisolone',
    A1: 'Prednisolone',
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
    stepsEn: const [
      'Take the tablets exactly as prescribed by your doctor.',
      'Take with food to reduce stomach upset.',
      "Do not stop suddenly if used for more than a few days — follow your doctor's tapering plan.",
      'Contact your doctor if you notice unusual side effects.',
    ],
    stepsAr: const [
      'خذ الأقراص تماماً حسب وصف الطبيب.',
      'خذها مع الطعام لتقليل اضطراب المعدة.',
      'لا تتوقف فجأة إذا استخدمته لأكثر من بضعة أيام — اتبع خطة التخفيض التدريجي من طبيبك.',
      'اتصل بطبيبك عند ظهور أي آثار جانبية غير معتادة.',
    ],
    videoUrl: null, // tablet — no device technique to demonstrate
  ),
  Medication(
    code: 'ipratropium',
    nameAr: 'إبراتروبيوم / أتروفنت',
    nameEn: 'Ipratropium / Atrovent',
    A1: 'Ipratopium',
    descriptionAr: 'بخاخ موسع للشعب',
    descriptionEn: 'Bronchodilator inhaler',
    medicationType: 'emergency',
    instructionsAr: 'يُستخدم حسب تعليمات الطبيب عند ضيق التنفس.',
    instructionsEn: 'Use as directed for breathing difficulty.',
    warningAr: 'تجنب وصول الرذاذ إلى العينين.',
    warningEn: 'Avoid spraying into the eyes.',
    imagePath: 'assets/images/medications/ipratropium.png',
    sortOrder: 8,
    stepsEn: _mdiStepsEn,
    stepsAr: _mdiStepsAr,
    videoUrl: null,
  ),
];