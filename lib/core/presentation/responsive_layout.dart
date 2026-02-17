import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget desktopBody;
  final Widget? mobileBottomNav;
  final Widget? desktopSidebar;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    required this.desktopBody,
    this.mobileBottomNav,
    this.desktopSidebar,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Scaffold(
            body: mobileBody,
            bottomNavigationBar: mobileBottomNav,
          );
        } else {
          return Scaffold(
            body: Row(
              children: [
                ?desktopSidebar,
                Expanded(child: desktopBody),
              ],
            ),
          );
        }
      },
    );
  }
}
