import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../shared/providers.dart';
import '../../shared/widgets/buttons.dart';
import 'access_controller.dart';

/// Shown when there's no access: explains why, then either asks again or,
/// when the OS won't ask any more, walks the user to Settings.
class AccessDeniedScreen extends ConsumerStatefulWidget {
  const AccessDeniedScreen({super.key, required this.state});
  final AccessState state;

  @override
  ConsumerState<AccessDeniedScreen> createState() => _AccessDeniedScreenState();
}

class _AccessDeniedScreenState extends ConsumerState<AccessDeniedScreen> {
  bool _busy = false;

  Future<void> _request() async {
    setState(() => _busy = true);
    await ref.read(accessProvider.notifier).request();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final device = ref.watch(deviceServiceProvider);
    final permanent = widget.state.permanentlyDenied;
    final steps = device.isIOS
        ? 'Open Settings, tap Photos, then choose Full Access or Limited Access.'
        : 'Open Settings, tap Permissions, then Photos and videos, and choose Allow.';

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Insets.xxl),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: Insets.xxl),
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: c.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 36,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: Insets.xxl),
                        Semantics(
                          header: true,
                          child: Text(
                            permanent
                                ? 'Photo access is turned off'
                                : 'Photos needs your permission',
                            textAlign: TextAlign.center,
                            style: context.text.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: Insets.md),
                        Text(
                          'Photos only shows what is already on this device. It needs '
                          'permission to read your library, and never uploads or analyses anything.',
                          textAlign: TextAlign.center,
                          style: context.text.bodyMedium?.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                        if (permanent) ...[
                          const SizedBox(height: Insets.xl),
                          Container(
                            padding: const EdgeInsets.all(Insets.lg),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(Radii.lg),
                              border: Border.all(color: c.divider, width: 0.6),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: IconSizes.sm,
                                  color: c.accent,
                                ),
                                const SizedBox(width: Insets.md),
                                Expanded(
                                  child: Text(
                                    steps,
                                    style: context.text.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: Insets.xxxl),
                        if (permanent) ...[
                          AppButton(
                            label: 'Open Settings',
                            icon: Icons.settings_outlined,
                            onPressed: () => ref
                                .read(mediaServiceProvider)
                                .openSystemSettings(),
                          ),
                          const SizedBox(height: Insets.sm),
                          AppTextButton(
                            label: 'Ask again',
                            color: c.textSecondary,
                            onPressed: _busy ? null : _request,
                          ),
                        ] else
                          AppButton(
                            label: 'Access My Photos',
                            icon: Icons.photo_library_outlined,
                            busy: _busy,
                            onPressed: _request,
                          ),
                        const SizedBox(height: Insets.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
