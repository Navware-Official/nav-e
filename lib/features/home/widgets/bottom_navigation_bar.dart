import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/theme/colors.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.lightGray, width: 3)),
      ),
      child: BottomAppBar(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Builder(
              builder: (context) => IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.menu, size: 30),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            IconButton(
              tooltip: 'Start Navigation',
              icon: const Icon(Icons.assistant_navigation, size: 30),
              onPressed: () {
                context.go('start-navigation');
              },
            ),
          ],
        ),
      ),
    );
  }
}
