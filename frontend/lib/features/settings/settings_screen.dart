import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/ruva_kit.dart';
import '../../core/widgets/ruva_logo.dart';
import '../../core/widgets/sheet.dart';
import '../../domain/settings.dart';
import '../kitchen/kitchen_review_screen.dart';
import '../../state/providers.dart';

String unitsLabel(AppLocalizations l, UnitSystem u) => u == UnitSystem.metric ? l.unitsMetric : l.unitsImperial;

String dietLabel(AppLocalizations l, DietPreference d) => switch (d) {
  DietPreference.none => l.dietNone,
  DietPreference.vegetarian => l.dietVegetarian,
  DietPreference.vegan => l.dietVegan,
  DietPreference.pescatarian => l.dietPescatarian,
  DietPreference.halal => l.dietHalal,
};

String allergenLabel(AppLocalizations l, Allergen a) => switch (a) {
  Allergen.eggs => l.allergenEggs,
  Allergen.dairy => l.allergenDairy,
  Allergen.peanuts => l.allergenPeanuts,
  Allergen.treeNuts => l.allergenTreeNuts,
  Allergen.gluten => l.allergenGluten,
  Allergen.soy => l.allergenSoy,
  Allergen.fish => l.allergenFish,
  Allergen.shellfish => l.allergenShellfish,
  Allergen.sesame => l.allergenSesame,
};

/// Settings (RUVA design): profile card, preferences, optional reminders,
/// privacy & data, about & safety.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.onChangeTarget});
  final VoidCallback onChangeTarget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    final prefs = ref.watch(notificationPrefsProvider).value;
    if (settings == null || prefs == null) return const Center(child: CircularProgressIndicator());
    final l = context.l10n;
    NotificationPreference pref(NotificationType t) => prefs.firstWhere((p) => p.type == t);
    final target = pref(NotificationType.targetReached);
    final daily = pref(NotificationType.dailyReminder);
    final water = pref(NotificationType.waterReminder);
    final review = pref(NotificationType.monthlyReview);
    final dailyTime = TimeOfDay(hour: daily.hour ?? 20, minute: daily.minute ?? 0);
    void change(AppSettings Function(AppSettings) edit) => ref.read(settingsProvider.notifier).change(edit);

    Future<void> setPref(NotificationPreference p) async {
      final ok = await ref.read(notificationPrefsProvider.notifier).set(p);
      if (!ok && context.mounted) showRuvaSnack(context, l.settingsNotificationsBlocked);
    }

    final allergies = settings.allergies.isEmpty
        ? l.allergiesNone
        : (settings.allergies.toList()..sort((a, b) => a.index - b.index)).map((a) => allergenLabel(l, a)).join(', ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(header: true, child: Text(l.navSettings, style: AppText.title.copyWith(fontSize: 30))),
            ),
            const RuvaLogo(size: 40, semanticLabel: null),
          ],
        ),
        const SizedBox(height: 20),
        _ProfileCard(settings: settings, onTap: () => _editName(context, settings.userName)),
        const SizedBox(height: 26),
        _SectionLabel(l.settingsPreferences),
        _Group(
          children: [
            _NavRow(
              icon: Icons.straighten,
              title: l.settingsUnits,
              value: unitsLabel(l, settings.units),
              onTap: () => _pickOne<UnitSystem>(
                context,
                title: l.settingsUnits,
                options: UnitSystem.values,
                current: settings.units,
                label: (u) => unitsLabel(l, u),
                onSelected: (u) => change((s) => s.copyWith(units: u)),
              ),
            ),
            _NavRow(
              icon: Icons.eco_outlined,
              title: l.settingsDiet,
              value: dietLabel(l, settings.diet),
              onTap: () => _pickOne<DietPreference>(
                context,
                title: l.settingsDiet,
                options: DietPreference.values,
                current: settings.diet,
                label: (d) => dietLabel(l, d),
                onSelected: (d) => change((s) => s.copyWith(diet: d)),
              ),
            ),
            _NavRow(
              icon: Icons.error_outline,
              title: l.settingsAllergies,
              value: allergies,
              onTap: () => showAppSheet<void>(context, (_) => const _AllergiesSheet()),
            ),
            _NavRow(
              icon: Icons.timer_outlined,
              title: l.settingsTarget,
              value: formatTarget(Duration(minutes: settings.targetMinutes)),
              onTap: onChangeTarget,
            ),
            _ToggleRow(
              title: l.settings24h,
              value: settings.use24HourTime,
              onChanged: (v) => change((s) => s.copyWith(use24HourTime: v)),
            ),
          ],
        ),
        const SizedBox(height: 26),
        _SectionLabel(l.settingsRemindersOptional),
        _Group(
          children: [
            _ToggleRow(
              title: l.settingsTargetReached,
              subtitle: l.settingsTargetReachedSub,
              value: target.enabled,
              onChanged: (v) => setPref(target.copyWith(enabled: v)),
            ),
            _ToggleRow(
              title: l.settingsDailyReminder,
              subtitle: daily.enabled
                  ? l.settingsEveryDayAt(
                      MaterialLocalizations.of(context)
                          .formatTimeOfDay(dailyTime, alwaysUse24HourFormat: settings.use24HourTime),
                    )
                  : null,
              value: daily.enabled,
              onChanged: (v) => setPref(daily.copyWith(enabled: v, hour: dailyTime.hour, minute: dailyTime.minute)),
            ),
            if (daily.enabled)
              _NavRow(
                icon: Icons.schedule,
                title: l.settingsReminderTime,
                onTap: () async {
                  final t = await showTimePicker(context: context, initialTime: dailyTime);
                  if (t != null) await setPref(daily.copyWith(hour: t.hour, minute: t.minute));
                },
              ),
            _ToggleRow(
              title: l.settingsWaterReminders,
              subtitle: l.settingsWaterRemindersSub,
              value: water.enabled,
              onChanged: (v) => setPref(water.copyWith(enabled: v)),
            ),
            _ToggleRow(
              title: l.settingsMonthlyReview,
              subtitle: l.settingsMonthlyReviewSub,
              value: review.enabled,
              onChanged: (v) => setPref(review.copyWith(enabled: v)),
            ),
            _NavRow(
              icon: Icons.fact_check_outlined,
              title: l.settingsReviewNow,
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const KitchenReviewScreen())),
            ),
          ],
        ),
        const SizedBox(height: 26),
        _SectionLabel(l.settingsPrivacy),
        _Group(
          children: [
            _NavRow(icon: Icons.lock_outline, title: l.settingsDataStays, subtitle: l.settingsDataStaysSub),
            _NavRow(
              icon: Icons.delete_outline,
              title: l.settingsDeleteAll,
              subtitle: l.settingsDeleteAllSub,
              danger: true,
              onTap: () => _confirmDelete(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 26),
        _SectionLabel(l.settingsAboutSafety),
        _Group(
          children: [
            _NavRow(
              icon: Icons.menu_book_outlined,
              title: l.settingsHowItWorks,
              onTap: () => _info(context, l.settingsHowItWorks, l.settingsHowItWorksBody),
            ),
            _NavRow(
              icon: Icons.health_and_safety_outlined,
              title: l.settingsNotMedical,
              onTap: () => _info(context, l.settingsNotMedical, l.settingsNotMedicalSub),
            ),
            _NavRow(
              icon: Icons.restaurant_menu_outlined,
              title: l.settingsFoodData,
              onTap: () => _info(context, l.settingsFoodData, l.settingsFoodDataSub),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(l.settingsFooter, textAlign: TextAlign.center, style: AppText.small),
      ],
    );
  }

  Future<void> _pickOne<T>(
    BuildContext context, {
    required String title,
    required List<T> options,
    required T current,
    required String Function(T) label,
    required ValueChanged<T> onSelected,
  }) => showAppSheet<void>(
    context,
    (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(title, style: AppText.title.copyWith(fontSize: 22))),
        const SizedBox(height: 8),
        for (final o in options)
          ListTile(
            contentPadding: EdgeInsets.zero,
            minTileHeight: 52,
            selected: o == current,
            title: Text(label(o), style: AppText.body.copyWith(fontSize: 16)),
            trailing: Icon(
              o == current ? Icons.check_circle : Icons.circle_outlined,
              color: o == current ? AppColors.primary : AppColors.muted,
            ),
            onTap: () {
              onSelected(o);
              Navigator.pop(ctx);
            },
          ),
      ],
    ),
  );

  Future<void> _info(BuildContext context, String title, String body) => showAppSheet<void>(
    context,
    (_) => Gap16Column(
      children: [
        Semantics(header: true, child: Text(title, style: AppText.title.copyWith(fontSize: 22))),
        Text(body, style: AppText.body),
      ],
    ),
  );

  Future<void> _editName(BuildContext context, String current) =>
      showAppSheet<void>(context, (_) => _NameSheet(initial: current));

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) => showAppSheet<void>(
    context,
    (ctx) => Gap16Column(
      children: [
        Semantics(header: true, child: Text(ctx.l10n.deleteAllTitle, style: AppText.title)),
        Text(ctx.l10n.deleteAllBody, style: AppText.body.copyWith(color: AppColors.textSecondary)),
        Row(
          children: [
            Expanded(
              child: PillButton(label: ctx.l10n.cancel, outlined: true, onPressed: () => Navigator.pop(ctx)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                label: ctx.l10n.deleteAll,
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.settings, required this.onTap});
  final AppSettings settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = settings.userName.trim();
    final initials = name.isEmpty
        ? null
        : name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
    final since = settings.memberSince;
    return ForestCard(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: '${name.isEmpty ? l.profileAddName : name}. ${l.profileEditHint}',
        excludeSemantics: true,
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.cream, shape: BoxShape.circle),
              child: initials == null
                  ? const Icon(Icons.person_outline, color: AppColors.primary, size: 30)
                  : Text(initials, style: AppText.title.copyWith(fontSize: 22, color: AppColors.primary)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (since != null)
                    MonoLabel(
                      l.profileMemberSince(DateFormat('MMM y').format(since.toLocal())),
                      color: AppColors.accent,
                      size: 10,
                    ),
                  const SizedBox(height: 6),
                  Text(
                    name.isEmpty ? l.profileAddName : name,
                    style: AppText.title.copyWith(fontSize: 22, color: AppColors.white),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}

class _NameSheet extends ConsumerStatefulWidget {
  const _NameSheet({required this.initial});
  final String initial;

  @override
  ConsumerState<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends ConsumerState<_NameSheet> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Gap16Column(
      children: [
        Semantics(header: true, child: Text(l.profileTitle, style: AppText.title)),
        Text(l.profileOptional, style: AppText.small),
        RuvaTextField(controller: _name, label: l.profileNameLabel, autofocus: true),
        PrimaryButton(
          label: l.save,
          onPressed: () async {
            await ref.read(settingsProvider.notifier).change((s) => s.copyWith(userName: _name.text.trim()));
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}

class _AllergiesSheet extends ConsumerWidget {
  const _AllergiesSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final selected = ref.watch(settingsProvider).value?.allergies ?? const {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(l.settingsAllergies, style: AppText.title.copyWith(fontSize: 22))),
        const SizedBox(height: 6),
        Text(l.allergiesHint, style: AppText.small),
        const SizedBox(height: 8),
        for (final a in Allergen.values)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            value: selected.contains(a),
            title: Text(allergenLabel(l, a), style: AppText.body.copyWith(fontSize: 16)),
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .change((s) => s.copyWith(allergies: v! ? {...s.allergies, a} : ({...s.allergies}..remove(a)))),
          ),
        const SizedBox(height: 8),
        PrimaryButton(label: l.done, onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 6, bottom: 12),
    child: Semantics(header: true, child: MonoLabel(text)),
  );
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => RuvaCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.divider),
          children[i],
        ],
      ],
    ),
  );
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.icon, required this.title, this.value, this.subtitle, this.onTap, this.danger = false});

  final IconData icon;
  final String title;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: [title, ?value, ?subtitle].join(', '),
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              IconBubble(
                icon: icon,
                size: 42,
                background: danger ? const Color(0xFFFCE3DE) : AppColors.primary,
                foreground: danger ? AppColors.errorText : AppColors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.link.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: danger ? AppColors.errorText : AppColors.text,
                      ),
                    ),
                    if (subtitle != null) Text(subtitle!, style: AppText.small),
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value!,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
              ],
              if (onTap != null) ...[const SizedBox(width: 8), const Icon(Icons.chevron_right, color: AppColors.muted)],
            ],
          ),
        ),
      ),
    ),
  );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.title, required this.value, required this.onChanged, this.subtitle});

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.link.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.text),
                      ),
                      const SizedBox(height: 3),
                      Text(subtitle ?? l.settingsCurrentState(value ? l.on : l.off), style: AppText.small),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: AppColors.accent,
                  activeThumbColor: AppColors.primary,
                  inactiveTrackColor: AppColors.divider,
                  inactiveThumbColor: AppColors.white,
                  trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
