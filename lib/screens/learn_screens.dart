import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repositories/health_repository.dart';
import '../repositories/profile_repository.dart';
import '../core/app_theme.dart';
import '../widgets/common.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});
  @override
  Widget build(BuildContext c) => PageFrame(
    title: appText('Learn', 'تعلّم'),
    subtitle: appText(
      'Educational resources for asthma management',
      'مصادر تعليمية لإدارة الربو',
    ),
    child: Column(
      children: [
        _guide(
          c,
          appText('Inhaler Technique Guide', 'دليل استخدام البخاخ'),
          appText(
            'Step-by-step instructions for your device',
            'تعليمات خطوة بخطوة لاستخدام جهازك',
          ),
          Icons.medication,
          AppColors.teal,
          '/learn/inhaler-technique',
        ),
        _guide(
          c,
          appText('How to Measure PEF', 'كيفية قياس ذروة التدفق'),
          appText(
            'Guide to using your Peak Flow Meter',
            'دليل استخدام مقياس ذروة التدفق',
          ),
          Icons.speed,
          AppColors.blue,
          '/learn/pef-technique',
        ),
        SectionTitle(appText('Learn About Asthma', 'تعرّف على الربو')),
        AppCard(
          onTap: () => _showArticle(
            c,
            appText('Understanding Asthma', 'فهم الربو'),
            appText(
              'Asthma is a chronic condition that narrows and inflames the airways. Regular treatment, trigger avoidance, and monitoring help keep it controlled.',
              'الربو حالة مزمنة تسبب تضيق والتهاب مجاري الهواء. يساعد العلاج المنتظم وتجنب المحفزات والمراقبة على إبقائه تحت السيطرة',
            ),
          ),
          child: ListTile(
            leading: Icon(Icons.favorite_outline, color: Colors.red),
            title: Text(appText('Understanding Asthma', 'فهم الربو')),
            trailing: Icon(Icons.arrow_forward),
          ),
        ),
        AppCard(
          onTap: () => _showArticle(
            c,
            appText('Common Triggers', 'المحفزات الشائعة'),
            appText(
              'Common triggers include dust, smoke, pollen, strong smells, cold air, respiratory infections, exercise, and stress.',
              'تشمل المحفزات الشائعة الغبار والدخان وحبوب اللقاح والروائح القوية والهواء البارد والتهابات الجهاز التنفسي والتمارين والتوتر',
            ),
          ),
          child: ListTile(
            leading: Icon(Icons.warning_amber, color: Colors.orange),
            title: Text(appText('Common Triggers', 'المحفزات الشائعة')),
            trailing: Icon(Icons.arrow_forward),
          ),
        ),
        AppCard(
          onTap: () => _showArticle(
            c,
            appText('When to Seek Help', 'متى تطلب المساعدة'),
            appText(
              'Seek urgent medical help for severe breathlessness, difficulty speaking, blue lips, faintness, or symptoms that do not improve after rescue medicine.',
              'اطلب المساعدة الطبية العاجلة عند ضيق التنفس الشديد أو صعوبة الكلام أو ازرقاق الشفاه أو الإغماء أو عدم تحسن الأعراض بعد دواء الإنقاذ',
            ),
          ),
          child: ListTile(
            leading: Icon(Icons.health_and_safety, color: Colors.pink),
            title: Text(appText('When to Seek Help', 'متى تطلب المساعدة')),
            trailing: Icon(Icons.arrow_forward),
          ),
        ),
        AppCard(
          onTap: () => c.go('/community'),
          color: Color(0xFFFDF2F8),
          child: ListTile(
            leading: Icon(Icons.groups, color: AppColors.pink),
            title: Text(appText('Asthma Community', 'مجتمع الربو')),
            subtitle: Text(
              appText(
                'Connect, share your story, and get support',
                'تواصل وشارك قصتك واحصل على الدعم',
              ),
            ),
            trailing: Icon(Icons.arrow_forward),
          ),
        ),
      ],
    ),
  );
  Future<void> _showArticle(BuildContext context, String title, String body) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                SizedBox(height: 16),
                Text(body, style: Theme.of(context).textTheme.bodyLarge),
                SizedBox(height: 20),
                PrimaryButton(
                  text: appText('Close', 'إغلاق'),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _guide(
    BuildContext c,
    String t,
    String s,
    IconData i,
    Color color,
    String r,
  ) => Padding(
    padding: EdgeInsets.only(bottom: 14),
    child: AppCard(
      color: color,
      onTap: () => c.go(r),
      child: Row(
        children: [
          Icon(i, color: Colors.white, size: 36),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(s, style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward, color: Colors.white),
        ],
      ),
    ),
  );
}

class TechniqueScreen extends StatefulWidget {
  const TechniqueScreen({super.key, required this.pef});
  final bool pef;

  @override
  State<TechniqueScreen> createState() => _TechniqueScreenState();
}

class _TechniqueScreenState extends State<TechniqueScreen> {
  final readings = List.generate(3, (_) => TextEditingController());
  bool saving = false;
  bool get pef => widget.pef;

  @override
  void dispose() {
    for (final controller in readings) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> saveHighest(BuildContext context) async {
    final values = readings
        .map((controller) => int.tryParse(controller.text.trim()))
        .toList();
    if (values.any((value) => value == null || value < 1 || value > 1000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appText(
              'Enter three valid readings between 1 and 1000.',
              'أدخل ثلاث قراءات صحيحة بين 1 و1000.',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => saving = true);
    try {
      final highest = values.whereType<int>().reduce((a, b) => a > b ? a : b);
      await HealthRepository().addPeakFlow(highest);
      for (final controller in readings) {
        controller.clear();
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appText(
              'Highest reading saved: $highest',
              'تم حفظ أعلى قراءة: $highest',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appText(
              'Could not save the reading. Try again.',
              'تعذر حفظ القراءة. حاول مرة أخرى.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> openVideo() async {
    final url = Uri.parse(
      pef
          ? 'https://www.youtube.com/results?search_query=how+to+use+peak+flow+meter'
          : 'https://www.youtube.com/results?search_query=correct+inhaler+technique',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appText('Could not open YouTube.', 'تعذر فتح يوتيوب.')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext c) {
    final steps = pef
        ? [
            (
              appText('Get Ready', 'استعد'),
              appText(
                'Stand up straight. Make sure the marker on the peak flow meter is at the bottom of the scale (zero).',
                'قف بشكل مستقيم وتأكد من أن مؤشر مقياس ذروة التدفق في أسفل التدريج (صفر)',
              ),
            ),
            (
              appText('Take a Deep Breath', 'خذ نفساً عميقاً'),
              appText(
                'Take a deep breath in, filling your lungs completely.',
                'خذ شهيقاً عميقاً حتى تمتلئ رئتاك بالكامل',
              ),
            ),
            (
              appText('Blow Hard and Fast', 'انفخ بقوة وسرعة'),
              appText(
                'Place the mouthpiece in your mouth and close your lips tightly around it. Blow out as hard and as fast as you can in a single blow.',
                'ضع القطعة الفموية في فمك وأغلق شفتيك حولها بإحكام ثم انفخ بأقصى قوة وسرعة في نفخة واحدة',
              ),
            ),
            (
              appText('Read the Number', 'اقرأ الرقم'),
              appText(
                'Write down the number you see on the meter.',
                'دوّن الرقم الذي تراه على المقياس',
              ),
            ),
            (
              appText('Repeat', 'كرّر'),
              appText(
                'Repeat these steps two more times (for a total of 3 times).',
                'كرّر هذه الخطوات مرتين إضافيتين بمجموع ثلاث مرات',
              ),
            ),
            (
              appText('Record the Highest', 'سجّل أعلى قراءة'),
              appText(
                'Record the highest of the three readings.',
                'سجّل أعلى قراءة من القراءات الثلاث',
              ),
            ),
          ]
        : [
            (
              appText('Prepare the Inhaler', 'حضّر البخاخ'),
              appText(
                'Remove the cap and shake the inhaler well.',
                'انزع الغطاء ورجّ البخاخ جيداً',
              ),
            ),
            (
              appText('Breathe Out', 'ازفر'),
              appText(
                'Breathe out fully, away from the inhaler.',
                'ازفر بالكامل بعيداً عن البخاخ',
              ),
            ),
            (
              appText('Seal Your Lips', 'أغلق شفتيك'),
              appText(
                'Place the mouthpiece between your teeth and close your lips.',
                'ضع القطعة الفموية بين أسنانك وأغلق شفتيك',
              ),
            ),
            (
              appText('Breathe In Slowly', 'استنشق ببطء'),
              appText(
                'Press the canister once while breathing in slowly and deeply.',
                'اضغط العبوة مرة واحدة مع الاستنشاق ببطء وعمق',
              ),
            ),
            (
              appText('Hold Your Breath', 'احبس أنفاسك'),
              appText(
                'Hold your breath for about 10 seconds.',
                'احبس أنفاسك لنحو 10 ثوانٍ',
              ),
            ),
            (
              appText('Rinse Your Mouth', 'تمضمض'),
              appText(
                'If using a steroid inhaler, rinse your mouth afterward.',
                'إذا كنت تستخدم بخاخ الستيرويد فتمضمض بعده',
              ),
            ),
          ];
    return PageFrame(
      title: pef
          ? appText('How to Measure PEF', 'كيفية قياس ذروة التدفق')
          : appText('Inhaler Technique Guide', 'دليل استخدام البخاخ'),
      subtitle: pef
          ? appText(
              'Guide to using your Peak Flow Meter',
              'دليل استخدام مقياس ذروة التدفق',
            )
          : appText(
              'Step-by-step instructions for your device',
              'تعليمات خطوة بخطوة لاستخدام جهازك',
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pef)
            AppCard(
              color: Color(0xFFEFF6FF),
              child: Text(
                appText(
                  'A Peak Flow Meter measures how fast air comes out of your lungs when you exhale forcefully. It can help you spot asthma symptoms before you feel them.',
                  'يقيس مقياس ذروة التدفق سرعة خروج الهواء من رئتيك عند الزفير بقوة وقد يساعدك على اكتشاف أعراض الربو قبل الشعور بها',
                ),
              ),
            ),
          SectionTitle(appText('Step-by-Step Guide', 'دليل خطوة بخطوة')),
          ...steps.indexed.map(
            (x) => AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: pef ? AppColors.blue : AppColors.teal,
                    foregroundColor: Colors.white,
                    child: Text('${x.$1 + 1}'),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          x.$2.$1,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(x.$2.$2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (pef) ...[
            SectionTitle(appText('Record Your Readings', 'سجّل قراءاتك')),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: readings[0],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: appText('Blow 1', 'النفخة 1'),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: readings[1],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: appText('Blow 2', 'النفخة 2'),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: readings[2],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: appText('Blow 3', 'النفخة 3'),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            PrimaryButton(
              text: appText('Save Highest Reading', 'حفظ أعلى قراءة'),
              onPressed: saving ? null : () => saveHighest(c),
            ),
          ],
          SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: openVideo,
            icon: Icon(Icons.play_circle),
            label: Text(appText('Watch on YouTube', 'المشاهدة على يوتيوب')),
          ),
        ],
      ),
    );
  }
}
