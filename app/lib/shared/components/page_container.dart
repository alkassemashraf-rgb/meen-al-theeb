import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PageContainer extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showBackButton;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool safeArea;

  const PageContainer({
    super.key,
    required this.child,
    this.title,
    this.showBackButton = false,
    this.appBar,
    this.bottomNavigationBar,
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (safeArea) {
      content = SafeArea(child: content);
    }
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar ?? (title != null ? AppBar(
        title: Text(title!),
        automaticallyImplyLeading: showBackButton,
      ) : null),
      bottomNavigationBar: bottomNavigationBar,
      body: content,
    );
  }
}

