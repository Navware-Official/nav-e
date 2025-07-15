import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),

      body: Expanded(
        child: Image.asset('assets/img/house_cat.jpeg',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.fitWidth,
          alignment: Alignment.bottomCenter,
        ),
      ),

      // This FAB floats above the bottom right
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
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
              icon: const Icon(Icons.settings),
              color: Colors.white,
              onPressed: () => context.goNamed('settings'),
            ),
            IconButton(
              icon: const Icon(Icons.assistant_navigation),
              color: Colors.white,
              onPressed: () => context.goNamed('start_navigation'),
            ),
          ],
        ),
      ),
    );
  }
}
