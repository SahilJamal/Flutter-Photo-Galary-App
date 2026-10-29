import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'features/gallery/home_shell.dart';
import 'features/permissions/access_controller.dart';
import 'features/permissions/access_denied_screen.dart';
import 'features/permissions/onboarding_screen.dart';
import 'features/settings/settings_controller.dart';
import 'shared/providers.dart';
import 'shared/widgets/message_view.dart';

class PhotoGalleryApp extends ConsumerWidget {
  const PhotoGalleryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp(
      title: 'Photos',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      themeAnimationDuration: Motion.slow,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        // Respect large text, but cap it where layouts stop being usable.
        return MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.6,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value:
                (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                    .copyWith(
                      statusBarColor: Colors.transparent,
                      systemNavigationBarColor: Colors.transparent,
                      systemNavigationBarContrastEnforced: false,
                    ),
            child: child!,
          ),
        );
      },
      home: const RootGate(),
    );
  }
}

/// Chooses onboarding, the no-access screen or the app, and keeps the
/// library fresh on resume and on system media changes.
class RootGate extends ConsumerStatefulWidget {
  const RootGate({super.key});

  @override
  ConsumerState<RootGate> createState() => _RootGateState();
}

class _RootGateState extends ConsumerState<RootGate> {
  late final AppLifecycleListener _lifecycle;
  Timer? _debounce;
  bool _watching = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  Future<void> _onResume() async {
    await ref.read(accessProvider.notifier).recheck();
    if (ref.read(accessProvider).valueOrNull?.granted ?? false) {
      ref.read(mediaRevisionProvider.notifier).bump();
    }
  }

  void _syncWatching(bool granted) {
    final media = ref.read(mediaServiceProvider);
    if (granted && !_watching) {
      media.startWatching(() {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 600), () {
          if (mounted) ref.read(mediaRevisionProvider.notifier).bump();
        });
      });
      _watching = true;
    } else if (!granted && _watching) {
      media.stopWatching();
      _watching = false;
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _debounce?.cancel();
    if (_watching) ref.read(mediaServiceProvider).stopWatching();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(accessProvider);
    final onboarded = ref.watch(
      settingsProvider.select((s) => s.onboardingDone),
    );
    final state = access.valueOrNull;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncWatching(state?.granted ?? false);
    });

    final Widget child;
    final String key;
    if (state == null && access.hasError) {
      key = 'error';
      child = Scaffold(
        body: MessageView.error(
          message: "Couldn't check photo access.",
          onRetry: () => ref.invalidate(accessProvider),
        ),
      );
    } else if (state == null) {
      key = 'splash';
      child = const Scaffold();
    } else if (state.granted) {
      key = 'home';
      child = const HomeShell();
    } else if (!onboarded) {
      key = 'onboarding';
      child = const OnboardingScreen();
    } else {
      key = 'denied';
      child = AccessDeniedScreen(state: state);
    }

    return AnimatedSwitcher(
      duration: Motion.slow,
      switchInCurve: Motion.curve,
      child: KeyedSubtree(key: ValueKey(key), child: child),
    );
  }
}
