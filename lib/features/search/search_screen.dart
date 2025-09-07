import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nav_e/features/search/bloc/search_bloc.dart';
import 'package:nav_e/features/search/bloc/search_event.dart';
import 'package:nav_e/features/search/bloc/search_state.dart';
import 'package:nav_e/features/search/widgets/search_result_tile.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          margin: const EdgeInsets.only(top: 32.0),
          child: Column(
            children: [
              Hero(
                tag: 'searchBarHero',
                child: Material(
                  borderRadius: BorderRadius.circular(8),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter an address or place',
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (query) {
                      context.read<SearchBloc>().add(SearchQueryChanged(query));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<SearchBloc, SearchState>(
                  builder: (context, state) {
                    if (state.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.results.isEmpty) {
                      return const Center(child: Text('No results yet.'));
                    }

                    return ListView.separated(
                      itemCount: state.results.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (contexIt, index) {
                        final result = state.results[index];
                        return SearchResultTile(result: result);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
