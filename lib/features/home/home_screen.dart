import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'
    show MultiBlocProvider, BlocProvider, ReadContext;
import 'package:nav_e/core/services/geocoding_service.dart';
import 'package:nav_e/features/search/bloc/search_bloc.dart';

import '../../core/bloc/map_bloc.dart';
import 'home_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MapBloc>(create: (_) => MapBloc()..add(MapInitialized())),
        BlocProvider<SearchBloc>(
          create: (ctx) => SearchBloc(ctx.read<GeocodingService>()),
        ),
      ],
      child: const HomeView(),
    );
  }
}
