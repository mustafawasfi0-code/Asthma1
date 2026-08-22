import 'app_state.dart';

const iraqiCityArabic = <String, String>{
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

String localizedCity(String value) =>
    AppState.instance.arabic ? iraqiCityArabic[value] ?? value : value;

String localizedStoredValue(String value, Map<String, String> arabicValues) =>
    AppState.instance.arabic ? arabicValues[value] ?? value : value;

const _commonEnglishNames = <String, String>{
  'علي': 'Ali',
  'محمد': 'Mohammed',
  'احمد': 'Ahmed',
  'أحمد': 'Ahmed',
  'حسن': 'Hassan',
  'حسين': 'Hussein',
  'محمود': 'Mahmoud',
  'مصطفى': 'Mustafa',
  'فاطمة': 'Fatima',
  'زهراء': 'Zahraa',
  'مريم': 'Maryam',
  'نور': 'Noor',
};

String localizedPersonName(String value) {
  if (AppState.instance.arabic || value.trim().isEmpty) return value;
  final trimmed = value.trim();
  final common = _commonEnglishNames[trimmed];
  if (common != null) return common;
  const letters = <String, String>{
    'ا': 'a',
    'أ': 'a',
    'إ': 'i',
    'آ': 'a',
    'ب': 'b',
    'ت': 't',
    'ث': 'th',
    'ج': 'j',
    'ح': 'h',
    'خ': 'kh',
    'د': 'd',
    'ذ': 'th',
    'ر': 'r',
    'ز': 'z',
    'س': 's',
    'ش': 'sh',
    'ص': 's',
    'ض': 'd',
    'ط': 't',
    'ظ': 'z',
    'ع': 'a',
    'غ': 'gh',
    'ف': 'f',
    'ق': 'q',
    'ك': 'k',
    'ل': 'l',
    'م': 'm',
    'ن': 'n',
    'ه': 'h',
    'ة': 'a',
    'و': 'w',
    'ؤ': 'u',
    'ي': 'y',
    'ى': 'a',
    'ئ': 'e',
    'ء': '',
  };
  final result = trimmed.runes.map((rune) {
    final character = String.fromCharCode(rune);
    return letters[character] ?? character;
  }).join();
  if (result.isEmpty) return value;
  return '${result[0].toUpperCase()}${result.substring(1)}';
}

const healthValueArabic = <String, String>{
  'Male': 'ذكر',
  'Female': 'أنثى',
  'Family': 'العائلة',
  'Friend': 'صديق',
  'Doctor': 'طبيب',
  'Caregiver': 'مقدم رعاية',
  'Cough': 'سعال',
  'Wheezing': 'صفير',
  'Shortness of breath': 'ضيق نفس',
  'Night waking': 'استيقاظ ليلاً',
  'Dust & Sandstorms': 'الغبار والعواصف الترابية',
 'Smoke & Tobacco': 'الدخان والتدخين',
 'Exercise & Effort': 'الجهد البدني والرياضة',
 'Cold Air': 'الهواء البارد والتغير الجوي',
 'Strong Scents': 'العطور والروائح القوية',
 'Pets': 'الحيوانات الأليفة',
 'Pollen': 'حبوب اللقاح والنباتات',
 'Stress & Emotions': 'التوتر والمشاعر القوية',

};

String localizedHealthValue(String value) =>
    localizedStoredValue(value, healthValueArabic);
