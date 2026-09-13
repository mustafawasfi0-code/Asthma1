import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_state.dart';
import '../core/localized_values.dart';
import '../models/home_data.dart';
import '../models/medication.dart';
import '../models/weather_status.dart';
import '../repositories/home_repository.dart';
import '../services/emergency_call_service.dart';
import '../services/weather_service.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _page = Color(0xFFF3F9FC);
  static const _blue = Color(0xFF0787F7);
  static const _ink = Color(0xFF111827);
  static const _muted = Color(0xFF667085);
  final repository = HomeRepository();
  HomeData? data;
  bool loading = true;
  String? loadError;
  WeatherStatus weather = const WeatherStatus(state: WeatherState.loading);

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

  Widget _actionPlan(BuildContext context) => _pressable(
        key: const ValueKey('home_pef'),
        onTap: () => context.go('/monitoring?tab=symptoms'),
        borderRadius: 28,
        child: Container(
          height: 172,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF16E1AF), Color(0xFF00BE13)],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2B00A73C),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              PositionedDirectional(
                end: -35,
                top: -46,
                child: Container(
                  width: 145,
                  height: 145,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              PositionedDirectional(
                start: -38,
                bottom: -62,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.health_and_safety_outlined,
                    color: Colors.white,
                    size: 36,
                  ),
                  const Spacer(),
                  Text(
                    appText('Daily Check', 'الفحص اليومي'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          appText('Daily checking of your health', 'الفحص اليومي لصحتك'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 15,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
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
                          _actionPlan(context),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: _gradientAction(
                                  context,
                                  key: const ValueKey('home_learn'),
                                  colors: const [
                                    Color(0xFF14B8A6),
                                    Color(0xFF0D9488),
                                  ],
                                  iconColor: const Color(0xFF14B8A6),
                                  icon: Icons.menu_book_outlined,
                                  title: appText('Learn', 'تعلّم'),
                                  subtitle: appText('Educational resources', 'مصادر تعليمية'),
                                  onTap: () => context.go('/learn'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _gradientAction(
                                  context,
                                  key: const ValueKey('home_inhaler'),
                                  colors: const [
                                    Color(0xFFD51CF1),
                                    Color(0xFFA900ED),
                                  ],
                                  iconColor: const Color(0xFFCB42EB),
                                  icon: Icons.monitor_heart_outlined,
                                  title: appText('Use inhaler', 'استخدام البخاخ'),
                                  subtitle: appText('Learn technique', 'تعلم الطريقة'),
                                  onTap: () => context.go('/learn/inhaler-technique?tab=inhaler'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _medications(context, data),
                          const SizedBox(height: 22),
                          _stats(data),
                          const SizedBox(height: 22),
                          _reminders(context, data),
                          const SizedBox(height: 22),
                          _weather(weather, data?.profile?.city),
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
                      ? appText('Hello', 'مرحباً')
                      : appText('Hello, ', 'مرحباً، ') +
                          localizedPersonName(home!.profile!.name),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  appText('Your asthma dashboard', 'لوحة متابعة الربو'),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 25,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
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
          // التعديل هنا: استخدام Flexible و SingleChildScrollView
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
                          color: const Color(0xFFF7FAFC),
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
                                color: const Color(0xFF0A8CF5),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _medications(BuildContext context, HomeData? home) {
    final medicines = home?.medications ?? const [];
    final selected = medicines.isEmpty ? null : medicines.first;
    return _surface(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.medication_outlined,
                color: Color(0xFFD52EEA),
                size: 29,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  appText('My Medications', 'أدويتي'),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                key: const ValueKey('home_edit_medications'),
                onPressed: () {
                  final currentCodes = medicines.map((m) => m.code).toList();
                  context.push(
                    '/onboarding/medications?edit=true',
                    extra: currentCodes,
                  );
                },
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(appText('Edit', 'تعديل')),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF007CD9),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _pressable(
            key: const ValueKey('home_medication_card'),
            onTap: selected == null
                ? () => context.go('/onboarding/medications')
                : medicines.length == 1
                    ? () => context.go('/medications/info/${selected.code}')
                    : () => _openMedicationPicker(context, medicines),
            borderRadius: 18,
            child: Container(
              height: medicines.length > 1 ? 112 : 92,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEFFFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEAF0F4)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0B101828),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: selected == null
                  ? Row(
                      children: [
                        Container(
                          width: 58,
                          height: 66,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF4FD),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Color(0xFF0A8CF5),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            appText(
                              'No medications selected. Tap to add.',
                              'لا توجد أدوية مختارة. اضغط للإضافة.',
                            ),
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 58,
                          height: 66,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A8CF5),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x340078DE),
                                blurRadius: 9,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.medication_outlined,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medicines
                                    .map(
                                      (medicine) => AppState.instance.arabic
                                          ? medicine.nameAr
                                          : medicine.nameEn,
                                    )
                                    .join(
                                      AppState.instance.arabic ? '، ' : ', ',
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                medicines.length > 1
                                    ? appText(
                                        ' medications selected',
                                        '${medicines.length} أدوية مختارة',
                                      )
                                    : AppState.instance.arabic
                                        ? selected.descriptionAr
                                        : selected.descriptionEn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (medicines.length > 1)
                                Text(
                                  '${appText('+', '+')}${medicines.length - 1} ${appText('more', 'أخرى')}',
                                  style: const TextStyle(
                                    color: Color(0xFF0787F7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientAction(
    BuildContext context, {
    required Key key,
    required List<Color> colors,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stats(HomeData? home) => Row(
        children: [
          Expanded(
            child: _stat(
              Icons.air,
              const Color(0xFF0086EA),
              home?.latestPeakFlow?.toString() ?? '--',
              'PEF',
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _stat(
              Icons.medication_outlined,
              const Color(0xFFD52EEA),
              home?.medications.length.toString() ?? '0',
              appText('Medicines', 'أدوية'),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _stat(
              Icons.trending_up,
              const Color(0xFF00C878),
              home?.peakFlows.length.toString() ?? '0',
              appText('Readings', 'قراءات'),
            ),
          ),
        ],
      );

  Widget _stat(IconData icon, Color color, String value, String label) =>
      _surface(
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 130,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

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
                  color: Color(0xFF0098EA),
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
                    color: Color(0xFFE6F5FF),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    reminders.length.toString(),
                    style: const TextStyle(
                      color: Color(0xFF0089ED),
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

  Widget _weather(WeatherStatus status, String? profileCity) {
    final arabic = AppState.instance.arabic;
    final cityText = status.state == WeatherState.ready &&
            (status.cityLabel ?? profileCity) != null &&
            (status.cityLabel ?? profileCity)!.isNotEmpty
        ? localizedCity((status.cityLabel ?? profileCity)!)
        : appText('Current location', 'موقعك الحالي');

    final String tempText;
    final String conditionText;
    final IconData conditionIcon;
    switch (status.state) {
      case WeatherState.loading:
        tempText = appText('Loading…', 'جارٍ التحميل…');
        conditionText = appText('Loading…', 'جارٍ التحميل…');
        conditionIcon = Icons.hourglass_top_outlined;
        break;
      case WeatherState.ready:
        tempText = '${status.temperatureC!.round()}°C';
        conditionText = weatherCodeLabel(status.weatherCode, arabic);
        conditionIcon = _weatherIcon(status.weatherCode);
        break;
      case WeatherState.noInternet:
        tempText = appText('No internet', 'لا يوجد إنترنت');
        conditionText = appText(
          'Connect to the internet',
          'اتصل بالإنترنت',
        );
        conditionIcon = Icons.wifi_off_outlined;
        break;
      case WeatherState.locationDenied:
        tempText = appText('Location denied', 'صلاحية الموقع مرفوضة');
        conditionText = appText(
          'Enable location access',
          'فعّل صلاحية الموقع',
        );
        conditionIcon = Icons.location_disabled_outlined;
        break;
      case WeatherState.locationServiceDisabled:
        tempText = appText('Location is off', 'الموقع مغلق');
        conditionText = appText('Turn on location', 'شغّل خدمة الموقع');
        conditionIcon = Icons.location_off_outlined;
        break;
      case WeatherState.unavailable:
        tempText = appText('Unavailable', 'غير متاح');
        conditionText = appText('Try again later', 'حاول لاحقاً');
        conditionIcon = Icons.error_outline;
        break;
    }

    return KeyedSubtree(
      key: const ValueKey('home_weather'),
      child: _surface(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.cloud_outlined,
                  color: Color(0xFF008FE8),
                  size: 29,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    appText("Today's Weather", 'الطقس اليوم'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (status.state != WeatherState.loading)
                  IconButton(
                    key: const ValueKey('home_weather_refresh'),
                    onPressed: _loadWeather,
                    icon: const Icon(Icons.refresh, size: 20),
                    color: _muted,
                    tooltip: appText('Refresh', 'تحديث'),
                  ),
              ],
            ),
            const SizedBox(height: 17),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEAF8FF), Color(0xFFDFFFF7)],
                ),
                border: Border.all(color: const Color(0xFFCDEEF3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: _muted,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          arabic ? 'موقعك الحالي' : 'Current location',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Expanded(
                        child: _weatherValue(
                          Icons.thermostat_outlined,
                          const Color(0xFFFF5A00),
                          appText('Temperature', 'درجة الحرارة'),
                          tempText,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: _weatherValue(
                          conditionIcon,
                          const Color(0xFF00BD76),
                          appText('Condition', 'حالة الطقس'),
                          conditionText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _weatherIcon(int? code) {
    if (code == null) return Icons.help_outline;
    if (code == 0) return Icons.wb_sunny_outlined;
    if (code <= 3) return Icons.cloud_outlined;
    if (code == 45 || code == 48) return Icons.foggy;
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return Icons.water_drop_outlined;
    }
    if (code >= 71 && code <= 77) return Icons.ac_unit_outlined;
    if (code >= 95) return Icons.thunderstorm_outlined;
    return Icons.cloud_outlined;
  }

  Widget _weatherValue(
    IconData icon,
    Color color,
    String label,
    String value,
  ) =>
      Container(
        height: 104,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .82),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFDDECF2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0B101828),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              height: 28,
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 25,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _medicalDisclaimer() => Container(
        key: const ValueKey('home_disclaimer'),
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F5F8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD8E0E6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFF87919D), size: 25),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appText('Take medical responsibility', 'إخلاء مسؤولية طبي'),
                    style: const TextStyle(
                      color: Color(0xFF374151),
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
                      color: Color(0xFF4B5563),
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
          border: Border.all(color: const Color(0xFFE6EDF2)),
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
