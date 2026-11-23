// lib/core/arabic_terms.dart
//
// Keeps Arabic text 100% Arabic. Some medication texts (e.g. the ones that come
// from the database) still contain Latin device names or abbreviations such as
// "pMDI" or "Elpenhaler". [pureArabic] swaps them for Arabic wording.
// Add new terms to [_terms] when needed.

const List<(String, String)> _terms = [
  ('بخاخ pMDI', 'بخاخ الجرعات المقننة'),
  ('pMDI', 'بخاخ الجرعات المقننة'),
  ('Elpenhaler', 'إلبنهيلر'),
  ('Easyhaler', 'إيزي هيلر'),
  ('Turbuhaler', 'توربوهيلر'),
  ('Autohaler', 'أوتوهيلر'),
  ('Accuhaler', 'أكيوهيلر'),
  ('Breezhaler', 'بريزهيلر'),
  ('Handihaler', 'هاندي هيلر'),
  ('LupinHaler', 'لوبين هيلر'),
  ('Ciphaler', 'سيفالر'),
  ('Spiromax', 'سبيرومكس'),
  ('Respimat', 'ريسبيمات'),
  ('Haleraid', 'هاليريد'),
  ('Genuair', 'جينوير'),
  ('Ellipta', 'إليبتا'),
  ('Diskus', 'ديسكاس'),
  ('Zonda', 'زوندا'),
  ('Spacer', 'الحجرة الفاصلة'),
  ('Budesonide', 'بوديزونيد'),
  ('Formoterol', 'فورموتيرول'),
  ('DPI', 'بودرة جافة'),
  ('SMI', 'رذاذ ناعم'),
];

/// Replaces Latin device names / abbreviations inside Arabic text.
String pureArabic(String text) {
  var out = text;
  for (final (latin, arabic) in _terms) {
    out = out.replaceAll(RegExp(latin, caseSensitive: false), arabic);
  }
  return out;
}