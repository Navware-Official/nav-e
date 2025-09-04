import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/domain/repositories/geocoding_repository.dart';
import 'package:nav_e/core/domain/repositories/saved_places_repository.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_cubit.dart';
import 'package:nav_e/features/search/bloc/search_bloc.dart';
import 'home_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SearchBloc>(
          create: (ctx) => SearchBloc(ctx.read<IGeocodingRepository>()),
        ),
        BlocProvider<SavedPlacesCubit>(
          create: (ctx) =>
              SavedPlacesCubit(ctx.read<ISavedPlacesRepository>())
                ..loadPlaces(),
        ),
      ],
      child: const HomeView(),
    );
  }
}
