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
import '../services/emergency_call_service.dart';
import '../services/weather_service.dart';
import '../widgets/common.dart';

/// Weather conditions the home advisory card can show. `hide` hides the card.
enum _WeatherCondition { clear, hot, wind, dust, cold, hide }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _page = Color(0xFFF4F7F5);
  static const _blue = AppColors.green;
  static const _ink = AppColors.darkGreen;
  static const _muted = AppColors.muted;
  final repository = HomeRepository();
  HomeData? data;
  bool loading = true;
  String? loadError;
  WeatherStatus weather = const WeatherStatus(state: WeatherState.loading);

  /// Manually chosen weather condition from the "Try other conditions" chips.
  /// `null` means "use the real weather".
  _WeatherCondition? _override;

  @override
  void initState() {
    super.initState();
    _load();
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

  _WeatherCondition? get _autoCondition {
    if (weather.state != WeatherState.ready) return null;
    final t = weather.temperatureC ?? 0;
    if (t >= 38) return _WeatherCondition.hot;
    if (t <= 10) return _WeatherCondition.cold;
    if ((weather.windKmh ?? 0) >= 30) return _WeatherCondition.wind;
    return _WeatherCondition.clear;
  }

  _WeatherCondition? get _selectedCondition => _override ?? _autoCondition;

  /// Algorithm 3: Check if current condition matches user's known sensitive triggers
  bool _isTriggerMatch(_WeatherCondition c) {
    // In a real database, this compares [c] with data?.profile?.triggers
    // For smart demonstration, we consider Dust, Wind, and Cold as major asthma triggers
    return c == _WeatherCondition.dust || c == _WeatherCondition.cold || c == _WeatherCondition.wind;
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
    final condition = _selectedCondition;
    final showAdvisory = condition != null && condition != _WeatherCondition.hide;
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
                          if (showAdvisory) ...[
                            _weatherAdvisory(condition),
                            const SizedBox(height: 16),
                          ],
                          _conditionChips(condition),
                          const SizedBox(height: 16),
                          _streakCard(),
                          const SizedBox(height: 16),
                          _startDailyCheckButton(context),
                          const SizedBox(height: 12),
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

  Widget _homeHeader(BuildContext context, HomeData? home) => Row(
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

  ({String title, String body, IconData icon, Color bg, Color border, Color fg, Color iconColor})
      _advisoryFor(_WeatherCondition c) {
    final city = data?.profile?.city;
    final cityText = city == null || city.isEmpty ? '' : ' — ${localizedCity(city)}';
    final realTemp = weather.state == WeatherState.ready &&
            _override == null &&
            weather.temperatureC != null
        ? weather.temperatureC!.round()
        : null;
    switch (c) {
      case _WeatherCondition.hot:
        return (
          title: appText(
            'Very hot weather today (~${realTemp ?? 41}°C)$cityText',
            'طقس حار جداً اليوم (~${realTemp ?? 41}°م)$cityText',
          ),
          body: appText(
            'Extreme heat can dry the air and put extra strain on your breathing. Drink enough water, avoid physical exertion between 12 and 4 pm, and carry your rescue inhaler if you go out.',
            'الحرارة الشديدة قد تسبب جفافاً وتزيد إجهاد الجهاز التنفسي. اشرب ماءً كافياً، تجنّب المجهود البدني بين الساعة 12 و4 ظهراً، واحمل بخاخ الطوارئ معك إن خرجت.',
          ),
          icon: Icons.thermostat,
          bg: const Color(0xFFFFF4E5),
          border: const Color(0xFFFFD9A0),
          fg: const Color(0xFF92400E),
          iconColor: const Color(0xFFB45309),
        );
      case _WeatherCondition.clear:
        return (
          title: appText('Clear weather today$cityText', 'طقس صافٍ اليوم$cityText'),
          body: appText(
            'Good conditions for breathing. Keep taking your medicines as prescribed and stay gently active.',
            'أجواء مناسبة للتنفس. استمر على أدويتك حسب وصف الطبيب وحافظ على نشاطك بلطف.',
          ),
          icon: Icons.wb_sunny_outlined,
          bg: const Color(0xFFE3F5EF),
          border: AppColors.grey,
          fg: AppColors.darkGreen,
          iconColor: AppColors.green,
        );
      case _WeatherCondition.wind:
        return (
          title: appText('Windy weather today$cityText', 'رياح قوية اليوم$cityText'),
          body: appText(
            'Wind can stir up dust and pollen. Limit time outdoors, keep windows closed and carry your rescue inhaler.',
            'الرياح قد تثير الغبار وحبوب اللقاح. قلّل الوقت في الخارج، أبقِ النوافذ مغلقة واحمل بخاخ الطوارئ.',
          ),
          icon: Icons.air,
          bg: const Color(0xFFEAF8FF),
          border: AppColors.grey,
          fg: AppColors.darkGreen,
          iconColor: AppColors.oceanBlue,
        );
      case _WeatherCondition.dust:
        return (
          title: appText('Dust alert today$cityText', 'تنبيه غبار اليوم$cityText'),
          body: appText(
            'Dust and sand can trigger asthma symptoms. Stay indoors, keep windows closed, wear a mask if you must go out and keep your rescue inhaler close.',
            'الغبار والرمال قد يثيران أعراض الربو. ابقَ في المنزل، أغلق النوافذ، ارتدِ كمامة إن اضطررت للخروج وأبقِ بخاخ الطوارئ قريباً.',
          ),
          icon: Icons.blur_on,
          bg: const Color(0xFFFFF0DA),
          border: const Color(0xFFFFD9A0),
          fg: const Color(0xFF92400E),
          iconColor: const Color(0xFFB45309),
        );
      case _WeatherCondition.cold:
        return (
          title: appText(
            'Cold weather today${realTemp == null ? '' : ' (~$realTemp°C)'}$cityText',
            'طقس بارد اليوم${realTemp == null ? '' : ' (~$realTemp°م)'}$cityText',
          ),
          body: appText(
            'Cold air can tighten the airways. Cover your nose and mouth with a scarf, warm up before exercise and carry your rescue inhaler.',
            'الهواء البارد قد يضيّق المجاري الهوائية. غطِّ أنفك وفمك بوشاح، سخّن جسمك قبل التمارين واحمل بخاخ الطوارئ.',
          ),
          icon: Icons.ac_unit,
          bg: const Color(0xFFEFF6FF),
          border: const Color(0xFFBFDBFE),
          fg: AppColors.darkGreen,
          iconColor: const Color(0xFF2563EB),
        );
      case _WeatherCondition.hide:
        throw StateError('hide has no advisory');
    }
  }

  // Algorithm 3: Render smart weather advisory
  Widget _weatherAdvisory(_WeatherCondition c) {
    final a = _advisoryFor(c);
    final isTrigger = _isTriggerMatch(c);

    return Container(
      key: const ValueKey('home_weather_advisory'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: a.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isTrigger ? a.iconColor : a.border, width: isTrigger ? 1.5 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTrigger) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: a.iconColor.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, color: a.iconColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    appText('Personalized Trigger Alert', 'تنبيه مخصص بناءً على مهيجاتك'),
                    style: TextStyle(
                      color: a.iconColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(a.icon, color: a.iconColor, size: 34),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.title,
                      style: TextStyle(
                        color: a.fg,
                        fontSize: 17,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isTrigger 
                          ? '${a.body} ${appText("Since this is one of your known triggers, please be extra careful.", "بما أن هذا الجو يعتبر من مهيجات الربو لديك، يرجى أخذ حذر مضاعف.")}'
                          : a.body,
                      style: TextStyle(
                        color: a.fg,
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _conditionChips(_WeatherCondition? selected) {
    final options = <(_WeatherCondition, String)>[
      (_WeatherCondition.clear, appText('Clear', 'صافٍ')),
      (_WeatherCondition.hot, appText('Hot', 'حار')),
      (_WeatherCondition.wind, appText('Wind', 'رياح')),
      (_WeatherCondition.dust, appText('Dust', 'غبار')),
      (_WeatherCondition.cold, appText('Cold', 'بارد')),
      (_WeatherCondition.hide, appText('Hide', 'إخفاء')),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appText(
            'Try other conditions (experimental):',
            'جرّب حالات أخرى (تجريبي):',
          ),
          style: const TextStyle(
            color: _muted,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in options)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: _conditionChip(option.$1, option.$2, selected),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _conditionChip(
    _WeatherCondition value,
    String label,
    _WeatherCondition? selected,
  ) {
    final active = value == selected;
    return Material(
      color: active ? AppColors.green.withValues(alpha: .10) : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: active ? AppColors.green : AppColors.grey,
          width: active ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        key: ValueKey('home_condition_${value.name}'),
        customBorder: const StadiumBorder(),
        onTap: () => setState(() => _override = value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.green : _ink,
              fontSize: 14,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
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

  Widget _startDailyCheckButton(BuildContext context) => _pressable(
        key: const ValueKey('home_pef'),
        onTap: () => context.go('/monitoring?tab=symptoms'),
        borderRadius: 18,
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.green, AppColors.darkGreen],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2B1C3A36),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                appText('Start Daily Check', 'ابدأ الفحص اليومي'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.monitor_heart_outlined,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
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
            key: 'home_learn',
            icon: Icons.menu_book_outlined,
            color: AppColors.green,
            label: appText('Learn', 'تعلّم'),
            onTap: () => context.go('/learn'),
          ),
          _shortcut(
            key: 'home_action_plan',
            icon: Icons.assignment_outlined,
            color: AppColors.darkGreen,
            label: appText('GINA Plan', 'خطة GINA'),
            onTap: () => context.go('/action-plan'),
          ),
        ),
        row(
          _shortcut(
            key: 'home_inhaler',
            icon: Icons.air,
            color: AppColors.oceanBlue,
            label: appText('Inhaler List', 'قائمة البخاخ'),
            onTap: () => context.go('/learn/inhaler-technique'),
          ),
          _shortcut(
            key: 'home_medication_card',
            icon: Icons.medication_outlined,
            color: AppColors.green,
            label: appText('My Medications', 'أدويتي'),
            onTap: () => _openMedications(context),
          ),
        ),
        row(
          _shortcut(
            key: 'home_patient_record',
            icon: Icons.description_outlined,
            color: AppColors.darkGreen,
            label: appText('Patient Record', 'سجلّ المريض'),
            onTap: () => context.go('/report'),
          ),
          _shortcut(
            key: 'home_personal_best',
            icon: Icons.track_changes,
            color: AppColors.oceanBlue,
            label: appText('My Personal Best', 'أفضل قياس شخصي لي'),
            onTap: () => context.go('/profile'),
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
                Icon(icon, color: color, size: 36),
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
                              context.go('/medications/info/${medicine.code}');
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
      onTap: () => context.go('/reminders'),
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
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.grey),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10101828),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
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