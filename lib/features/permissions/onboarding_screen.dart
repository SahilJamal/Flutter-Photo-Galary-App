import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/haptics.dart';
import '../../shared/widgets/buttons.dart';
import '../settings/settings_controller.dart';
import 'access_controller.dart';

/// First run: a short welcome, then why we need access, then the request.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  bool _requesting = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _requestAccess() async {
    Haptics.light();
    setState(() => _requesting = true);
    ref.read(settingsProvider.notifier).completeOnboarding();
    await ref.read(accessProvider.notifier).request();
    if (mounted) setState(() => _requesting = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [_WelcomePage(), _PrivacyPage()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.xxl,
                Insets.sm,
                Insets.xxl,
                Insets.lg,
              ),
              child: Column(
                children: [
                  Semantics(
                    label: 'Page ${_page + 1} of 2',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 2; i++)
                          AnimatedContainer(
                            duration: Motion.medium,
                            curve: Motion.curve,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _page ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _page ? c.textPrimary : c.divider,
                              borderRadius: BorderRadius.circular(Radii.pill),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Insets.xxl),
                  AnimatedSwitcher(
                    duration: Motion.medium,
                    child: _page == 0
                        ? AppButton(
                            key: const ValueKey('continue'),
                            label: 'Continue',
                            onPressed: () => _pages.nextPage(
                              duration: Motion.slow,
                              curve: Motion.emphasized,
                            ),
                          )
                        : AppButton(
                            key: const ValueKey('access'),
                            label: 'Access My Photos',
                            icon: Icons.photo_library_outlined,
                            busy: _requesting,
                            onPressed: _requestAccess,
                          ),
                  ),
                  const SizedBox(height: Insets.xs),
                  SizedBox(
                    height: 44,
                    child: AnimatedOpacity(
                      opacity: _page == 1 ? 1 : 0,
                      duration: Motion.medium,
                      child: IgnorePointer(
                        ignoring: _page != 1,
                        child: AppTextButton(
                          label: 'Not now',
                          color: c.textSecondary,
                          onPressed: () => ref
                              .read(settingsProvider.notifier)
                              .completeOnboarding(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      art: const _Mosaic(),
      title: 'A calmer home\nfor your photos',
      body:
          'Browse every photo and video on this device in a quiet, focused space, '
          'organised by date and album.',
    );
  }
}

class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage();

  @override
  Widget build(BuildContext context) {
    return const _PageLayout(
      title: 'Your library\nstays yours',
      body:
          'To show your photos and videos, Photos needs permission to read your '
          'library. Here is what that means:',
      points: [
        (
          Icons.phone_android_rounded,
          'Stays on this device',
          'Nothing is uploaded, synced or shared unless you choose to share.',
        ),
        (
          Icons.visibility_off_outlined,
          'No analysis',
          'Photos never scans faces or content, and has no analytics.',
        ),
        (
          Icons.tune_rounded,
          'You stay in control',
          'Allow everything or only selected photos, and change it any time in Settings.',
        ),
      ],
    );
  }
}

class _PageLayout extends StatelessWidget {
  const _PageLayout({
    required this.title,
    required this.body,
    this.art,
    this.points = const [],
  });
  final Widget? art;
  final String title;
  final String body;
  final List<(IconData, String, String)> points;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Insets.xxl),
                    if (art != null) ...[
                      Center(child: art!),
                      const SizedBox(height: Insets.huge),
                    ],
                    Semantics(
                      header: true,
                      child: Text(title, style: context.text.headlineMedium),
                    ),
                    const SizedBox(height: Insets.md),
                    Text(
                      body,
                      style: context.text.bodyLarge?.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    for (final p in points) ...[
                      const SizedBox(height: Insets.xl),
                      MergeSemantics(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: c.surfaceMuted,
                                borderRadius: BorderRadius.circular(Radii.md),
                              ),
                              child: Icon(
                                p.$1,
                                size: IconSizes.md,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(width: Insets.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.$2, style: context.text.titleSmall),
                                  const SizedBox(height: 2),
                                  Text(p.$3, style: context.text.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: Insets.xxl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Abstract "photo stack" illustration: soft tiles drifting very slightly.
class _Mosaic extends StatefulWidget {
  const _Mosaic();

  @override
  State<_Mosaic> createState() => _MosaicState();
}

class _MosaicState extends State<_Mosaic> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    final palettes = dark
        ? const [
            [Color(0xFF3B4252), Color(0xFF2A2F3A)],
            [Color(0xFF4A3F35), Color(0xFF2F2924)],
            [Color(0xFF34443B), Color(0xFF242E28)],
            [Color(0xFF3A3F55), Color(0xFF262A3A)],
          ]
        : const [
            [Color(0xFFD9DEE8), Color(0xFFC3CAD8)],
            [Color(0xFFEADFD2), Color(0xFFDCCBB7)],
            [Color(0xFFD5E0D6), Color(0xFFBFD0C2)],
            [Color(0xFFDCDCEB), Color(0xFFC7C8DE)],
          ];
    const tiles = [
      (Offset(-62, -18), Size(118, 150), -0.10, 0),
      (Offset(64, -34), Size(108, 132), 0.08, 1),
      (Offset(-8, 38), Size(150, 112), 0.02, 2),
      (Offset(78, 62), Size(84, 84), -0.06, 3),
    ];
    return ExcludeSemantics(
      child: SizedBox(
        width: 300,
        height: 240,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                for (final (offset, size, angle, i) in tiles)
                  Transform.translate(
                    offset:
                        offset +
                        Offset(0, 4 * math.sin(_c.value * 2 * math.pi + i)),
                    child: Transform.rotate(
                      angle: angle,
                      child: Container(
                        width: size.width,
                        height: size.height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Radii.lg),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: palettes[i],
                          ),
                          border: Border.all(
                            color: context.colors.surface,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.shadow,
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: i == 2
                            ? Align(
                                alignment: const Alignment(-0.6, 0.5),
                                child: Icon(
                                  Icons.wb_sunny_outlined,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  size: 26,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
