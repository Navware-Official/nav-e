import 'package:flutter/material.dart';
import 'package:nav_e/core/domain/extensions/query_params.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';

class SearchResultTile extends StatelessWidget {
  final GeocodingResult result;

  const SearchResultTile({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.place),
      title: Text(result.displayName),
      subtitle: Text(result.type),
      onTap: () {
        context.goHomeWithCoords(
          lat: result.lat,
          lon: result.lon,
          label: result.displayName,
          placeId: result.id,
          zoom: 14,
        );
      },
    );
  }
}
