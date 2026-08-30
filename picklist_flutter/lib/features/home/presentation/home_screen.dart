import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/auth_error_handler.dart';
import '../../../models/pick_area.dart';
import '../../../models/pick_mode.dart';
import '../../../providers/picklist_provider.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/state/auth_provider.dart';
import '../../picklist/presentation/picklist_screen.dart';
import 'widgets/area_plate.dart';
import 'widgets/job_link.dart';

/// Where a run starts.
///
/// It opens straight on customer picks, which run every day, with the areas at
/// the top - two or three people pick at once and the only decision this screen
/// exists to support is "which area do I take", so the areas carry their own
/// numbers and nothing sits above them competing. Amazon stock runs weekly at
/// most and lives at the bottom, one tap away.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool silent = false}) async {
    try {
      await context.read<PicklistProvider>().load(silent: silent);
    } on AuthenticationException catch (error) {
      if (mounted) {
        await AuthErrorHandler.handleWithNotification(context, error.response);
      }
    }
  }

  Future<void> _switchJob(PickMode mode) async {
    try {
      await context.read<PicklistProvider>().setMode(mode);
    } on AuthenticationException catch (error) {
      if (mounted) {
        await AuthErrorHandler.handleWithNotification(context, error.response);
      }
    }
  }

  Future<void> _logOut() async {
    final NavigatorState navigator = Navigator.of(context);
    context.read<PicklistProvider>().reset();
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    await navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (Route<void> route) => false,
    );
  }

  void _openArea(String? area, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PicklistScreen(area: area, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.gutter,
        // The title names the job outright, so it needs no JobTag beside it.
        // The tag earns its place only on the pick list, where the title is a
        // bay code and nothing else says which job is being worked.
        title: Consumer<PicklistProvider>(
          builder: (BuildContext context, PicklistProvider provider, _) =>
              Text(provider.mode.jobName, style: AppTypography.title),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _logOut,
            icon: const Icon(Icons.logout_rounded, size: 20),
            color: AppColors.chalkDim,
            tooltip: 'Log out',
          ),
          AppSpacing.w4,
        ],
      ),
      body: Consumer<PicklistProvider>(
        builder: (BuildContext context, PicklistProvider provider, _) {
          return RefreshIndicator(
            onRefresh: () => _load(silent: true),
            color: AppColors.signal,
            backgroundColor: AppColors.deck,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.sm,
                    AppSpacing.gutter,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(<Widget>[
                      _StatusLine(provider: provider),
                      AppSpacing.h24,
                      ..._areaSection(provider),
                      AppSpacing.h40,
                      JobLink(
                        current: provider.mode,
                        enabled: !provider.isLoading,
                        onSwitch: _switchJob,
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _areaSection(PicklistProvider provider) {
    if (provider.isLoading && !provider.hasLoaded) {
      return const <Widget>[_LoadingBlock()];
    }

    if (provider.errorMessage != null && provider.total == 0) {
      return <Widget>[
        _MessageBlock(
          icon: Icons.wifi_off_rounded,
          headline: 'Cannot reach the server',
          body: provider.errorMessage!,
          action: 'Try again',
          onAction: _load,
        ),
      ];
    }

    final List<PickArea> areas = provider.areas;

    if (areas.isEmpty) {
      return <Widget>[
        _MessageBlock(
          icon: Icons.check_circle_outline_rounded,
          headline: 'Nothing to pick',
          body: 'No ${provider.mode.displayName.toLowerCase()} picks are '
              'waiting. Pull down to check again.',
          tint: AppColors.done,
        ),
      ];
    }

    return <Widget>[
      Text('PICK AN AREA', style: AppTypography.eyebrow),
      AppSpacing.h12,
      for (final PickArea area in areas) ...<Widget>[
        AreaPlate(
          area: area,
          onTap: () => _openArea(area.name, area.name),
        ),
        AppSpacing.h8,
      ],
      AppSpacing.h16,
      _WholeUnitButton(
        remaining: provider.remaining,
        onTap: () => _openArea(null, 'Whole unit'),
      ),
    ];
  }
}

/// One line of run context: what is left, and how fresh the numbers are.
/// Freshness matters because someone else may be working the same list at the
/// same time.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.provider});

  final PicklistProvider provider;

  @override
  Widget build(BuildContext context) {
    final String left =
        provider.remaining == 0 ? 'All picked' : '${provider.remaining} to pick';
    final DateTime? at = provider.lastLoaded;
    final String stamp = at == null
        ? 'loading'
        : 'checked ${at.hour.toString().padLeft(2, '0')}:'
            '${at.minute.toString().padLeft(2, '0')}';

    return Row(
      children: <Widget>[
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: provider.remaining == 0 ? AppColors.done : AppColors.signal,
          ),
        ),
        AppSpacing.w8,
        Text(
          left,
          style: AppTypography.detail.copyWith(color: AppColors.chalk),
        ),
        Text('  ·  $stamp', style: AppTypography.detail),
      ],
    );
  }
}

/// Takes the whole unit in one list, for a quiet day or a single picker.
class _WholeUnitButton extends StatelessWidget {
  const _WholeUnitButton({required this.remaining, required this.onTap});

  final int remaining;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.md,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.md,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            border: Border.all(color: AppColors.rule),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Walk the whole unit',
                  style: AppTypography.label.copyWith(color: AppColors.chalkDim),
                ),
              ),
              Text(
                '$remaining',
                style: AppTypography.bayCode.copyWith(
                  color: AppColors.chalkDim,
                  fontSize: 20,
                ),
              ),
              AppSpacing.w8,
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.chalkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: <Widget>[
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          AppSpacing.h16,
          Text('Reading the picklist', style: AppTypography.detail),
        ],
      ),
    );
  }
}

class _MessageBlock extends StatelessWidget {
  const _MessageBlock({
    required this.icon,
    required this.headline,
    required this.body,
    this.action,
    this.onAction,
    this.tint = AppColors.chalkFaint,
  });

  final IconData icon;
  final String headline;
  final String body;
  final String? action;
  final VoidCallback? onAction;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 40, color: tint),
          AppSpacing.h16,
          Text(headline, style: AppTypography.title),
          AppSpacing.h8,
          Text(body, style: AppTypography.detail, textAlign: TextAlign.center),
          if (action != null) ...<Widget>[
            AppSpacing.h24,
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: AppColors.signal),
              child: Text(
                action!,
                style: AppTypography.label.copyWith(color: AppColors.signal),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
