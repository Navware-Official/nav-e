import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/search_bar_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/img/house_cat.jpeg',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.fitWidth,
              alignment: Alignment.bottomCenter,
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: SearchBarWidget(),
          ),
        ],
      ),

      // This FAB floats above the bottom right
      floatingActionButton: FloatingActionButton(
            onPressed: () => context.goNamed('active_route'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.deepOrange,
        tooltip: 'Start Navigation',
        child: Icon(
          Icons.assistant_navigation,
          color: Colors.deepOrange,
          size: 50,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Bottom bar stays at the bottom, below FAB
      bottomNavigationBar: BottomAppBar(
        height: 60,
        color: Colors.deepOrange,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings, size: 30),
              color: Colors.white,
              onPressed: () => context.goNamed('settings'),
            ),
            IconButton(
              tooltip: 'Start Navigation',
              icon: const Icon(Icons.assistant_navigation, size: 30),
              color: Colors.white,
              onPressed: () => context.goNamed('start_navigation'),
            ),
          ],
        ),
      ),
    );
  }
}
