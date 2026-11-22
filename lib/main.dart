import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'ViewModels/theme_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TuSolutionApp()));
}

class TuSolutionApp extends ConsumerStatefulWidget {
  const TuSolutionApp({super.key});

  @override
  ConsumerState<TuSolutionApp> createState() => _TuSolutionAppState();
}

class _TuSolutionAppState extends ConsumerState<TuSolutionApp> {
  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeViewModelProvider);
    return MaterialApp.router(
      title: 'Tu Solution',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      routerConfig: appRouter,
    );
  }
}
