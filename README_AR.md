# تطبيق AsthmaCare — Flutter

هذا المشروع تحويل Native Widgets لنسخة موقع Figma/HTTrack الموجودة في المجلد الأب. لا يستخدم WebView.

## التشغيل

1. ثبّت أحدث Flutter مستقر.
2. انسخ `.env.example` إلى `.env`.
3. من داخل `flutter_app` نفّذ:

```bash
flutter pub get
flutter run
```

## إعداد Supabase

1. أنشئ مشروعاً من لوحة Supabase.
2. افتح SQL Editor والصق محتوى `supabase_schema.sql` ثم نفّذه.
3. ضع القيم في `.env`:

```env
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

المخطط ينشئ `profiles` و`peak_flow_logs` و`symptom_logs` و`trigger_logs` و`medication_logs` و`reminders` و`community_posts`، مع العلاقات والفهارس وRLS وTriggers لـ`updated_at`. لا تضع مفتاح service role داخل التطبيق.

## بناء APK

```bash
flutter pub get
dart format lib test
flutter analyze
flutter build apk --debug
```

الملف الناتج: `build/app/outputs/flutter-apk/app-debug.apk`.

## الصفحات المحوّلة

- إعداد الملف الشخصي بأربع خطوات: الاسم، الموقع، البيانات، القياسات.
- الرئيسية والوصول السريع واتجاه Peak Flow والنصيحة.
- المتابعة: Peak Flow والأعراض والمهيجات.
- خطة عمل الربو: المناطق الخضراء والصفراء والحمراء والطوارئ.
- التعلّم، دليل البخاخ، دليل قياس PEF وتسجيل أعلى قراءة.
- الملف الشخصي ومقدم الرعاية والتذكيرات.
- مجتمع المرضى.
- تقرير الطبيب.

تم تنفيذ التنقل عبر `go_router`، وتقسيم البيانات إلى `models/services/repositories`، ودعم العربية وRTL وتخطيطات مرنة للهواتف.

## ملاحظات المصدر

- المصدر نسخة HTTrack من Figma Make، ويتكون من bundle JavaScript/CSS وJSON واحد، وليس مشروع المصدر الأصلي.
- لا توجد ملفات خطوط أو صور تطبيق محلية داخل النسخة؛ الأيقونات الأصلية كانت SVG مولّدة داخل JavaScript، ولذلك استُبدلت بأيقونات Material الأصلية الأقرب شكلاً كـNative Widgets. حُفظت ملفات CSS وFigma JSON وملفات GIF المتاحة في `assets/source` للتدقيق.
- واجهة المصدر لا تحتوي شاشة تسجيل دخول أو إنشاء حساب؛ لذلك لم تُضف شاشة Auth ظاهرة كي لا يتغير التصميم. طبقات Supabase مربوطة بالمستخدم الحالي، والمخطط يربط `auth.users` بـ`profiles` تلقائياً عند تفعيل المصادقة لاحقاً.
- زر المجتمع في المصدر كان يعرض رسالة تطلب ربط قاعدة البيانات؛ تم الإبقاء على نفس السلوك الظاهر، مع تجهيز جدول `community_posts` للربط.
- بيانات الطقس في المصدر تعتمد خدمات شبكة خارجية غير موجودة ضمن نسخة HTTrack؛ لم تُخترع بيانات بديلة.

## نتائج التحقق والبناء النهائية

تم تنفيذ الأوامر من المسار `C:\Projects\flutter_app` بتاريخ 2026-07-21:

- `flutter clean`: نجح.
- `flutter pub get`: نجح.
- `dart format .`: نجح، وجميع الملفات منسقة.
- `flutter analyze`: نجح — `No issues found`.
- `flutter test`: نجح — `All tests passed`.
- `flutter build apk --debug`: نجح.
- `flutter build apk --release`: نجح.
- `flutter build appbundle --release`: نجح.

### ملفات الإصدار

- Debug APK: `C:\Projects\flutter_app\release\pharmacy-app-debug.apk`
- Release APK: `C:\Projects\flutter_app\release\pharmacy-app-release.apk`
- Release AAB: `C:\Projects\flutter_app\release\pharmacy-app-release.aab`

### متغيرات البيئة

يقرأ التطبيق القيم التالية من `.env` بواسطة `flutter_dotenv`:

```env
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

لا يحتوي كود Dart على مفتاح `service_role` أو مفاتيح Supabase سرية. ملف `.env.example` محفوظ كنموذج بدون بيانات حقيقية.

### تشغيل المشروع من موقعه النهائي

```powershell
cd C:\Projects\flutter_app
flutter pub get
flutter run
```

إعدادات Gradle مضبوطة لاستخدام ذاكرة محدودة وعامل واحد لتناسب الجهاز الحالي. Visual Studio غير مطلوب لبناء Android؛ ملاحظة `flutter doctor` الخاصة به تخص تطبيقات Windows فقط.

## إكمال ربط Supabase

قبل وضع مفاتيح المشروع، نفّذ `supabase_schema.sql` من Supabase Dashboard > SQL Editor > New query > الصق الملف كاملًا > Run. ثم افتح Authentication > Settings (أو Sign In / Providers حسب واجهة اللوحة) وفعّل Allow anonymous sign-ins، لأن تصميم التطبيق الأصلي لا يحتوي شاشة تسجيل دخول. التطبيق ينشئ جلسة مجهولة آمنة تلقائيًا، وكل جلسة تصل فقط إلى بياناتها عبر RLS.

## نتيجة ربط Supabase الفعلية

تم ربط المشروع بـSupabase باستخدام `SUPABASE_URL` و`SUPABASE_ANON_KEY` من ملف `.env` بتاريخ 2026-07-21. تم اختبار إنشاء Anonymous Session بنجاح، وإنشاء صف `profiles` تلقائياً بدور `patient`. كما نجحت عمليات الإدخال والقراءة والحذف عبر RLS في: `peak_flow_logs`, `symptom_logs`, `trigger_logs`, `medication_logs`, `reminders`, `community_posts`.

بعد الربط نجحت النتائج التالية:
- `flutter clean`: ناجح.
- `flutter pub get`: ناجح.
- `flutter analyze`: No issues found.
- `flutter test`: All tests passed.
- Debug APK: ناجح.
- Release APK: ناجح.
- Release AAB: ناجح.

## مسار الأدوية والطوارئ

أضيف مسار Onboarding أصلي بـ Flutter لاختيار عدة أدوية من ثمانية أدوية أو المتابعة بلا اختيار، ثم عرض تعليمات الأدوية المختارة بالتتابع، ثم إضافة جهة اتصال طوارئ اختيارية. يمكن تعديل جهة الاتصال أو حذفها من الملف الشخصي، ويمكن الاتصال بها من خطة التعامل مع الربو بعد نافذة تأكيد.

### تحديث Supabase

بعد هذا التحديث افتح لوحة مشروع Supabase، ثم SQL Editor، ثم New query. الصق ملف supabase_schema.sql كاملاً وشغّله. الملف قابل للتشغيل أكثر من مرة ويضيف الجداول:

- medications
- user_medications
- emergency_contacts

مع الفهارس، العلاقات، RLS، Triggers، وبيانات الأدوية الثمانية. يجب تنفيذ النسخة المحدثة من الملف قبل تجربة حفظ الأدوية أو جهة الطوارئ.

### ملفات البناء النهائية

- release/pharmacy-app-debug.apk
- release/pharmacy-app-release.apk
- release/pharmacy-app-release.aab

### نتيجة التحقق

- flutter analyze: بدون أخطاء أو تحذيرات.
- flutter test: جميع الاختبارات ناجحة.
- Debug APK وRelease APK وRelease AAB: تم بناؤها بنجاح.

## ?????? ?????? ???????? (????? 2026)

- ????? ?????? ???????? ??????? HomeRepository ???? ????? ??????? ??????? ????????? ?????? PEF ?????????? ?? Supabase.
- ????? ?? ???? ?????? ?????? ???? ???? ???? ????? ??? ??? ??? ???? ??? ?????.
- ????? ????? ?????? ????? ?????? ??? ?????? ?????? ????? ??????? ????????? ??????????.
- ?? ??? ??? ?????? ????? ???????? ?????? ??????? ???? PEF? ????? ?????? ?????????? ????????? ???????.
- ????? `flutter analyze`: ?? ???? ?????.
- ????? `flutter test`: ???? 6 ????????.
- ??? ???? Debug APK ?Release APK ?Release AAB.

????? ?????? ????????:

- `release/pharmacy-app-debug.apk`
- `release/pharmacy-app-release.apk`
- `release/pharmacy-app-release.aab`

## صفحة المراقبة الكاملة (يوليو 2026)

- يدعم PEF ثلاث قراءات بالضبط، ويحفظ أعلى قراءة ويحسب النسبة والمنطقة مقارنة بأفضل رقم شخصي.
- يدعم مناطق Green وYellow وRed ونافذة نتيجة مع الإجراءات والانتقال إلى خطة العمل.
- يدعم اختيار أعراض متعددة، شدة من 0 إلى 10، ملاحظة، سجل كامل، تعديل وحذف.
- يدعم مثيرات جاهزة ومثيراً مخصصاً، مع سجل كامل وتعديل وحذف.
- أضيفت ترقية Monitoring v2 في نهاية `supabase_schema.sql`. يجب تنفيذ هذا الجزء في SQL Editor للمشروع الحالي قبل استخدام حفظ PEF الجديد.
- نتيجة التحليل: لا توجد مشاكل. نتيجة الاختبارات: 10 اختبارات ناجحة.
- نجح بناء `release/pharmacy-app-release.apk` و`release/pharmacy-app-release.aab`.

