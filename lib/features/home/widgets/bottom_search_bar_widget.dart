import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';
import 'package:nav_e/core/domain/repositories/geocoding_repository.dart';
import 'package:nav_e/core/theme/colors.dart';
import 'package:nav_e/features/search/bloc/search_bloc.dart';
import 'package:nav_e/features/search/search_screen.dart';
import 'package:nav_e/widgets/search_bar_widget.dart';

class BottomSearchBarWidget extends StatelessWidget {
  const BottomSearchBarWidget({super.key, required this.onResultSelected});

  final ValueChanged<GeocodingResult> onResultSelected;

  void _showMenuBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Device Management'),
              onTap: () {
                Navigator.pop(context);
                context.pushNamed('devices');
              },
            ),
            ListTile(
              leading: const Icon(Icons.featured_play_list),
              title: const Text('Saved Places'),
              onTap: () {
                Navigator.pop(context);
                context.pushNamed('savedPlaces');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('App Settings'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 26,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Hero(
                tag: 'searchBarHero',
                child: SearchBarWidget(
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (ctx) =>
                              SearchBloc(ctx.read<IGeocodingRepository>()),
                          child: const SearchScreen(),
                        ),
                      ),
                    );
                    if (result != null) {
                      onResultSelected(result);
                    }
                  },
                ),
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: AppColors.lightGray,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            IconButton(
              icon: const Icon(Icons.menu, size: 28),
              tooltip: 'Menu',
              onPressed: () => _showMenuBottomSheet(context),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ],
        ),
      ),
    );
  }
}
