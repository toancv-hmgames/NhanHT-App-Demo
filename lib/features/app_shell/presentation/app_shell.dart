import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:story_reading_app/gen/assets.gen.dart';

import '../../../gen/colors.gen.dart';
import '../../../share/const_value.dart';
import '../../discover/presentation/discover_page.dart';
import '../../library/presentation/library_page.dart';
import 'widgets/nav_item.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        const LibraryPage(),
        const DiscoverPage(),
      ][index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: ColorName.background,
        selectedIndex: index,
        indicatorColor: Colors.transparent,
        elevation: 0,
        onDestinationSelected: (i) {
          if (i < 2) {
            setState(() => index = i);
          }
        },
        destinations: [
          NavItem(
            iconPath: Assets.icons.library,
            label: 'Library',
          ),
          NavItem(
            iconPath: Assets.icons.discovery,
            label: 'Discover',
          ),
          NavItem(
            iconPath: Assets.icons.rewards,
            label: 'Rewards',
          ),
          NavItem(
            iconPath: Assets.icons.profile,
            label: 'Me',
          ),
        ],
      ),
    );
  }
}
