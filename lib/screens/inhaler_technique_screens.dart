import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';
import '../data/inhaler_devices.dart';
import '../widgets/common.dart';

class InhalerDeviceListScreen extends StatelessWidget {
  const InhalerDeviceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryOrder = <String>[];
    final byCategory = <String, List<InhalerDevice>>{};
    for (final device in inhalerDevices) {
      if (!byCategory.containsKey(device.categoryId)) {
        categoryOrder.add(device.categoryId);
        byCategory[device.categoryId] = [];
      }
      byCategory[device.categoryId]!.add(device);
    }

    return PageFrame(
      title: appText('Inhaler Technique Guide', 'دليل استخدام البخاخ'),
      subtitle: appText(
        'Select your device to see its steps',
        'اختر جهازك لعرض خطوات استخدامه',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            color: Color(0xFFF8FAFC),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    appText(
                      'P = requires priming   C = has a dose counter   S = should be shaken before use',
                      'P = يحتاج تركيب أولي   C = يحتوي عداد جرعات   S = يحتاج رجّ قبل الاستخدام',
                    ),
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6),
          for (final categoryId in categoryOrder) ...[
            SectionTitle(
              appText(
                byCategory[categoryId]!.first.categoryEn,
                byCategory[categoryId]!.first.categoryAr,
              ),
            ),
            for (final device in byCategory[categoryId]!)
              _deviceCard(context, device),
          ],
          SectionTitle(appText('General Tips', 'نصائح عامة')),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < inhalerGeneralTips.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == inhalerGeneralTips.length - 1 ? 0 : 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: AppColors.teal,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            appText(
                              inhalerGeneralTips[i].en,
                              inhalerGeneralTips[i].ar,
                            ),
                            style: TextStyle(fontSize: 13.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deviceCard(BuildContext context, InhalerDevice device) => Padding(
    padding: EdgeInsets.only(bottom: 12),
    child: AppCard(
      onTap: () => context.go('/learn/inhaler-technique/${device.id}'),
      child: Row(
        children: [
          Icon(_categoryIcon(device.categoryId), color: AppColors.teal),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appText(device.nameEn, device.nameAr),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  device.quickBreath
                      ? appText(
                          'Inhale quick and deep',
                          'استنشق بسرعة وعمق',
                        )
                      : appText(
                          'Inhale slow and steady',
                          'استنشق ببطء وثبات',
                        ),
                  style: TextStyle(
                    fontSize: 12.5,
                    color: device.quickBreath
                        ? Colors.deepOrange
                        : AppColors.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    if (device.requiresPriming) _badge('P'),
                    if (device.hasDoseCounter) _badge('C'),
                    if (device.requiresShaking) _badge('S'),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: AppColors.muted),
        ],
      ),
    ),
  );

  Widget _badge(String letter) => Padding(
    padding: EdgeInsetsDirectional.only(end: 6),
    child: Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: .12),
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.blue,
        ),
      ),
    ),
  );

  IconData _categoryIcon(String categoryId) => switch (categoryId) {
    'pmdi_manual' => Icons.medication,
    'pmdi_breath' => Icons.touch_app,
    'smi' => Icons.blur_on,
    'dpi_blister' => Icons.grid_view,
    'dpi_reservoir' => Icons.propane_tank_outlined,
    'dpi_capsule' => Icons.circle_outlined,
    _ => Icons.medication,
  };
}

/// Result tiers used to pick the color, icon, headline, and motivational
/// message shown in the save/results dialog based on completion percentage.
enum _ResultTier { perfect, good, fair, low }

class InhalerDeviceDetailScreen extends StatefulWidget {
  const InhalerDeviceDetailScreen({super.key, required this.deviceId});
  final String deviceId;

  @override
  State<InhalerDeviceDetailScreen> createState() =>
      _InhalerDeviceDetailScreenState();
}

class _InhalerDeviceDetailScreenState
    extends State<InhalerDeviceDetailScreen> {
  final Set<int> completedSteps = {};

  void _toggleStep(int index) {
    setState(() {
      if (completedSteps.contains(index)) {
        completedSteps.remove(index);
      } else {
        completedSteps.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final device =
        inhalerDevices.where((d) => d.id == widget.deviceId).firstOrNull;
    final a = AppState.instance.arabic;
    if (device == null) {
      return PageFrame(
        title: appText('Inhaler Technique Guide', 'دليل استخدام البخاخ'),
        subtitle: '',
        child: Text(appText('Device not found.', 'الجهاز غير موجود.')),
      );
    }
    final steps = a ? device.stepsAr : device.stepsEn;
    final total = steps.length;
    final done = completedSteps.length;
    final percent = total == 0 ? 0 : ((done / total) * 100).round();

    return PageFrame(
      title: appText(device.nameEn, device.nameAr),
      subtitle: appText(device.categoryEn, device.categoryAr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            color:
                device.quickBreath ? Color(0xFFFFF7ED) : Color(0xFFEFF6FF),
            child: Row(
              children: [
                Icon(
                  device.quickBreath ? Icons.bolt : Icons.self_improvement,
                  color:
                      device.quickBreath ? Colors.deepOrange : AppColors.blue,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    device.quickBreath
                        ? appText(
                            'Inhale quick and deep',
                            'استنشق بسرعة وعمق',
                          )
                        : appText(
                            'Inhale slow and steady',
                            'استنشق ببطء وثبات',
                          ),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          if (device.requiresPriming ||
              device.hasDoseCounter ||
              device.requiresShaking) ...[
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (device.requiresPriming)
                  _tag(appText('Requires priming', 'يحتاج تركيب أولي (P)')),
                if (device.hasDoseCounter)
                  _tag(
                    appText('Has a dose counter', 'يحتوي عداد جرعات (C)'),
                  ),
                if (device.requiresShaking)
                  _tag(
                    appText('Should be shaken', 'يحتاج رجّ قبل الاستخدام (S)'),
                  ),
              ],
            ),
          ],
          SizedBox(height: 8),
          SectionTitle(appText('Step-by-Step Guide', 'دليل خطوة بخطوة')),
          _progressCard(percent, done, total),
          SizedBox(height: 12),
          ...steps.indexed.map((x) => _stepTile(x.$1, x.$2)),
          SizedBox(height: 8),
          PrimaryButton(
            text: appText('Save my progress', 'حفظ تقدمي'),
            icon: Icons.save_outlined,
            onPressed: total == 0
                ? null
                : () => _showResults(context, steps, percent, done, total),
          ),
          if (device.noteEn != null) ...[
            SizedBox(height: 16),
            AppCard(
              color: Color(0xFFFFFBEB),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.amber.shade800),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(appText(device.noteEn!, device.noteAr!)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _progressCard(int percent, int done, int total) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                appText('Your progress', 'تقدمك'),
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: percent == 100 ? Colors.green : AppColors.blue,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : done / total,
            minHeight: 8,
            backgroundColor: Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation(
              percent == 100 ? Colors.green : AppColors.blue,
            ),
          ),
        ),
        SizedBox(height: 6),
        Text(
          appText(
            '$done of $total steps done',
            'تم إنجاز $done من $total خطوات',
          ),
          style: TextStyle(color: AppColors.muted, fontSize: 12.5),
        ),
      ],
    ),
  );

  Widget _stepTile(int index, String text) {
    final checked = completedSteps.contains(index);
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => _toggleStep(index),
        color: checked ? Color(0xFFF0FDF4) : Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 180),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: checked ? Colors.green : AppColors.border,
                  width: 2,
                ),
              ),
              child: checked
                  ? Icon(Icons.check, color: Colors.white, size: 17)
                  : null,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  decoration: checked ? TextDecoration.lineThrough : null,
                  color: checked ? AppColors.muted : AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResults(
    BuildContext context,
    List<String> steps,
    int percent,
    int done,
    int total,
  ) {
    final a = AppState.instance.arabic;
    final missedIndexes = List.generate(
      total,
      (i) => i,
    ).where((i) => !completedSteps.contains(i)).toList();

    final tier = percent == 100
        ? _ResultTier.perfect
        : percent >= 70
        ? _ResultTier.good
        : percent >= 40
        ? _ResultTier.fair
        : _ResultTier.low;

    final color = switch (tier) {
      _ResultTier.perfect => Colors.green,
      _ResultTier.good => Color(0xFF0787F7),
      _ResultTier.fair => Color(0xFFD97706),
      _ResultTier.low => Color(0xFFDC2626),
    };
    final icon = switch (tier) {
      _ResultTier.perfect => Icons.emoji_events_outlined,
      _ResultTier.good => Icons.thumb_up_outlined,
      _ResultTier.fair => Icons.trending_up,
      _ResultTier.low => Icons.favorite_outline,
    };
    final headline = switch (tier) {
      _ResultTier.perfect => appText(
        'Perfect technique!',
        'تقنية مثالية!',
      ),
      _ResultTier.good => appText('Almost there!', 'أنت قريب جداً!'),
      _ResultTier.fair => appText(
        'Good start — keep practicing',
        'بداية جيدة — واصل التدريب',
      ),
      _ResultTier.low => appText(
        "Don't worry, you'll get it",
        'لا تقلق، ستتقنها',
      ),
    };
    final motivation = switch (tier) {
      _ResultTier.perfect => appText(
        "You followed every step correctly. This is exactly how your inhaler should be used — keep it up at every dose.",
        'اتبعت كل خطوة بشكل صحيح. هذه هي الطريقة الصحيحة تماماً لاستخدام البخاخ — استمر عليها في كل جرعة.',
      ),
      _ResultTier.good => appText(
        "You're using your inhaler well. Review the steps you missed below so every dose is fully effective.",
        'أنت تستخدم البخاخ بشكل جيد. راجع الخطوات التي فاتتك أدناه لضمان فعالية كل جرعة.',
      ),
      _ResultTier.fair => appText(
        "You're on the right track. Missing several steps can reduce how much medicine actually reaches your lungs — go through the missed steps below and try again.",
        'أنت على الطريق الصحيح. تفويت عدة خطوات قد يقلل من كمية الدواء التي تصل فعلياً إلى رئتيك — راجع الخطوات الفائتة أدناه وحاول مجدداً.',
      ),
      _ResultTier.low => appText(
        "Correct technique makes a big difference in how well your medicine works. Take it one step at a time — review the list below, then try the checklist again.",
        'التقنية الصحيحة تُحدث فرقاً كبيراً في مدى فعالية دوائك. خذ الأمر خطوة بخطوة — راجع القائمة أدناه ثم أعد المحاولة.',
      ),
    };

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: a ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(icon, color: color),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  headline,
                  style: TextStyle(fontWeight: FontWeight.w900, color: color),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      Text(
                        appText(
                          '$done of $total steps completed',
                          'تم إنجاز $done من $total خطوات',
                        ),
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14),
                Text(motivation, style: TextStyle(height: 1.45)),
                if (missedIndexes.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    appText('Steps you missed:', 'الخطوات التي فاتتك:'),
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  ...missedIndexes.map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: Color(0xFFDC2626),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${i + 1}. ${steps[i]}',
                              style: TextStyle(height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (missedIndexes.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(appText('Review steps', 'مراجعة الخطوات')),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(appText('Close', 'إغلاق')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String text) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.blue.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.blue,
      ),
    ),
  );
}