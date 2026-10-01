import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/accent_color.dart';
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
      _say('Health Connect did not allow Gymfy to write workouts.');
      return;
    }
    await sync.setWriteWorkouts(true);
  });

  Future<void> _setRead(bool on) => _guarded(() async {
    final sync = ref.read(healthConnectSyncProvider);
    if (!on) return sync.setReadBodyweight(false);
    if (!await _ensure(readWeightPermission)) {
      _say('Health Connect did not allow Gymfy to read your weight.');
      return;
    }
    await sync.setReadBodyweight(true);
    // Straight away rather than on the next app start, so switching it on
    // visibly does something.
    final filled = await sync.importBodyweight();
    if (filled != null && filled > 0) {
      _say(
        filled == 1
            ? 'Added 1 weigh-in to your measurements.'
            : 'Added $filled weigh-ins to your measurements.',
      );
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
        title: const Text('Write past workouts?'),
        content: const Text(
          'Adds every finished workout from before you switched this on to '
          'Health Connect, as strength training with its start and end time. '
          'Workouts already there are not added twice.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Write'),
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
        _say('Health Connect is not allowing Gymfy to write workouts.');
        return;
      }
      _say(describeBackfill(result));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
    final missing = [
      if (write && !canWrite) 'write workouts',
      if (read && !canRead) 'read your weight',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            "Android's store for health data, on this phone. Gymfy can add "
            'your finished workouts to it and fill in your bodyweight from a '
            'smart scale. It all stays on the device — Gymfy has no internet '
            'access.',
            style: muted,
          ),
        ),
        ListTile(
          leading: Icon(
            available ? Icons.favorite : Icons.favorite_border,
            color: available ? accent : null,
          ),
          title: const Text('Health Connect'),
          subtitle: Text(asked.hasValue ? availability.label : 'Checking…'),
          trailing: switch (availability) {
            HealthConnectAvailability.notInstalled ||
            HealthConnectAvailability.needsUpdate => TextButton(
              style: TextButton.styleFrom(foregroundColor: accent),
              onPressed: () async {
                final opened = await ref
                    .read(healthConnectBridgeProvider)
                    .openStore();
                if (!opened) _say('Could not open the Play Store.');
              },
              child: Text(
                availability == HealthConnectAvailability.notInstalled
                    ? 'Install'
                    : 'Update',
              ),
            ),
            _ => null,
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.fitness_center),
          title: const Text('Write workouts'),
          subtitle: const Text(
            'Each workout you finish appears as strength training, with its '
            'name, start and end',
          ),
          value: write,
          onChanged: available && !_busy ? _setWrite : null,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.monitor_weight_outlined),
          title: const Text('Read bodyweight'),
          subtitle: const Text(
            "Weigh-ins fill in days where you haven't entered a weight. A "
            'weight you typed is never replaced',
          ),
          value: read,
          onChanged: available && !_busy ? _setRead : null,
        ),
        if (available)
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('Permissions'),
            subtitle: Text(
              missing.isNotEmpty
                  ? 'Health Connect no longer lets Gymfy '
                        '${missing.join(' or ')}'
                  : 'Workouts: ${canWrite ? 'allowed' : 'not allowed'} · '
                        'Weight: ${canRead ? 'allowed' : 'not allowed'}',
              style: missing.isNotEmpty
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
              child: const Text('Grant'),
            ),
          ),
        if (available && write && canWrite)
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Write past workouts'),
            subtitle: const Text(
              'Only workouts finished from now on are written by themselves',
            ),
            trailing: const Icon(Icons.chevron_right),
            enabled: !_busy,
            onTap: _backfill,
          ),
        if (available)
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Manage in Health Connect'),
            subtitle: const Text(
              'Revoke access, or delete what Gymfy wrote there',
            ),
            onTap: () async {
              final opened = await ref
                  .read(healthConnectBridgeProvider)
                  .openHealthConnect();
              if (!opened) _say('Could not open Health Connect.');
            },
          ),
        if (lastError != null && (write || read))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Last sync with Health Connect failed: $lastError',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

/// The snackbar after "Write past workouts".
String describeBackfill(WorkoutSyncResult result) {
  final wrote = switch (result.written) {
    0 => 'No workouts needed writing',
    1 => 'Wrote 1 workout to Health Connect',
    final n => 'Wrote $n workouts to Health Connect',
  };
  final untimed = switch (result.untimed) {
    0 => '',
    1 => ' 1 without a recorded length was left out.',
    final n => ' $n without a recorded length were left out.',
  };
  final failed = result.error == null
      ? ''
      : ' Then it stopped: ${result.error}';
  return '$wrote.$untimed$failed';
}
