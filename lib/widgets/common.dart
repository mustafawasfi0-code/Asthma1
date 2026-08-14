import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_state.dart';
import '../core/app_theme.dart';

String appText(String english, String arabic) =>
    AppState.instance.arabic ? arabic : english;

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showNav = true,
  });
  final String title, subtitle;
  final Widget child;
  final bool showNav;
  @override
  Widget build(BuildContext context) {
    final a = AppState.instance.arabic;
    return Directionality(
      textDirection: a ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: const AppBackButton(),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: AppState.instance.toggleLanguage,
              child: Text(a ? 'English' : 'العربية'),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                child: child,
              ),
            ),
          ),
        ),
        bottomNavigationBar: showNav ? AppNav() : null,
      ),
    );
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.fallback = '/'});

  final String fallback;

  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('app_back_button'),
    tooltip: appText('Back', 'رجوع'),
    onPressed: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(fallback);
      }
    },
    icon: const Icon(Icons.arrow_back_ios_new_rounded),
  );
}

class AppNav extends StatelessWidget {
  const AppNav({super.key});

  static const routes = [
    '/',
    '/monitoring',
    '/action-plan',
    '/learn',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _index(GoRouterState.of(context).uri.path);
    final items = [
      (Icons.home_outlined, Icons.home_rounded, appText('Home', 'الرئيسية')),
      (
        Icons.monitor_heart_outlined,
        Icons.monitor_heart,
        appText('Monitoring', 'المتابعة'),
      ),
      (
        Icons.assignment_outlined,
        Icons.assignment,
        appText('Action Plan', 'خطة العمل'),
      ),
      (Icons.menu_book_outlined, Icons.menu_book, appText('Learn', 'تعلم')),
      (Icons.person_outline, Icons.person, appText('Profile', 'الملف')),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7EDF2))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D101828),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final active = selected == index;
              final color = active
                  ? const Color(0xFF0787F7)
                  : const Color(0xFF4B5563);
              return Expanded(
                child: InkWell(
                  onTap: () => context.go(routes[index]),
                  splashColor: const Color(0x170787F7),
                  highlightColor: const Color(0x0D0787F7),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 9, bottom: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          active ? item.$2 : item.$1,
                          color: color,
                          size: 25,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontSize: 11.5,
                            height: 1,
                            fontWeight: active
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  int _index(String path) => path.startsWith('/monitoring')
      ? 1
      : path.startsWith('/action-plan')
      ? 2
      : path.startsWith('/learn') || path.contains('technique')
      ? 3
      : path.startsWith('/profile')
      ? 4
      : 0;
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.onTap,
  });
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    color: color,
    elevation: 1,
    shadowColor: Colors.black12,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon = Icons.arrow_forward,
  });
  final String text;
  final VoidCallback? onPressed;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 20),
        ],
      ),
    ),
  );
}