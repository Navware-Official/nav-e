import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/domain/repositories/geocoding_respository.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_bloc.dart';
import 'package:nav_e/features/map_layers/presentation/bloc/map_events.dart';
import 'package:nav_e/features/search/bloc/search_bloc.dart';
import 'home_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MapBloc()..add(MapInitialized())),
        BlocProvider<SearchBloc>(
          create: (ctx) => SearchBloc(ctx.read<IGeocodingRepository>()),
        ),
      ],
      child: const HomeView(),
    );
  }
}
