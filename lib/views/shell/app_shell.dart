import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/core/widgets/widgets.dart';
import 'package:warsha_app/views/auth/auth_gate.dart';
import 'package:warsha_app/views/shell/destinations.dart';
import 'package:warsha_app/views/shell/navigation_v_m.dart';
import 'package:warsha_app/view_models/user_v_m.dart';

/// The signed-in frame around every page.
///
/// - Desktop: a grouped sidebar.
/// - Tablet: a navigation rail.
/// - Phone: a bottom bar with the four main pages and "More" for the rest.
///
/// Pages stay alive while switching (IndexedStack), so searches, filters and
/// scroll positions are kept.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final current = context.watch<NavigationVM>().current;
    final pages = IndexedStack(
      index: current.index,
      children: [for (final d in AppDestination.values) d.page],
    );

    if (context.isCompact) {
      final index = AppDestination.primary.indexOf(current);
      return Scaffold(
        body: pages,
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
          child: NavigationBar(
            selectedIndex: index < 0 ? AppDestination.primary.length : index,
            onDestinationSelected: (i) => i < AppDestination.primary.length
                ? context.read<NavigationVM>().go(AppDestination.primary[i])
                : _showMore(context),
            destinations: [
              for (final d in AppDestination.primary)
                NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
              NavigationDestination(
                icon: const Icon(Iconsax.menu_1_copy),
                selectedIcon: const Icon(Iconsax.menu_1),
                label: index < 0 ? current.label : 'More',
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          context.isExpanded ? const _Sidebar() : const _Rail(),
          Expanded(child: pages),
        ],
      ),
    );
  }

  static void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s16),
          child: _NavList(
            destinations: AppDestination.values.where((d) => !AppDestination.primary.contains(d)).toList(),
            onSelected: (_) => Navigator.pop(sheet),
          ),
        ),
      ),
    );
  }
}

/// Desktop sidebar: logo, grouped destinations, sign out.
class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      child: const SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.s24, AppSpacing.s24, AppSpacing.s24, AppSpacing.s16),
              child: BrandLogo(size: 40, showName: true),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.s12),
                child: _NavList(destinations: AppDestination.values),
              ),
            ),
            Divider(),
            Padding(padding: EdgeInsets.all(AppSpacing.s12), child: _SignOutTile()),
          ],
        ),
      ),
    );
  }
}

/// Destinations under their group captions; used by the sidebar and the
/// phone's "More" sheet.
class _NavList extends StatelessWidget {
  const _NavList({required this.destinations, this.onSelected});

  final List<AppDestination> destinations;
  final ValueChanged<AppDestination>? onSelected;

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationVM>();
    final children = <Widget>[];
    NavGroup? group;
    for (final d in destinations) {
      if (d.group != group) {
        group = d.group;
        children.add(Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.s12, children.isEmpty ? AppSpacing.s4 : AppSpacing.s16, AppSpacing.s12, AppSpacing.s4),
          child: AppText.caption(group.label.toUpperCase(), weight: FontWeight.w600),
        ));
      }
      final selected = nav.current == d;
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          dense: true,
          selected: selected,
          leading: Icon(selected ? d.selectedIcon : d.icon, size: 20),
          title: Text(d.label, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          onTap: () {
            nav.go(d);
            onSelected?.call(d);
          },
        ),
      ));
    }
    if (onSelected != null) {
      children
        ..add(const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.s8), child: Divider()))
        ..add(const _SignOutTile());
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _SignOutTile extends StatelessWidget {
  const _SignOutTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Iconsax.logout_copy, size: 20, color: AppStatusColors.errorText),
      title: const Text('Sign out', style: TextStyle(color: AppStatusColors.errorText)),
      onTap: () => _signOut(context),
    );
  }
}

/// Tablet rail: every destination as an icon with its label.
class _Rail extends StatelessWidget {
  const _Rail();

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationVM>();
    return DecoratedBox(
      decoration: const BoxDecoration(border: Border(right: BorderSide(color: AppColors.line))),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: NavigationRail(
                selectedIndex: nav.current.index,
                onDestinationSelected: (i) => nav.go(AppDestination.values[i]),
                labelType: NavigationRailLabelType.all,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
                  child: BrandLogo(size: 40),
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                      child: IconButton(
                        tooltip: 'Sign out',
                        icon: const Icon(Iconsax.logout_copy, color: AppStatusColors.errorText),
                        onPressed: () => _signOut(context),
                      ),
                    ),
                  ),
                ),
                destinations: [
                  for (final d in AppDestination.values)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label, textAlign: TextAlign.center),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _signOut(BuildContext context) async {
  final ok = await confirmAction(
    context,
    title: 'Sign out?',
    message: "You'll need your username and password to sign back in.",
    confirmLabel: 'Sign out',
    icon: Iconsax.logout_copy,
  );
  if (ok && context.mounted) await context.read<UserViewModel>().logout();
}
