import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../core/theme/app_theme.dart';

/// A reusable generic loading widget using SpinKitCubeGrid.
class GlobalLoader extends StatelessWidget {
  const GlobalLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      alignment: Alignment.center,
      child: const SpinKitCubeGrid(color: AppTheme.secondaryColor, size: 50.0),
    );
  }
}
