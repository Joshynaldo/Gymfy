import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/data/settings_repository.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../data/health_connect_bridge.dart';
import '../data/health_connect_sync.dart';

/// The Settings section for Health Connect: whether it is there, the two
/// switches, permissions, the backfill, and the way out to revoke or delete.
///
/// Its own widget, in its own feature, so Settings only has to place it.
///
/// Both switches are off until the user turns one on, and turning one on is
/// what asks for its permission — one permission per switch, never both at
/// once, so the Health Connect screen only ever asks for what was just
/// chosen.
class HealthConnectSettingsPanel extends ConsumerStatefulWidget {
  const HealthConnectSettingsPanel({super.key});

  @override
  ConsumerState<HealthConnectSettingsPanel> createState() =>
      _HealthConnectSettingsPanelState();
}

class _HealthConnectSettingsPanelState
    extends ConsumerState<HealthConnectSettingsPanel> {
  late final AppLifecycleListener _lifecycle;

  /// Set while a permission screen or the backfill is running, so a second
  /// tap does not start another beside it.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Everything this panel shows can change while the app is in the
    // background: Health Connect installed from the Play Store, permissions
    // revoked in Health Connect itself. Coming back asks again.
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(healthConnectAvailabilityProvider);
    ref.invalidate(healthConnectGrantedProvider);
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Makes sure [permission] is granted, asking Health Connect if it is not.
  Future<bool> _ensure(String permission) async {
    final granted = await ref.read(healthConnectGrantedProvider.future);
    if (granted.contains(permission)) return true;
    final after = await ref
        .read(healthConnectBridgeProvider)
        .requestPermissions({permission});
    ref.invalidate(healthConnectGrantedProvider);
    return after.contains(permission);
  }

  Future<void> _guarded(Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setWrite(bool on) => _guarded(() async {
    final sync = ref.read(healthConnectSyncProvider);
    if (!on) return sync.setWriteWorkouts(false);
    if (!await _ensure(writeExercisePermission)) {
      _say(_l10n.healthConnectWriteRefused);
      return;
    }
    await sync.setWriteWorkouts(true);
  });

  Future<void> _setRead(bool on) => _guarded(() async {
    final sync = ref.read(healthConnectSyncProvider);
    if (!on) return sync.setReadBodyweight(false);
    if (!await _ensure(readWeightPermission)) {
      _say(_l10n.healthConnectReadRefused);
      return;
    }
    await sync.setReadBodyweight(true);
    // Straight away rather than on the next app start, so switching it on
    // visibly does something.
    final filled = await sync.importBodyweight();
    if (filled != null && filled > 0) {
      _say(_l10n.healthConnectWeighInsAdded(filled));
    }
  });

  /// Asks again for the permissions of whichever switches are on — or both,
  /// if neither is, since then this button is the only way to ask.
  Future<void> _grant({required bool write, required bool read}) =>
      _guarded(() async {
        final wanted = {
          if (write || !read) writeExercisePermission,
          if (read || !write) readWeightPermission,
        };
        await ref.read(healthConnectBridgeProvider).requestPermissions(wanted);
        ref.invalidate(healthConnectGrantedProvider);
      });

  Future<void> _backfill() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => GlassDialog(
        title: Text(context.l10n.healthConnectBackfillTitle),
        content: Text(context.l10n.healthConnectBackfillMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.healthConnectBackfillConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _guarded(() async {
      final result = await ref
          .read(healthConnectSyncProvider)
          .syncWorkouts(backfill: true);
      if (result == null) {
        _say(_l10n.healthConnectWriteNotAllowed);
        return;
      }
      _say(describeBackfill(result, l10n: _l10n));
    });
  }

  /// The strings for snackbars said after an await, when the widget may be
  /// gone; [_say] checks [mounted] before showing one.
  AppLocalizations get _l10n => mounted ? context.l10n : englishLocalizations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final accent = ref.watch(accentColorProvider);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final asked = ref.watch(healthConnectAvailabilityProvider);
    // Until the answer is in, the switches stay disabled and the line says
    // "Checking…" — "not available" would be wrong for a moment on every visit.
    final availability = asked.value ?? HealthConnectAvailability.unsupported;
    final available = availability == HealthConnectAvailability.available;
    final granted = ref.watch(healthConnectGrantedProvider).value ?? const {};
    final write = ref.watch(healthConnectWriteProvider).value ?? false;
    final read = ref.watch(healthConnectReadProvider).value ?? false;
    final lastError = ref
        .watch(rawSettingProvider(healthConnectLastErrorKey))
        .value;

    final canWrite = granted.contains(writeExercisePermission);
    final canRead = granted.contains(readWeightPermission);
    // A switch that is on while Health Connect no longer grants it — revoked
    // in Health Connect's own settings. Said plainly, with the fix next to it.
    final missingWrite = write && !canWrite;
    final missingRead = read && !canRead;
    final missing = missingWrite || missingRead;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(l10n.healthConnectIntro, style: muted),
        ),
        ListTile(
          leading: Icon(
            available ? Icons.favorite : Icons.favorite_border,
            color: available ? accent : null,
          ),
          // The product's name, the same in every language.
          title: const Text('Health Connect'),
          subtitle: Text(
            asked.hasValue
                ? availability.localizedLabel(l10n)
                : l10n.healthConnectChecking,
          ),
          trailing: switch (availability) {
            HealthConnectAvailability.notInstalled ||
            HealthConnectAvailability.needsUpdate => TextButton(
              style: TextButton.styleFrom(foregroundColor: accent),
              onPressed: () async {
                final opened = await ref
                    .read(healthConnectBridgeProvider)
                    .openStore();
                if (!opened) _say(_l10n.healthConnectStoreFailed);
              },
              child: Text(
                availability == HealthConnectAvailability.notInstalled
                    ? l10n.healthConnectInstall
                    : l10n.healthConnectUpdate,
              ),
            ),
            _ => null,
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.fitness_center),
          title: Text(l10n.healthConnectWriteTitle),
          subtitle: Text(l10n.healthConnectWriteSubtitle),
          value: write,
          onChanged: available && !_busy ? _setWrite : null,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.monitor_weight_outlined),
          title: Text(l10n.healthConnectReadTitle),
          subtitle: Text(l10n.healthConnectReadSubtitle),
          value: read,
          onChanged: available && !_busy ? _setRead : null,
        ),
        if (available)
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: Text(l10n.healthConnectPermissionsTitle),
            subtitle: Text(
              missing
                  ? l10n.healthConnectPermissionsMissing(
                      missingWrite && missingRead
                          ? 'both'
                          : missingWrite
                          ? 'write'
                          : 'read',
                    )
                  : l10n.healthConnectPermissionsStatus(
                      canWrite ? 'yes' : 'no',
                      canRead ? 'yes' : 'no',
                    ),
              style: missing
                  ? theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    )
                  : muted,
            ),
            trailing: TextButton(
              style: TextButton.styleFrom(foregroundColor: accent),
              onPressed: _busy || (canWrite && canRead)
                  ? null
                  : () => _grant(write: write, read: read),
              child: Text(l10n.healthConnectGrant),
            ),
          ),
        if (available && write && canWrite)
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(l10n.healthConnectBackfillTile),
            subtitle: Text(l10n.healthConnectBackfillTileSubtitle),
            trailing: const Icon(Icons.chevron_right),
            enabled: !_busy,
            onTap: _backfill,
          ),
        if (available)
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: Text(l10n.healthConnectManageTitle),
            subtitle: Text(l10n.healthConnectManageSubtitle),
            onTap: () async {
              final opened = await ref
                  .read(healthConnectBridgeProvider)
                  .openHealthConnect();
              if (!opened) _say(_l10n.healthConnectOpenFailed);
            },
          ),
        if (lastError != null && (write || read))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              l10n.healthConnectLastError(lastError),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

/// The snackbar after "Write past workouts", in [l10n]'s language (English
/// without it). Up to three sentences: what was written, what was left out,
/// and why it stopped.
String describeBackfill(WorkoutSyncResult result, {AppLocalizations? l10n}) {
  final strings = l10n ?? englishLocalizations;
  final error = result.error;
  return [
    strings.healthConnectBackfillWrote(result.written),
    if (result.untimed > 0)
      strings.healthConnectBackfillUntimed(result.untimed),
    if (error != null) strings.healthConnectBackfillStopped(error),
  ].join(' ');
}
