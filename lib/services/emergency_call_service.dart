import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_state.dart';
import '../core/localized_values.dart';
import '../repositories/onboarding_repository.dart';
import '../widgets/common.dart';

class EmergencyCallService {
  static Future<void> call(BuildContext context) async {
    final a = AppState.instance.arabic;
    try {
      final contact = await OnboardingRepository().loadEmergencyContact();
      if (!context.mounted) return;
      if (contact == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              a
                  ? 'لم تُضف جهة اتصال للطوارئ بعد. أضفها من الملف الشخصي.'
                  : 'No emergency contact yet. Add one from Profile.',
            ),
          ),
        );
        return;
      }
      if (kIsWeb) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(a ? 'جهة اتصال الطوارئ' : 'Emergency contact'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedPersonName(contact.contactName),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(
                    contact.phoneNumber,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  a
                      ? 'الاتصال الهاتفي غير متاح من نسخة المتصفح. استخدم الرقم الظاهر أو افتح التطبيق على الهاتف.'
                      : 'Phone calls are unavailable in the browser. Use the number shown or open the mobile app.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(a ? 'إغلاق' : 'Close'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.push('/profile/emergency-contact');
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(a ? 'عرض أو تعديل' : 'View or edit'),
              ),
            ],
          ),
        );
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(a ? 'تأكيد الاتصال' : 'Confirm call'),
          content: Text(
            a
                ? 'هل تريد الاتصال بجهة الطوارئ؟'
                : 'Do you want to call the emergency contact?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(a ? 'إلغاء' : 'Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.phone),
              label: Text(a ? 'اتصال' : 'Call'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      final launched = await launchUrl(
        Uri(scheme: 'tel', path: contact.phoneNumber),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) throw StateError('Could not open the phone app');
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appText('Could not start the call.', 'تعذر بدء الاتصال.'),
          ),
        ),
      );
    }
  }
}
