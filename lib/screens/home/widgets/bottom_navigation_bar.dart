import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/bloc/app_state_bloc.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
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
              context.read<AppStateBloc>().add(StartNavigation());
            },
          ),
        ],
      ),
    );
  }
}