import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/nav/navware_auth_service.dart';
import 'package:nav_e/core/theme/spacing.dart';
import 'package:nav_e/features/device_management/bloc/devices_bloc.dart';
import 'package:nav_e/features/offline_maps/cubit/offline_maps_cubit.dart';
import 'package:nav_e/features/offline_maps/cubit/offline_maps_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    context.read<DevicesBloc>().add(LoadDevices());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OfflineMapsCubit>().loadRegions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _DevicesSummary(onManage: () => context.pushNamed('devices')),
          const SizedBox(height: AppSpacing.sm),
          _OfflineMapsSummary(onManage: () => context.pushNamed('offlineMaps')),
          const SizedBox(height: AppSpacing.sm),
          _NavwareAccountSummary(),
          const SizedBox(height: AppSpacing.lg),
          Text('More', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _MoreLinks(),
        ],
      ),
    );
  }
}

// ── Shared summary card ──────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconContainerColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color iconContainerColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10), // off-grid
              decoration: BoxDecoration(
                color: iconContainerColor,
                borderRadius: BorderRadius.circular(10), // off-grid
              ),
              child: Icon(icon, color: iconColor, size: 22), // off-grid
            ),
            const SizedBox(width: 14), // off-grid
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

// ── Devices ──────────────────────────────────────────────────────────────────

class _DevicesSummary extends StatelessWidget {
  const _DevicesSummary({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<DevicesBloc, DevicesState>(
      builder: (context, state) {
        final String subtitle;
        if (state is DeviceLoadInProgress || state is DeviceInitial) {
          subtitle = '…';
        } else if (state is DeviceLoadSuccess) {
          final n = state.devices.length;
          subtitle = n == 0
              ? 'No devices paired'
              : '$n device${n == 1 ? '' : 's'} paired';
        } else {
          subtitle = 'No devices paired';
        }
        return _SummaryCard(
          icon: Icons.devices_outlined,
          iconContainerColor: colorScheme.secondaryContainer,
          iconColor: colorScheme.onSecondaryContainer,
          title: 'Devices',
          subtitle: subtitle,
          actionLabel: 'Manage',
          onAction: onManage,
        );
      },
    );
  }
}

// ── Offline maps ─────────────────────────────────────────────────────────────

class _OfflineMapsSummary extends StatelessWidget {
  const _OfflineMapsSummary({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<OfflineMapsCubit, OfflineMapsState>(
      builder: (context, state) {
        final String subtitle;
        if (state.status == OfflineMapsStatus.initial ||
            state.status == OfflineMapsStatus.loading) {
          subtitle = '…';
        } else if (state.status == OfflineMapsStatus.loaded ||
            state.status == OfflineMapsStatus.downloading) {
          final n = state.regions.length;
          subtitle = n == 0
              ? 'No regions downloaded'
              : '$n region${n == 1 ? '' : 's'} downloaded';
        } else {
          subtitle = 'No regions downloaded';
        }
        return _SummaryCard(
          icon: Icons.download_for_offline_outlined,
          iconContainerColor: colorScheme.tertiaryContainer,
          iconColor: colorScheme.onTertiaryContainer,
          title: 'Offline maps',
          subtitle: subtitle,
          actionLabel: 'Manage',
          onAction: onManage,
        );
      },
    );
  }
}

// ── Navware account ──────────────────────────────────────────────────────────

class _NavwareAccountSummary extends StatefulWidget {
  const _NavwareAccountSummary();

  @override
  State<_NavwareAccountSummary> createState() => _NavwareAccountSummaryState();
}

class _NavwareAccountSummaryState extends State<_NavwareAccountSummary> {
  NavwareUser? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await NavwareAuthService.getStoredUser();
    if (mounted) setState(() { _user = user; _loading = false; });
  }

  Future<void> _signOut() async {
    await NavwareAuthService.logout();
    if (mounted) setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return _SummaryCard(
        icon: Icons.account_circle_outlined,
        iconContainerColor: colorScheme.primaryContainer,
        iconColor: colorScheme.onPrimaryContainer,
        title: 'Navware Account',
        subtitle: '…',
        actionLabel: '',
        onAction: () {},
      );
    }

    return _SummaryCard(
      icon: Icons.account_circle_outlined,
      iconContainerColor: colorScheme.primaryContainer,
      iconColor: colorScheme.onPrimaryContainer,
      title: 'Navware Account',
      subtitle: _user != null ? _user!.email : 'Sign in for premium features',
      actionLabel: _user != null ? 'Sign out' : 'Sign in',
      onAction: _user != null
          ? _signOut
          : () async {
              final result = await context.pushNamed('navwareAuth');
              if (result is NavwareUser && mounted) {
                setState(() => _user = result);
              }
            },
    );
  }
}

// ── More links ───────────────────────────────────────────────────────────────

class _MoreLinks extends StatelessWidget {
  const _MoreLinks();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Trip log'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/log'),
          ),
          Divider(
            height: 1,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
            color: colorScheme.outlineVariant,
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('App settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushNamed('settings'),
          ),
        ],
      ),
    );
  }
}
