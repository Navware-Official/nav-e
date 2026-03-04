import 'package:flutter/material.dart';
import 'package:nav_e/features/home/home_view.dart';

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
    return HomeView(
      placeId: placeId,
      latParam: latParam,
      lonParam: lonParam,
      labelParam: labelParam,
      zoomParam: zoomParam,
    );
  }
}
