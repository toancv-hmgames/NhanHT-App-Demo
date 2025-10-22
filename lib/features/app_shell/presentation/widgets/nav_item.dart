import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../gen/colors.gen.dart';

class NavItem extends StatelessWidget {
  final String iconPath;
  final String label;

  const NavItem({super.key, required this.iconPath, required this.label});

  @override
  Widget build(BuildContext context) {
    return NavigationDestination(
      icon: SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        color: ColorName.defaultIcon,
      ),
      selectedIcon: SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        color: ColorName.chooseIcon,
      ),
      label: label,
    );
  }
}
