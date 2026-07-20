import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/theme/vajra_theme.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: VajraApp()));
}

class VajraApp extends ConsumerWidget {
  const VajraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'VAJRA',
      debugShowCheckedModeBanner: false,
      theme: VajraTheme.darkTheme,
      // Enforce Dark Theme Only
      themeMode: ThemeMode.dark, 
      routerConfig: router,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
    );
  }
}
