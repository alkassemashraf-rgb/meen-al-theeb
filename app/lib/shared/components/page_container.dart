import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PageContainer extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showBackButton;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool safeArea;
  final Gradient? backgroundGradient;

  const PageContainer({
    super.key,
    required this.child,
    this.title,
    this.showBackButton = false,
    this.appBar,
    this.bottomNavigationBar,
    this.safeArea = true,
    this.backgroundGradient,
  });

  @override
  Widget build(BuildContext context) {
    final hasDarkBackground = backgroundGradient != null;

    Widget content = child;
    if (safeArea) {
      content = SafeArea(child: content);
    }

    PreferredSizeWidget? resolvedAppBar;
    if (appBar != null) {
      resolvedAppBar = appBar;
    } else if (title != null) {
      resolvedAppBar = hasDarkBackground
          ? AppBar(
              title: Text(title!, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              automaticallyImplyLeading: showBackButton,
            )
          : AppBar(
              title: Text(title!),
              automaticallyImplyLeading: showBackButton,
            );
    }

    final scaffold = Scaffold(
      backgroundColor:
          hasDarkBackground ? Colors.transparent : AppColors.background,
      extendBodyBehindAppBar: hasDarkBackground && title != null,
      appBar: resolvedAppBar,
      bottomNavigationBar: bottomNavigationBar,
      body: content,
    );

    // Wrap gradient outside Scaffold so it always fills the full screen,
    // regardless of how Scaffold constrains the body on this platform.
    if (hasDarkBackground) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: scaffold,
      );
    }

    return scaffold;
  }
}
