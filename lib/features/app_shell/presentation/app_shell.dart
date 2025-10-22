import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../share/const_value.dart';
import '../../discover/presentation/DiscoverPage.dart';
import '../../library/presentation/library_page.dart';

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
        backgroundColor: backgroundColor,
        selectedIndex: index,
        indicatorColor: Colors.transparent,
        elevation: 0,
        onDestinationSelected: (i) {
          if (i < 2) {
            setState(() => index = i);
          }
        },
        destinations: [
          NavigationDestination(
            icon: SvgPicture.asset(
              'assets/icons/library.svg',
              width: 24,
              height: 24,
              color: defaultIconColor,
            ),
            selectedIcon: SvgPicture.asset(
              'assets/icons/library.svg',
              width: 24,
              height: 24,
              color: chooseIconColor,
            ),
            label: 'Library',
          ),
          NavigationDestination(
              icon: SvgPicture.asset(
                'assets/icons/discovery.svg',
                width: 24,
                height: 24,
                color: defaultIconColor,
              ),
              selectedIcon: SvgPicture.asset(
                'assets/icons/discovery.svg',
                width: 24,
                height: 24,
                color: chooseIconColor,
              ),
              label: 'Discover'),
          NavigationDestination(
              icon: SvgPicture.asset(
                'assets/icons/rewards.svg',
                width: 24,
                height: 24,
              ),
              label: 'Rewards'),
          NavigationDestination(
              icon: SvgPicture.asset(
                'assets/icons/profile.svg',
                width: 24,
                height: 24,
              ),
              label: 'Me'),
        ],
      ),
    );
  }
}
