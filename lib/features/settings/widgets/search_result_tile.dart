import 'package:flutter/material.dart';

class SearchResultTile extends StatelessWidget {
  final dynamic result;

  const SearchResultTile({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.place),
      title: Text(result.displayName),
      subtitle: Text(result.type),
      onTap: () {
        Navigator.pop(context, result);
      },
    );
  }
}
