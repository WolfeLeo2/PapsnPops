import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

extension ColorSchemeStatusColors on ColorScheme {
  Color get success => AppColors.success;
  Color get successContainer => AppColors.successContainer;
  Color get warning => AppColors.warning;
  Color get warningContainer => AppColors.warningContainer;
  Color get info => AppColors.info;
  Color get infoContainer => AppColors.infoContainer;
}
