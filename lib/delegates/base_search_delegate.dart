import 'package:flutter/material.dart';

// Custom class that all delegates should derive from
abstract class BaseSearchDelegate<T> extends SearchDelegate<T?> {
  BaseSearchDelegate({required super.searchFieldLabel});

  // Unified normalization method for all search delegates
  String normalizeGreek(String input) {
    const withAccents = 'άέήίϊΐόύϋΰώ';
    const withoutAccents = 'αεηιιιουυυω';

    String result = input.toLowerCase();
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }
}