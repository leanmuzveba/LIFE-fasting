import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/page_header.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/settings.dart';
import '../../state/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.onChangeTarget});
  final VoidCallback onChangeTarget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final prefs = ref.watch(notificationPrefsProvider).value;
    if (settings == null || prefs == null) return const Center(child: CircularProgressIndicator());
    final target = prefs.firstWhere((p) => p.type == NotificationType.targetReached);
    final daily = prefs.firstWhere((p) => p.type == NotificationType.dailyReminder);
    final dailyTime = TimeOfDay(hour: daily.hour ?? 20, minute: daily.minute ?? 0);

    Future<void> setPref(NotificationPreference p) async {
      final ok = await ref.read(notificationPrefsProvider.notifier).set(p);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications are turned off for this app in your phone’s settings.')),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PageHeader('Settings'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              const _Section('TIMER'),
              _Card(
                children: [
                  _Row(
                    title: 'Target',
                    subtitle: formatTarget(Duration(minutes: settings.targetMinutes)),
                    trailing: const AppIconView(AppIcon.chevronRight, color: AppColors.muted),
                    onTap: onChangeTarget,
                  ),
                  _SwitchRow(
                    title: '24-hour clock',
                    value: settings.use24HourTime,
                    onChanged: (v) => ref.read(settingsProvider.notifier).change((s) => s.copyWith(use24HourTime: v)),
                  ),
                ],
              ),
              const _Section('NOTIFICATIONS'),
              _Card(
                children: [
                  _SwitchRow(
                    title: 'Target time reached',
                    subtitle: 'A quiet notice when your planned time passes',
                    value: target.enabled,
                    onChanged: (v) => setPref(target.copyWith(enabled: v)),
                  ),
                  _SwitchRow(
                    title: 'Daily reminder',
                    subtitle: daily.enabled
                        ? 'Every day at ${MaterialLocalizations.of(context).formatTimeOfDay(dailyTime, alwaysUse24HourFormat: settings.use24HourTime)}'
                        : 'Off',
                    value: daily.enabled,
                    onChanged: (v) =>
                        setPref(daily.copyWith(enabled: v, hour: dailyTime.hour, minute: dailyTime.minute)),
                  ),
                  if (daily.enabled)
                    _Row(
                      title: 'Reminder time',
                      trailing: const AppIconView(AppIcon.clock, color: AppColors.deep),
                      onTap: () async {
                        final t = await showTimePicker(context: context, initialTime: dailyTime);
                        if (t != null) await setPref(daily.copyWith(hour: t.hour, minute: t.minute));
                      },
                    ),
                ],
              ),
              const _Section('PRIVACY'),
              _Card(
                children: [
                  const _Row(
                    title: 'Your data stays on this phone',
                    subtitle: 'Nothing is uploaded or shared. There are no accounts or ads.',
                  ),
                  _Row(
                    title: 'Delete all data',
                    subtitle: 'Sessions, settings and reminders',
                    danger: true,
                    onTap: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
              const _Section('ABOUT'),
              const _Card(
                children: [
                  _Row(
                    title: 'Not a medical device',
                    subtitle:
                        'This app records time only. Milestones are general estimates and can’t tell what is happening '
                        'in your body. Speak with a qualified healthcare professional before changing how you eat.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) => showAppSheet<void>(
    context,
    (ctx) => Gap16Column(
      children: [
        Semantics(header: true, child: const Text('Delete all data?', style: AppText.title)),
        Text(
          'This removes every session, your settings and any reminders from this phone. It can’t be undone.',
          style: AppText.body.copyWith(color: AppColors.textSecondary),
        ),
        Row(
          children: [
            Expanded(
              child: PillButton(label: 'Cancel', outlined: true, onPressed: () => Navigator.pop(ctx)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                label: 'Delete all',
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(sessionActionsProvider).deleteEverything();
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
    child: Semantics(header: true, child: Text(title, style: AppText.overline)),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: AppShadows.card,
    ),
    clipBehavior: Clip.antiAlias,
    child: Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, color: AppColors.divider),
            children[i],
          ],
        ],
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.title, this.subtitle, this.trailing, this.onTap, this.danger = false});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    minTileHeight: 56,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    title: Text(title, style: AppText.link.copyWith(color: danger ? const Color(0xFFB3261E) : AppColors.text)),
    subtitle: subtitle == null ? null : Text(subtitle!, style: AppText.small),
    trailing: trailing,
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, this.subtitle, required this.value, required this.onChanged});
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    value: value,
    onChanged: onChanged,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    activeTrackColor: AppColors.deep,
    title: Text(title, style: AppText.link.copyWith(color: AppColors.text)),
    subtitle: subtitle == null ? null : Text(subtitle!, style: AppText.small),
  );
}
