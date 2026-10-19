import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      child: BackScope(
        child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: const AppBackButton(),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.black,
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
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: TextButton(
                onPressed: AppState.instance.toggleLanguage,
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.softGreen,
                  foregroundColor: AppColors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: Text(a ? 'English' : 'العربية'),
              ),
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
      ),
    );
  }
}

/// Makes the system/physical back button behave naturally:
///  1. [onBack] gets the first chance (return true when it handled the press),
///  2. otherwise pops the screen if there is one underneath,
///  3. otherwise (a root tab) goes Home, and Home exits the app.
class BackScope extends StatelessWidget {
  const BackScope({super.key, required this.child, this.onBack});
  final Widget child;
  final bool Function()? onBack;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      if (onBack?.call() == true) return;
      if (context.canPop()) {
        context.pop();
      } else if (GoRouterState.of(context).uri.path != '/') {
        context.go('/');
      } else {
        SystemNavigator.pop();
      }
    },
    child: child,
  );
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
    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A1C3A36),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final active = selected == index;
              return Expanded(
                child: InkWell(
                  onTap: () => context.go(routes[index]),
                  borderRadius: BorderRadius.circular(20),
                  splashColor: AppColors.green.withValues(alpha: .08),
                  highlightColor: AppColors.green.withValues(alpha: .04),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 9, bottom: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: active ? AppGradients.primary : null,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: active
                                ? const [
                                    BoxShadow(
                                      color: Color(0x33007359),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            active ? item.$2 : item.$1,
                            color: active ? Colors.white : AppColors.muted,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active ? AppColors.green : AppColors.muted,
                            fontSize: 11,
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

/// White floating card: rounded corners with a soft, light shadow.
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(5),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(18), child: child),
        ),
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 10),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

/// Green -> Bright Green gradient button. Fills the space its parent gives it
/// (wrap it in a SizedBox to control the size).
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.radius = 16,
  });
  final VoidCallback? onPressed;
  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? AppGradients.primary : null,
        color: enabled ? null : AppColors.grey,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: enabled ? AppShadows.button : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: enabled ? Colors.white : AppColors.muted,
                fontWeight: FontWeight.w800,
                shadows: enabled
                    ? const [
                        Shadow(color: Color(0x66004D3B), blurRadius: 4),
                      ]
                    : null,
              ),
              child: IconTheme.merge(
                data: IconThemeData(
                  color: enabled ? Colors.white : AppColors.muted,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    height: 54,
    child: GradientButton(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 20),
          ],
        ),
      ),
    ),
  );
}