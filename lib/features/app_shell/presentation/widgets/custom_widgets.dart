import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../share/const_value.dart';

Widget navItem({required String iconPath, required String label}) {
  return NavigationDestination(
    icon: SvgPicture.asset(
      iconPath,
      width: 24,
      height: 24,
      color: AppColor.defaultIcon,
    ),
    selectedIcon: SvgPicture.asset(
      iconPath,
      width: 24,
      height: 24,
      color: AppColor.chooseIcon,
    ),
    label: label,
  );
}
