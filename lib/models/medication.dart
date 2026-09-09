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

  factory Medication.fromJson(Map<String, dynamic> json) {
    final String code = json['code'] as String;

    // ابحث عن الدواء في الكتالوج المحلي المطابق لنفس الكود
    final fallbackMedication = medicationCatalog.firstWhere(
      (m) => m.code == code,
      orElse: () => Medication(
        code: code,
        nameAr: '',
        nameEn: '',
        A1: '',
        descriptionAr: '',
        descriptionEn: '',
        medicationType: '',
        instructionsAr: '',
        instructionsEn: '',
        imagePath: '',
        sortOrder: 0,
      ),
    );

    return Medication(
      code: code,
      nameAr: json['name_ar'] as String,
      nameEn: (json['name_en'] as String?) ?? json['name_ar'] as String,
      A1: (json['A1'] as String?) ??
          (json['name_en'] as String?) ??
          (json['name_ar'] as String? ?? ''),
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
      
      // سحب الخطوات من الداتا بيس، وإذا كانت فارغة ناخذها من الكتالوج
      stepsEn: (json['steps_en'] as List?)?.isNotEmpty == true
          ? (json['steps_en'] as List).map((e) => e.toString()).toList()
          : fallbackMedication.stepsEn,
          
      stepsAr: (json['steps_ar'] as List?)?.isNotEmpty == true
          ? (json['steps_ar'] as List).map((e) => e.toString()).toList()
          : fallbackMedication.stepsAr,
          
      videoUrl: json['video_url'] as String?,
    );
  }
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
const _capsuleDpiStepsEn = [
  'Open the device and place one capsule from the blister into the chamber.',
  'Close the mouthpiece until it clicks (do not shake).',
  'Press the piercing button(s) once and release.',
  'Breathe out fully, away from the inhaler.',
  'Place the mouthpiece between your teeth and close your lips around it.',
  'Breathe in quickly and deeply — you should hear the capsule vibrate.',
  'Hold your breath for 5-10 seconds, then remove the inhaler from your mouth.',
  'Check the capsule is empty; if not, repeat the inhalation.',
  'Discard the empty capsule and close the mouthpiece.',
];
const _capsuleDpiStepsAr = [
  'افتح الجهاز وضع كبسولة واحدة من الشريط في الحجرة.',
  'أغلق القطعة الفموية حتى تسمع نقرة (لا ترجّه).',
  'اضغط زر (أزرار) الثقب مرة واحدة ثم حرره.',
  'ازفر بالكامل بعيداً عن الجهاز.',
  'ضع القطعة الفموية بين أسنانك وأغلق شفتيك حولها.',
  'استنشق بسرعة وعمق — يجب أن تسمع اهتزاز الكبسولة.',
  'احبس نفسك لمدة 5-10 ثوانٍ ثم أخرج الجهاز من فمك.',
  'تحقق من أن الكبسولة فارغة؛ إذا لم تكن، كرّر الاستنشاق.',
  'تخلص من الكبسولة الفارغة وأغلق القطعة الفموية.',
];

const _elpenhalerStepsEn = [
  'Hold the inhaler with one hand and pull the lever fully out, then push it back in to load a dose.',
  'Breathe out fully, away from the mouthpiece.',
  'Place the mouthpiece between your lips and close them to form a good seal.',
  'Breathe in quickly and deeply through the mouthpiece.',
  'Remove the inhaler and hold your breath for about 10 seconds.',
  'Breathe out slowly, away from the mouthpiece.',
];
const _elpenhalerStepsAr = [
  'أمسك الجهاز بيد واسحب الذراع بالكامل للخارج ثم أعده للداخل لتحميل الجرعة.',
  'ازفر بالكامل بعيداً عن القطعة الفموية.',
  'ضع القطعة الفموية بين شفتيك وأغلقهما لتكوين إغلاق محكم.',
  'استنشق بسرعة وعمق من خلال القطعة الفموية.',
  'أخرج الجهاز واحبس نفسك لنحو 10 ثوانٍ.',
  'أخرج الزفير ببطء بعيداً عن القطعة الفموية.',
];

const _easyhalerStepsEn2 = [
  'Hold the inhaler upright and shake it 3 to 5 times.',
  'Press down once on the coloured button until you hear a click, then release.',
  'Breathe out slowly, away from the inhaler.',
  'Place the mouthpiece between your teeth and close your lips around it.',
  'Breathe in quickly and deeply.',
  'Hold your breath for 5-10 seconds, then remove the inhaler from your mouth.',
  'Breathe out gently, away from the inhaler.',
  'Replace the mouthpiece cover after use.',
];
const _easyhalerStepsAr2 = [
  'أمسك الجهاز بشكل عمودي ورجّه من 3 إلى 5 مرات.',
  'اضغط مرة واحدة على الزر الملوّن حتى تسمع نقرة ثم حرره.',
  'ازفر ببطء بعيداً عن الجهاز.',
  'ضع القطعة الفموية بين أسنانك وأغلق شفتيك حولها.',
  'استنشق بسرعة وعمق.',
  'احبس نفسك لمدة 5-10 ثوانٍ ثم أخرج الجهاز من فمك.',
  'ازفر بلطف بعيداً عن الجهاز.',
  'أعد غطاء القطعة الفموية بعد الاستخدام.',
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
  Medication(
    code: 'salres',
    nameAr: 'سالريس',
    nameEn: 'Salres',
    A1: 'Salres',
    descriptionAr: 'بخاخ منقذ (أزرق)',
    descriptionEn: 'Rescue inhaler (blue)',
    medicationType: 'emergency',
    instructionsAr: 'يستخدم هذا الدواء عند الحاجة فقط.',
    instructionsEn: 'Use this medicine only when needed.',
    warningAr:
        'لا يوجد جدول زمني ثابت لهذا الدواء. يُستخدم عند الشعور بالأعراض أو قبل ممارسة الرياضة حسب تعليمات الطبيب.',
    warningEn:
        'There is no fixed schedule. Use it when symptoms occur or before exercise as directed by your doctor.',
    imagePath: 'assets/images/medications/salres.jpg',
    sortOrder: 9,
    stepsEn: _mdiStepsEn,
    stepsAr: _mdiStepsAr,
    videoUrl: null,
  ),
  Medication(
    code: 'brontio',
    nameAr: 'برونتيو',
    nameEn: 'Brontio',
    A1: 'Brontio',
    descriptionAr: 'كبسولات استنشاق - موسّع قصبي طويل المفعول',
    descriptionEn: 'Inhalation capsules - long-acting bronchodilator',
    medicationType: 'preventer',
    instructionsAr:
        'تُستخدم كبسولة واحدة يومياً عبر جهاز الاستنشاق المرفق حسب وصف الطبيب.',
    instructionsEn:
        'Use one capsule daily through the supplied inhalation device as prescribed.',
    warningAr: 'لا تبتلع الكبسولة؛ فهي للاستنشاق فقط.',
    warningEn: 'Do not swallow the capsule; it is for inhalation only.',
    imagePath: 'assets/images/medications/brontio.jpg',
    sortOrder: 10,
    stepsEn: _capsuleDpiStepsEn,
    stepsAr: _capsuleDpiStepsAr,
    videoUrl: null,
  ),
  Medication(
    code: 'respiramol',
    nameAr: 'ريسبيرامول',
    nameEn: 'Respiramol',
    A1: 'Respiramol',
    descriptionAr: 'كبسولات استنشاق مركبة (بوديزونيد + فورموتيرول)',
    descriptionEn: 'Combination inhalation capsules (Budesonide + Formoterol)',
    medicationType: 'preventer',
    instructionsAr: 'تُستخدم بانتظام حسب الجرعة والجدول الذي حدده الطبيب.',
    instructionsEn: 'Use regularly at the dose and schedule set by your doctor.',
    warningAr: 'تمضمض بعد الاستخدام ولا توقفه دون استشارة الطبيب.',
    warningEn:
        'Rinse your mouth after use and do not stop without medical advice.',
    imagePath: 'assets/images/medications/respiramol.jpg',
    sortOrder: 11,
    stepsEn: _capsuleDpiStepsEn,
    stepsAr: _capsuleDpiStepsAr,
    videoUrl: null,
  ),
  Medication(
    code: 'pralas',
    nameAr: 'برالاس',
    nameEn: 'Pralas',
    A1: 'Pralas',
    descriptionAr: 'بخاخ موسّع للشعب الهوائية (مركب)',
    descriptionEn: 'Combination bronchodilator inhaler',
    medicationType: 'emergency',
    instructionsAr: 'يُستخدم حسب تعليمات الطبيب عند ضيق التنفس.',
    instructionsEn: 'Use as directed for breathing difficulty.',
    warningAr: 'تجنب وصول الرذاذ إلى العينين.',
    warningEn: 'Avoid spraying into the eyes.',
    imagePath: 'assets/images/medications/pralas.jpg',
    sortOrder: 12,
    stepsEn: _mdiStepsEn,
    stepsAr: _mdiStepsAr,
    videoUrl: null,
  ),
  Medication(
    code: 'pulmoton',
    nameAr: 'بولموتون',
    nameEn: 'Pulmoton',
    A1: 'Pulmoton',
    descriptionAr: 'مسحوق استنشاق مركب (Elpenhaler)',
    descriptionEn: 'Combination inhalation powder (Elpenhaler)',
    medicationType: 'preventer',
    instructionsAr: 'يُستخدم بانتظام حسب الجرعة الموصوفة.',
    instructionsEn: 'Use regularly at the prescribed dose.',
    warningAr: 'تمضمض بعد كل جرعة.',
    warningEn: 'Rinse your mouth after each dose.',
    imagePath: 'assets/images/medications/pulmoton.jpg',
    sortOrder: 13,
    stepsEn: _elpenhalerStepsEn,
    stepsAr: _elpenhalerStepsAr,
    videoUrl: null,
  ),
  Medication(
    code: 'rolenium',
    nameAr: 'رولينيوم',
    nameEn: 'Rolenium',
    A1: 'Rolenium',
    descriptionAr: 'مسحوق استنشاق مركب (Elpenhaler)',
    descriptionEn: 'Combination inhalation powder (Elpenhaler)',
    medicationType: 'preventer',
    instructionsAr: 'يُستخدم بانتظام صباحاً ومساءً حسب الخطة العلاجية.',
    instructionsEn: 'Use regularly morning and evening according to your plan.',
    warningAr: 'ليس بديلاً عن بخاخ الإنقاذ أثناء النوبة الحادة.',
    warningEn: 'It does not replace a rescue inhaler during an acute attack.',
    imagePath: 'assets/images/medications/rolenium.jpg',
    sortOrder: 14,
    stepsEn: _elpenhalerStepsEn,
    stepsAr: _elpenhalerStepsAr,
    videoUrl: null,
  ),
  Medication(
    code: 'airtide',
    nameAr: 'إيرتايد',
    nameEn: 'Airtide',
    A1: 'Airtide',
    descriptionAr: 'كبسولات استنشاق مركبة جاهزة الجرعة',
    descriptionEn: 'Pre-metered combination inhalation capsules',
    medicationType: 'preventer',
    instructionsAr: 'تُستخدم بانتظام حسب الجرعة الموصوفة.',
    instructionsEn: 'Use regularly at the prescribed dose.',
    warningAr: 'تمضمض بعد كل جرعة.',
    warningEn: 'Rinse your mouth after each dose.',
    imagePath: 'assets/images/medications/airtide.jpg',
    sortOrder: 15,
    stepsEn: _capsuleDpiStepsEn,
    stepsAr: _capsuleDpiStepsAr,
    videoUrl: null,
  ),
  Medication(
    code: 'foracort',
    nameAr: 'فوراكورت',
    nameEn: 'Foracort',
    A1: 'Foracort',
    descriptionAr: 'بخاخ مركب بعداد جرعات',
    descriptionEn: 'Combination inhaler with dose counter',
    medicationType: 'preventer',
    instructionsAr:
        'استخدم الجرعة الموصوفة بانتظام وبطريقة الاستنشاق الصحيحة.',
    instructionsEn:
        'Use the prescribed dose regularly with correct inhalation technique.',
    warningAr: 'تحقق من عداد الجرعات قبل كل استخدام.',
    warningEn: 'Check the dose counter before each use.',
    imagePath: 'assets/images/medications/foracort.jpg',
    sortOrder: 16,
    stepsEn: _mdiStepsEn,
    stepsAr: _mdiStepsAr,
    videoUrl: null,
  ),
  Medication(
    code: 'pulmicort',
    nameAr: 'بولميكورت',
    nameEn: 'Pulmicort',
    A1: 'Pulmicort',
    descriptionAr: 'مسحوق جاف توربوهيلر',
    descriptionEn: 'Dry powder inhaler (Turbuhaler)',
    medicationType: 'preventer',
    instructionsAr:
        'يُستخدم يومياً حسب وصف الطبيب للسيطرة على التهاب مجاري التنفس.',
    instructionsEn: 'Use daily as prescribed to control airway inflammation.',
    warningAr: 'تمضمض بعد الاستخدام ولا توقفه دون استشارة الطبيب.',
    warningEn:
        'Rinse your mouth after use and do not stop without medical advice.',
    imagePath: 'assets/images/medications/pulmicort.jpg',
    sortOrder: 17,
    stepsEn: _turbuhalerStepsEn,
    stepsAr: _turbuhalerStepsAr,
    videoUrl: null,
  ),
  Medication(
    code: 'fobumix',
    nameAr: 'فوبوميكس',
    nameEn: 'Fubumix',
    A1: 'Fubumix',
    descriptionAr: 'مسحوق جاف Easyhaler مركب',
    descriptionEn: 'Combination dry powder inhaler (Easyhaler)',
    medicationType: 'preventer',
    instructionsAr: 'تُستخدم بانتظام حسب الجرعة الموصوفة.',
    instructionsEn: 'Use regularly at the prescribed dose.',
    warningAr: 'رجّ الجهاز جيداً قبل كل استخدام.',
    warningEn: 'Shake the device well before each use.',
    imagePath: 'assets/images/medications/fobumix.jpg',
    sortOrder: 18,
    stepsEn: _easyhalerStepsEn2,
    stepsAr: _easyhalerStepsAr2,
    videoUrl: null,
  ),
];