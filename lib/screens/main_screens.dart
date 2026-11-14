import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../core/localized_values.dart';
import '../models/home_data.dart';
import '../models/medication.dart';
import '../models/weather_status.dart';
import '../repositories/home_repository.dart';
import '../repositories/reminder_repository.dart';
import '../services/emergency_call_service.dart';
import '../services/notification_service.dart';
import '../services/weather_service.dart';
import '../widgets/common.dart';

/// Weather situations the home weather card gives advice for.
enum _WeatherCondition { clear, hot, wind, cold, wet }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _page = AppColors.background;
  static const _blue = AppColors.green;
  static const _ink = AppColors.darkGreen;
  static const _muted = AppColors.muted;
  final repository = HomeRepository();
  HomeData? data;
  bool loading = true;
  String? loadError;
  WeatherStatus weather = const WeatherStatus(state: WeatherState.loading);

  @override
  void initState() {
    super.initState();
    NotificationService.requestPermission().whenComplete(_syncNotifications);
    _load();
  }

  /// Makes sure every saved reminder has a scheduled phone notification
  /// (covers fresh installs, new logins and reminders edited elsewhere).
  Future<void> _syncNotifications() async {
    try {
      await NotificationService.syncReminders(await ReminderRepository().loadAll());
    } catch (_) {}
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        loading = true;
        loadError = null;
      });
    }
    try {
      final value = await repository.load();
      if (mounted) setState(() => data = value);
    } catch (_) {
      if (mounted) {
        setState(
          () => loadError = appText(
            'Could not load your data. Pull down to retry.',
            'تعذر تحميل بياناتك. اسحب للأسفل للمحاولة مجدداً.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
      unawaited(_loadWeather());
    }
  }

  Future<void> _loadWeather() async {
    if (mounted) {
      setState(() => weather = const WeatherStatus(state: WeatherState.loading));
    }
    final result = await WeatherService.fetch(fallbackCity: data?.profile?.city);
    if (mounted) setState(() => weather = result);
  }

  // ---------------------------------------------------------------------
  // Derived state
  // ---------------------------------------------------------------------

  Set<DateTime> get _followUpDays {
    final days = <DateTime>{};
    for (final row in data?.peakFlows ?? const <Map<String, dynamic>>[]) {
      final d = DateTime.tryParse(row['measured_at']?.toString() ?? '')
          ?.toLocal();
      if (d != null) days.add(DateTime(d.year, d.month, d.day));
    }
    return days;
  }

  /// The daily check counts as done once a peak-flow reading exists today.
  bool get _dailyCheckDone {
    final now = DateTime.now();
    return _followUpDays.contains(DateTime(now.year, now.month, now.day));
  }
  
  /// Check if it's late in the day (Algorithm 8)
  bool get _isLateForCheck {
    return DateTime.now().hour >= 16; // After 4:00 PM
  }

  /// Consecutive days with at least one reading. A streak stays alive until
  /// the end of today, so it starts counting from yesterday if today is empty.
  int get _streak {
    final days = _followUpDays;
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    if (!days.contains(cursor)) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    var count = 0;
    while (days.contains(cursor)) {
      count++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return count;
  }

  /// Advice bucket derived from the real, current weather.
  _WeatherCondition? get _condition {
    if (weather.state != WeatherState.ready) return null;
    final t = weather.temperatureC ?? 0;
    final code = weather.weatherCode ?? 0;
    if (t >= 38) return _WeatherCondition.hot;
    if (t <= 10) return _WeatherCondition.cold;
    if ((weather.windKmh ?? 0) >= 30) return _WeatherCondition.wind;
    if (code == 45 || code == 48 || (code >= 51 && code <= 99)) {
      return _WeatherCondition.wet;
    }
    return _WeatherCondition.clear;
  }

  String _dateLine() {
    final n = DateTime.now();
    const daysEn = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const monthsEn = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const daysAr = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    const monthsAr = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    final h = n.hour % 12 == 0 ? 12 : n.hour % 12;
    final time =
        '${h.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
    return AppState.instance.arabic
        ? '${daysAr[n.weekday - 1]}، ${n.day} ${monthsAr[n.month - 1]} $time ${n.hour < 12 ? 'ص' : 'م'}'
        : '${daysEn[n.weekday - 1]}, ${monthsEn[n.month - 1]} ${n.day} · $time ${n.hour < 12 ? 'AM' : 'PM'}';
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final showTasks = data != null && !_dailyCheckDone;
    return Directionality(
      textDirection: AppState.instance.arabic
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _page,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: RefreshIndicator(
                onRefresh: _load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                      sliver: SliverList.list(
                        children: [
                          _homeHeader(context, data),
                          if (loading) ...[
                            const SizedBox(height: 10),
                            const LinearProgressIndicator(minHeight: 3),
                          ],
                          if (loadError != null) ...[
                            const SizedBox(height: 12),
                            _errorBanner(),
                          ],
                          const SizedBox(height: 20),
                          if (showTasks) ...[
                            _tasksCard(context),
                            const SizedBox(height: 16),
                          ],
                          _weatherCard(),
                          const SizedBox(height: 16),
                          _streakCard(),
                          const SizedBox(height: 16),
                          _shortcutGrid(context),
                          const SizedBox(height: 22),
                          _reminders(context, data),
                          const SizedBox(height: 22),
                          _medicalDisclaimer(),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: const AppNav(),
      ),
    );
  }

  Widget _homeHeader(BuildContext context, HomeData? home) => Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
      decoration: BoxDecoration(
        gradient: AppGradients.mint,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  home?.profile?.name == null
                      ? appText('Hello 👋', 'مرحباً 👋')
                      : '${appText('Hello, ', 'مرحباً ')}'
                          '${localizedPersonName(home!.profile!.name)} 👋',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 25,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateLine(),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: AppState.instance.toggleLanguage,
            style: TextButton.styleFrom(
              foregroundColor: _blue,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(AppState.instance.arabic ? 'English' : 'العربية'),
          ),
        ],
      ),
    );

  // ---------------------------------------------------------------------
  // New sections
  // ---------------------------------------------------------------------

  // Algorithm 8: Smart Time-based Task Reminder
  Widget _tasksCard(BuildContext context) {
    final isLate = _isLateForCheck;
    final cardBg = isLate ? const Color(0xFFFFF4F4) : Colors.white;
    final cardBorder = isLate ? const Color(0xFFFFD1D6) : AppColors.grey;
    final iconColor = isLate ? const Color(0xFFE11D35) : AppColors.green;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10101828),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isLate ? Icons.notification_important_rounded : Icons.assignment_outlined,
                color: iconColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                 isLate 
    ? appText('Alert: Daily check missing!', 'تنبيه: لم تقم بالفحص اليومي!') 
    : appText("Today's Tasks", 'مهام اليوم'),
                  style: TextStyle(
                    color: isLate ? const Color(0xFF9D0615) : _ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (isLate) ...[
            const SizedBox(height: 6),
            Text(
              appText(
                'Consistency prevents asthma attacks. Please take 2 minutes to record your symptoms now.',
                'الالتزام يمنع نوبات الربو. يرجى تخصيص دقيقتين لتسجيل قراءاتك الآن.',
              ),
              style: TextStyle(
                color: const Color(0xFFC72439),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            key: const ValueKey('home_task_daily_check'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.go('/monitoring?tab=symptoms'),
            child: Row(
              children: [
                Checkbox(
                  value: false,
                  activeColor: iconColor,
                  side: BorderSide(color: isLate ? iconColor : Colors.grey, width: 2),
                  onChanged: (_) =>
                      context.go('/monitoring?tab=symptoms'),
                ),
                Expanded(
                  child: Text(
                    appText('Complete Daily Check', 'إجراء الفحص اليومي'),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Weather card (live data from the device location / profile city)
  // ---------------------------------------------------------------------

  IconData _weatherIcon(int? code) {
    if (code == null || code == 0) return Icons.wb_sunny_outlined;
    if (code <= 2) return Icons.cloud_queue;
    if (code == 3) return Icons.cloud_outlined;
    if (code == 45 || code == 48) return Icons.blur_on;
    if (code >= 51 && code <= 67) return Icons.water_drop_outlined;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 80 && code <= 82) return Icons.water_drop_outlined;
    if (code >= 95) return Icons.thunderstorm_outlined;
    return Icons.cloud_outlined;
  }

  ({String body, Color bg, Color fg, Color accent}) _adviceFor(
    _WeatherCondition c,
  ) {
    switch (c) {
      case _WeatherCondition.hot:
        return (
          body: appText(
            'Extreme heat can strain your breathing. Drink water, avoid exertion from 12 to 4 pm and carry your rescue inhaler.',
            'الحرارة الشديدة قد تزيد إجهاد التنفس. اشرب ماءً كافياً، تجنّب المجهود بين 12 و4 ظهراً واحمل بخاخ الطوارئ.',
          ),
          bg: const Color(0xFFFFF4E5),
          fg: const Color(0xFF92400E),
          accent: const Color(0xFFB45309),
        );
      case _WeatherCondition.cold:
        return (
          body: appText(
            'Cold air can tighten your airways. Cover your nose and mouth and carry your rescue inhaler.',
            'الهواء البارد قد يضيّق المجاري الهوائية. غطِّ أنفك وفمك واحمل بخاخ الطوارئ.',
          ),
          bg: AppColors.softOcean,
          fg: AppColors.darkGreen,
          accent: AppColors.green,
        );
      case _WeatherCondition.wind:
        return (
          body: appText(
            'Wind can stir up dust and pollen. Limit time outdoors and keep windows closed.',
            'الرياح قد تثير الغبار وحبوب اللقاح. قلّل الوقت في الخارج وأبقِ النوافذ مغلقة.',
          ),
          bg: const Color(0xFFFFF4E5),
          fg: const Color(0xFF92400E),
          accent: const Color(0xFFB45309),
        );
      case _WeatherCondition.wet:
        return (
          body: appText(
            'Damp or stormy weather can trigger symptoms. Keep your rescue inhaler close.',
            'الطقس الرطب أو العاصف قد يثير الأعراض. أبقِ بخاخ الطوارئ قريباً منك.',
          ),
          bg: AppColors.softOcean,
          fg: AppColors.darkGreen,
          accent: AppColors.green,
        );
      case _WeatherCondition.clear:
        return (
          body: appText(
            'Good conditions for breathing. Keep taking your medicines as prescribed.',
            'أجواء مناسبة للتنفس. استمر على أدويتك حسب وصف الطبيب.',
          ),
          bg: AppColors.softGreen,
          fg: AppColors.darkGreen,
          accent: AppColors.green,
        );
    }
  }

  Widget _weatherCard() {
    final arabic = AppState.instance.arabic;

    if (weather.state == WeatherState.loading) {
      return _surface(
        padding: const EdgeInsets.all(20),
        child: Row(
          key: const ValueKey('home_weather_loading'),
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: 14),
            Text(
              appText('Getting your local weather…', 'جارٍ جلب طقس منطقتك…'),
              style: const TextStyle(
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final condition = _condition;
    if (weather.state != WeatherState.ready || condition == null) {
      final message = switch (weather.state) {
        WeatherState.noInternet => appText(
          'No internet connection.',
          'لا يوجد اتصال بالإنترنت.',
        ),
        WeatherState.locationDenied => appText(
          'Location permission is off. Allow it to see your local weather.',
          'إذن الموقع مغلق. اسمح به لعرض طقس منطقتك.',
        ),
        WeatherState.locationServiceDisabled => appText(
          'Turn on location services to see your local weather.',
          'فعّل خدمة الموقع لعرض طقس منطقتك.',
        ),
        _ => appText(
          'Weather is unavailable right now.',
          'الطقس غير متاح حالياً.',
        ),
      };
      return _surface(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
        child: Row(
          key: const ValueKey('home_weather_error'),
          children: [
            const Icon(Icons.cloud_off_outlined, color: _muted, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            IconButton(
              tooltip: appText('Retry', 'إعادة المحاولة'),
              onPressed: _loadWeather,
              icon: const Icon(Icons.refresh, color: AppColors.green),
            ),
          ],
        ),
      );
    }

    final advice = _adviceFor(condition);
    final temp = (weather.temperatureC ?? 0).round();
    final city = data?.profile?.city;
    final cityText = city == null || city.isEmpty ? null : localizedCity(city);
    final wind = weather.windKmh?.round();
    final details = [
      if (cityText != null) cityText,
      if (wind != null) appText('Wind $wind km/h', 'الرياح $wind كم/س'),
    ].join('  •  ');

    return Container(
      key: const ValueKey('home_weather_card'),
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
      decoration: BoxDecoration(
        color: advice.bg,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _weatherIcon(weather.weatherCode),
                  color: advice.accent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '$temp°C',
                        style: const TextStyle(
                          color: AppColors.black,
                          fontSize: 34,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      weatherCodeLabel(weather.weatherCode, arabic),
                      style: TextStyle(
                        color: advice.fg,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (details.isNotEmpty)
                      Text(
                        details,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: appText('Refresh', 'تحديث'),
                onPressed: _loadWeather,
                icon: Icon(Icons.refresh, color: advice.accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Text(
              advice.body,
              style: TextStyle(
                color: advice.fg,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakCard() => _surface(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        child: Column(
          key: const ValueKey('home_streak'),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFFF5A00),
                  size: 42,
                ),
                const SizedBox(width: 10),
                Text(
                  '$_streak',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              appText(
                'days of consecutive follow-up',
                'أيام متابعة متتالية',
              ),
              style: const TextStyle(
                color: _muted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appText(
                'Every day of follow-up brings you closer to understanding your asthma better.',
                'كل يوم متابعة يقرّبك من فهم ربوك بشكل أفضل.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      );

  void _openMedications(BuildContext context) {
    final medicines = data?.medications ?? const <Medication>[];
    if (medicines.isEmpty) {
      context.push('/onboarding/medications?edit=true', extra: <String>[]);
    } else {
      _openMedicationPicker(context, medicines);
    }
  }

  Widget _shortcutGrid(BuildContext context) {
    Widget row(Widget first, Widget second) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(child: first),
              const SizedBox(width: 12),
              Expanded(child: second),
            ],
          ),
        );
    return Column(
      children: [
        row(
          _shortcut(
            key: 'home_pef',
            icon: Icons.monitor_heart_outlined,
            color: AppColors.green,
            label: appText('Start Daily Check', 'ابدأ الفحص اليومي'),
            onTap: () => context.go('/monitoring?tab=symptoms'),
          ),
          _shortcut(
            key: 'home_learn',
            icon: Icons.menu_book_outlined,
            color: AppColors.green,
            label: appText('Learn', 'تعلّم'),
            onTap: () => context.go('/learn'),
          ),
        ),
        row(
          _shortcut(
            key: 'home_medication_card',
            icon: Icons.medication_outlined,
            color: AppColors.green,
            label: appText('My Medications', 'أدويتي'),
            onTap: () => _openMedications(context),
          ),
          _shortcut(
            key: 'home_patient_record',
            icon: Icons.description_outlined,
            color: AppColors.darkGreen,
            label: appText('Patient Record', 'سجلّ المريض'),
            onTap: () => context.push('/report'),
          ),
        ),
      ],
    );
  }

  Widget _shortcut({
    required String key,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) =>
      _pressable(
        key: ValueKey(key),
        onTap: onTap,
        borderRadius: 24,
        child: _surface(
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 118,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color, size: 29),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _errorBanner() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD9A0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined, color: Color(0xFFB45309)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loadError!,
                style: const TextStyle(color: Color(0xFF92400E)),
              ),
            ),
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              color: const Color(0xFFB45309),
            ),
          ],
        ),
      );

  void _openMedicationPicker(BuildContext context, List<Medication> medicines) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                appText('My selected medications', 'أدويتي المختارة'),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: medicines.map(
                      (medicine) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: Material(
                          color: const Color(0xFFF3F7F5),
                          borderRadius: BorderRadius.circular(17),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.green,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(
                                Icons.medication_outlined,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              AppState.instance.arabic
                                  ? medicine.nameAr
                                  : medicine.nameEn,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(
                              AppState.instance.arabic
                                  ? medicine.descriptionAr
                                  : medicine.descriptionEn,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              context.push('/medications/info/${medicine.code}');
                            },
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.push(
                    '/onboarding/medications?edit=true',
                    extra: medicines.map((m) => m.code).toList(),
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(appText('Edit medications', 'تعديل الأدوية')),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _reminders(BuildContext context, HomeData? home) {
    final reminders = home?.reminders ?? const [];
    return _pressable(
      key: const ValueKey('home_reminders'),
      onTap: () => context.push('/reminders'),
      borderRadius: 24,
      child: _surface(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: AppColors.green,
                  size: 27,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    appText("Today's Reminders", 'تذكيرات اليوم'),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3F5EF),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    reminders.length.toString(),
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (reminders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Text(
                  appText('No reminders for today', 'لا توجد تذكيرات اليوم'),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              ...reminders.indexed.expand(
                (entry) => [
                  _reminderRow(entry.$2),
                  if (entry.$1 != reminders.length - 1)
                    const SizedBox(height: 17),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _reminderRow(HomeReminder reminder) => Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0DA),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFFFF5A00),
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              reminder.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              reminder.time,
              style: const TextStyle(
                color: _muted,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );

  Widget _medicalDisclaimer() => Container(
        key: const ValueKey('home_disclaimer'),
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F5F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.grey),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.muted, size: 25),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appText('Take medical responsibility', 'إخلاء مسؤولية طبي'),
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    appText(
                      'This app supports self-management and does not replace medical advice. In an emergency, contact your doctor immediately.',
                      'هذا التطبيق لدعم الإدارة الذاتية ولا يحل محل المشورة الطبية. في الطوارئ، اتصل بطبيبك فوراً.',
                    ),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _surface({
    required Widget child,
    required EdgeInsetsGeometry padding,
  }) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: AppShadows.soft,
        ),
        child: child,
      );

  Widget _pressable({
    Key? key,
    required Widget child,
    required VoidCallback onTap,
    required double borderRadius,
  }) =>
      Material(
        key: key,
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white.withValues(alpha: .16),
          highlightColor: Colors.white.withValues(alpha: .08),
          onTap: onTap,
          child: child,
        ),
      );
}

class ActionPlanScreen extends StatelessWidget {
  const ActionPlanScreen({super.key});
  @override
  Widget build(BuildContext c) => PageFrame(
        title: appText('Asthma Action Plan', 'خطة التعامل مع الربو'),
        subtitle: appText(
          'Your guide to managing symptoms',
          'دليلك للتعامل مع الأعراض',
        ),
        child: Column(
          children: [
            _zone(
              appText('Green Zone: Doing Well', 'المنطقة الخضراء: الحالة جيدة'),
              appText(
                'Breathing is good. No cough or wheeze.',
                'التنفس جيد، ولا يوجد سعال أو صفير',
              ),
              appText(
                'Take controller medicines as prescribed.',
                'خذ أدوية التحكم حسب وصف الطبيب',
              ),
              Colors.green,
              Icons.check_circle,
            ),
            _zone(
              appText('Yellow Zone: Caution', 'المنطقة الصفراء: انتباه'),
              appText(
                'Cough, wheeze, chest tightness, waking at night.',
                'سعال أو صفير أو ضيق في الصدر أو استيقاظ ليلاً',
              ),
              appText(
                'Use rescue inhaler and monitor peak flow.',
                'استخدم بخاخ الإنقاذ وراقب ذروة التدفق',
              ),
              Colors.amber,
              Icons.warning,
            ),
            _zone(
              appText('Red Zone: Medical Alert', 'المنطقة الحمراء: إنذار طبي'),
              appText(
                'Severe shortness of breath or medicines are not helping.',
                'ضيق تنفس شديد أو أن الأدوية لا تساعد',
              ),
              appText(
                'Use rescue medicine and get medical help now.',
                'استخدم دواء الإنقاذ واطلب المساعدة الطبية فوراً',
              ),
              Colors.red,
              Icons.emergency,
            ),
            AppCard(
              onTap: () => EmergencyCallService.call(c),
              child: ListTile(
                leading: Icon(Icons.phone, color: Colors.red),
                title: Text(
                  appText('Emergency Contact', 'جهة اتصال الطوارئ'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  appText('Call Emergency Contact', 'الاتصال بجهة الطوارئ'),
                ),
                trailing: Icon(Icons.arrow_forward),
              ),
            ),
          ],
        ),
      );
  Widget _zone(String t, String s, String a, Color color, IconData icon) =>
      Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: AppCard(
          color: color.withValues(alpha: .08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              Text(
                appText('Symptoms', 'الأعراض'),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(s),
              SizedBox(height: 12),
              Text(
                appText('Actions (Next Steps)', 'الإجراءات (الخطوات التالية)'),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(a),
            ],
          ),
        ),
      );
}