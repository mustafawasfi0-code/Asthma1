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

class InhalerDeviceDetailScreen extends StatelessWidget {
  const InhalerDeviceDetailScreen({super.key, required this.deviceId});
  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final device = inhalerDevices.where((d) => d.id == deviceId).firstOrNull;
    final a = AppState.instance.arabic;
    if (device == null) {
      return PageFrame(
        title: appText('Inhaler Technique Guide', 'دليل استخدام البخاخ'),
        subtitle: '',
        child: Text(
          appText('Device not found.', 'الجهاز غير موجود.'),
        ),
      );
    }
    final steps = a ? device.stepsAr : device.stepsEn;
    return PageFrame(
      title: appText(device.nameEn, device.nameAr),
      subtitle: appText(device.categoryEn, device.categoryAr),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            color: device.quickBreath
                ? Color(0xFFFFF7ED)
                : Color(0xFFEFF6FF),
            child: Row(
              children: [
                Icon(
                  device.quickBreath ? Icons.bolt : Icons.self_improvement,
                  color: device.quickBreath ? Colors.deepOrange : AppColors.blue,
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
          if (device.requiresPriming || device.hasDoseCounter || device.requiresShaking) ...[
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (device.requiresPriming)
                  _tag(
                    appText('Requires priming', 'يحتاج تركيب أولي (P)'),
                  ),
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
          ...steps.indexed.map(
            (x) => Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      child: Text('${x.$1 + 1}'),
                    ),
                    SizedBox(width: 14),
                    Expanded(child: Text(x.$2)),
                  ],
                ),
              ),
            ),
          ),
          if (device.noteEn != null) ...[
            SizedBox(height: 4),
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
