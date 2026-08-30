import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/auth_error_handler.dart';
import '../../../models/pick_area.dart';
import '../../../models/pick_item.dart';
import '../../../providers/picklist_provider.dart';
import '../../home/presentation/widgets/job_link.dart';
import 'widgets/bay_bar.dart';
import 'widgets/pick_row.dart';

/// The working list for one area of the unit, or for the whole unit.
///
/// Picked lines stay exactly where they are. The old screen dropped a line the
/// instant it was ticked, which meant a picker filtering for outstanding work
/// watched their list dissolve under them and lost their place in the aisle.
/// Here the list only changes when the picker asks it to - "Hide picked" sets
/// aside what is done at that moment, and anything picked after that stays put
/// until they ask again.
class PicklistScreen extends StatefulWidget {
  const PicklistScreen({
    super.key,
    required this.area,
    required this.title,
  });

  /// Area to show, or null for the whole unit.
  final String? area;

  final String title;

  @override
  State<PicklistScreen> createState() => _PicklistScreenState();
}

class _PicklistScreenState extends State<PicklistScreen> {
  /// Lines the picker has explicitly set aside. Nothing else ever removes a line
  /// from the list mid-run.
  final Set<String> _setAside = <String>{};

  Future<void> _refresh() async {
    try {
      await context.read<PicklistProvider>().load(silent: true);
      if (mounted) setState(_setAside.clear);
    } on AuthenticationException catch (error) {
      if (mounted) {
        await AuthErrorHandler.handleWithNotification(context, error.response);
      }
    }
  }

  Future<void> _toggle(PickItem item) async {
    final PicklistProvider provider = context.read<PicklistProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    unawaited(HapticFeedback.mediumImpact());
    await provider.toggle(item.id);

    final String? error = provider.errorMessage;
    if (error != null) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not save that pick. $error'),
            backgroundColor: AppColors.alert,
          ),
        );
      provider.clearError();
    }
  }

  void _hidePicked(List<PickItem> visible) {
    setState(() {
      _setAside.addAll(
        visible.where((PickItem i) => i.isPicked).map((PickItem i) => i.id),
      );
    });
  }

  void _showAll() => setState(_setAside.clear);

  @override
  Widget build(BuildContext context) {
    return Consumer<PicklistProvider>(
      builder: (BuildContext context, PicklistProvider provider, _) {
        final List<PickItem> all = provider.itemsForArea(widget.area);
        final List<PickItem> visible = all
            .where((PickItem item) => !_setAside.contains(item.id))
            .toList();
        final int pickedInView =
            visible.where((PickItem i) => i.isPicked).length;

        return Scaffold(
          appBar: _appBar(all, provider),
          bottomNavigationBar: _listControls(visible, pickedInView),
          body: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.signal,
            backgroundColor: AppColors.deck,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _emptyState(all.isEmpty),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      0,
                      AppSpacing.gutter,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        _rows(visible, provider),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _appBar(List<PickItem> all, PicklistProvider provider) {
    final int total = all.length;
    final int left = all.where((PickItem i) => !i.isPicked).length;
    final double progress = total == 0 ? 0 : (total - left) / total;

    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              widget.title.toUpperCase(),
              style: AppTypography.bayCode,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          JobTag(mode: provider.mode),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            0,
            AppSpacing.gutter,
            AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              Text(
                left == 0 ? 'All picked' : '$left left',
                style: AppTypography.detail.copyWith(
                  color: left == 0 ? AppColors.done : AppColors.signal,
                ),
              ),
              Text('  ·  $total lines', style: AppTypography.detail),
              AppSpacing.w16,
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.pill,
                  child: SizedBox(
                    height: 3,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.rule,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        left == 0 ? AppColors.done : AppColors.signal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bay bars interleaved with rows, so the list reads as the walk it is.
  List<Widget> _rows(List<PickItem> visible, PicklistProvider provider) {
    final List<Widget> widgets = <Widget>[];
    String? currentBay;

    for (int i = 0; i < visible.length; i++) {
      final PickItem item = visible[i];

      if (item.location != currentBay) {
        currentBay = item.location;
        final List<PickItem> inBay = visible
            .where((PickItem other) => other.location == currentBay)
            .toList();
        widgets.add(
          BayBar(
            bay: item.bay,
            area: PickArea.of(item.location),
            remaining: inBay.where((PickItem b) => !b.isPicked).length,
            total: inBay.length,
            showArea: widget.area == null,
          ),
        );
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: PickRow(
            item: item,
            isBusy: provider.isInFlight(item.id),
            onToggle: () => _toggle(item),
          ),
        ),
      );
    }

    return widgets;
  }

  /// Sits under the list rather than floating over it, so it never covers the
  /// last row of a bay. Only appears when there is something to set aside or
  /// bring back.
  Widget? _listControls(List<PickItem> visible, int pickedInView) {
    final bool canHide = pickedInView > 0;
    final bool canRestore = _setAside.isNotEmpty;
    if (!canHide && !canRestore) return null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.deck,
        border: Border(top: BorderSide(color: AppColors.rule)),
      ),
      child: Row(
        children: <Widget>[
          if (canRestore)
            TextButton(
              onPressed: _showAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.chalkDim,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                'Show all',
                style: AppTypography.label.copyWith(color: AppColors.chalkDim),
              ),
            ),
          const Spacer(),
          if (canHide)
            FilledButton(
              onPressed: () => _hidePicked(visible),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deckHigh,
                foregroundColor: AppColors.chalk,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.md,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              child: Text(
                'Hide $pickedInView picked',
                style: AppTypography.label,
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(bool areaIsEmpty) {
    final String headline = areaIsEmpty ? 'Nothing here' : 'Bay walked';
    final String body = areaIsEmpty
        ? 'No picks waiting in ${widget.title}.'
        : 'Everything showing is picked and set aside.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 40,
            color: AppColors.done,
          ),
          AppSpacing.h16,
          Text(headline, style: AppTypography.title),
          AppSpacing.h8,
          Text(body, style: AppTypography.detail, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
