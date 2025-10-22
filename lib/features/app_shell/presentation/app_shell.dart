import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:story_reading_app/gen/assets.gen.dart';
import '../../../gen/colors.gen.dart';
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
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          // Label đổi màu giống icon:
          labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
                (states) {
              final selected = states.contains(MaterialState.selected);
              return TextStyle(
                color: selected ? ColorName.chooseIcon : ColorName.defaultIcon,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              );
            },
          ),
          // Nếu muốn bỏ nền tròn của item được chọn:
          indicatorColor: Colors.transparent,
        ),

        child: NavigationBar(
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
      ),
    );
  }
}
