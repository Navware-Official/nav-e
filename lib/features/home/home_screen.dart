import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/core/domain/repositories/geocoding_repository.dart';
import 'package:nav_e/core/domain/repositories/saved_places_repository.dart';
import 'package:nav_e/features/home/home_view.dart';
import 'package:nav_e/features/saved_places/cubit/saved_places_cubit.dart';
import 'package:nav_e/features/search/bloc/search_bloc.dart';

import '../location_preview/cubit/preview_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.placeId,
    this.latParam,
    this.lonParam,
    this.labelParam,
    this.zoomParam,
  });

  final String? placeId;
  final String? latParam;
  final String? lonParam;
  final String? labelParam;
  final String? zoomParam;

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
        BlocProvider<PreviewCubit>(create: (_) => PreviewCubit()),
      ],
      child: HomeView(
        placeId: placeId,
        latParam: latParam,
        lonParam: lonParam,
        labelParam: labelParam,
        zoomParam: zoomParam,
      ),
    );
  }
}
