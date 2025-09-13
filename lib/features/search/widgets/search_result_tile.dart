import 'package:flutter/material.dart';
import 'package:nav_e/core/domain/entities/geocoding_result.dart';

class SearchResultTile extends StatelessWidget {
  final GeocodingResult result;
  final ValueChanged<GeocodingResult>? onSelected;

  const SearchResultTile({super.key, required this.result, this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.place),
      title: Text(result.displayName),
      subtitle: Text(result.type),
      onTap: () {
        FocusScope.of(context).unfocus();
        onSelected?.call(result);
      },
    );
  }
}
