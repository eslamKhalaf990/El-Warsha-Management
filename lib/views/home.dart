import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/controllers/navigation.dart';
import 'package:warsha_app/utils/app_bar_widget.dart';
import 'package:warsha_app/utils/const_values.dart';
import 'package:warsha_app/view_models/user_v_m.dart';
import '../utils/default_text.dart';

// A breakpoint to decide when to switch from mobile to desktop layout
const double kTabletBreakpoint = 720.0;

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder gives us the constraints of the parent widget
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if the screen is wide enough for a side nav
        if (constraints.maxWidth > kTabletBreakpoint) {
          return _buildDesktopLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  /// Builds the layout for wide screens (Tablet/Desktop)
  Widget _buildDesktopLayout(BuildContext context) {
    // Get the navigation state.
    // context.watch() rebuilds this widget when 'page' changes.
    final nav = context.watch<Navigation>();

    return Scaffold(
      // A cleaner background color for the main app body
      body: Padding(
        // Use the same padding as the original
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. The Side Navigation Rail
            const _SideNavRail(),
            const SizedBox(width: 15),

            // 2. The Main Content Area
            Expanded(child: nav.pages[nav.page]),
          ],
        ),
      ),
    );
  }

  /// Builds the layout for narrow screens (Mobile)
  Widget _buildMobileLayout(BuildContext context) {
    // Get the navigation state
    final nav = context.watch<Navigation>();
    // Get the navigation controller to call updatePage
    // context.read() does NOT rebuild, safe to use in callbacks.
    final navNotifier = context.read<Navigation>();

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: const DefaultAppBar(

      ),
      // The body is just the selected page
      body: nav.pages[nav.page],

      // Use a BottomNavigationBar for mobile navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: nav.page,
        onTap: (index) => navNotifier.updatePage(index),
        selectedLabelStyle: TextStyle(color: Theme.of(context).colorScheme.secondary),

        // These settings make it look good with 5 items
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.tertiary,
        unselectedItemColor: Colors.grey.shade600,
        selectedFontSize: 12,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Iconsax.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.category),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.receipt_item),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.profile_2user),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.empty_wallet),
            label: 'Accounting',
          ),
        ],
      ),
    );
  }
}

/// A dedicated widget for the Side Navigation Rail
class _SideNavRail extends StatelessWidget {
  const _SideNavRail();

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<Navigation>();
    final navNotifier = context.read<Navigation>();

    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Logo
          const _Logo(),
          const SizedBox(height: 24),

          // 2. Navigation Items
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _NavigationItem(
                    title: 'Home',
                    icon: Iconsax.home,
                    isSelected: nav.page == 0,
                    onTap: () => navNotifier.updatePage(0),
                  ),
                  _NavigationItem(
                    title: 'Products',
                    icon: Iconsax.box_1,
                    isSelected: nav.page == 1,
                    onTap: () => navNotifier.updatePage(1),
                  ),
                  _NavigationItem(
                    title: 'Orders',
                    icon: Iconsax.receipt_item,
                    isSelected: nav.page == 2,
                    onTap: () => navNotifier.updatePage(2),
                  ),
                  _NavigationItem(
                    title: 'Customers',
                    icon: Iconsax.profile_2user,
                    isSelected: nav.page == 3,
                    onTap: () => navNotifier.updatePage(3),
                  ),
                  _NavigationItem(
                    title: 'Categories',
                    icon: Iconsax.category,
                    isSelected: nav.page == 4,
                    onTap: () => navNotifier.updatePage(4),
                  ),
                  _NavigationItem(
                    title: 'Vendors',
                    icon: Iconsax.people,
                    isSelected: nav.page == 5,
                    onTap: () => navNotifier.updatePage(5),
                  ),
                  _NavigationItem(
                    title: 'Shipping Zones',
                    icon: Iconsax.truck,
                    isSelected: nav.page == 6,
                    onTap: () => navNotifier.updatePage(6),
                  ),
                  _NavigationItem(
                    title: 'Accounting',
                    icon: Iconsax.empty_wallet,
                    isSelected: nav.page == 7,
                    onTap: () => navNotifier.updatePage(7),
                  ),
                ],
              ),
            ),
          ),

          // 3. Log out, pinned to the bottom
          _NavigationItem(
            title: 'Log out',
            icon: Iconsax.logout,
            isSelected: false,
            onTap: () => context.read<UserViewModel>().logout(),
          ),
        ],
      ),
    );
  }
}

/// A dedicated widget for the Logo section
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: Constants.BORDER_RADIUS_100,
            child: Image.asset("assets/images/logo-no-back.png", width: 40),
          ),
          const SizedBox(width: 10),
          const DefaultText(
            txt: "ELWARSHA",
            bold: true,
          ),
        ],
      ),
    );
  }
}


/// A reusable widget for a single navigation item (replaces the InkWell)
class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Using ListTile for semantic correctness and cleaner code
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? theme.colorScheme.tertiary
            : theme.colorScheme.tertiary.withOpacity(0.5),
      ),
      title: DefaultText(
        txt: title,
        bold: true,
        // Optionally change text color when selected
        color: isSelected
            ? theme.colorScheme.secondary
            : theme.colorScheme.onSurface,
      ),
      onTap: onTap,

      // Use built-in ListTile properties for selection
      selected: isSelected,
      selectedTileColor: theme.colorScheme.onPrimary.withAlpha(100),

      // Apply the border radius
      shape: RoundedRectangleBorder(
        borderRadius: Constants.BORDER_RADIUS_20,
      ),
      // Adjust padding as needed
      contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      dense: true,
    );
  }
}