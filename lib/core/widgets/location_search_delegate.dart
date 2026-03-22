import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feed_the_future/core/services/location_service.dart';
import 'package:feed_the_future/core/theme/app_theme.dart';

class LocationSearchDelegate extends SearchDelegate<PlaceDetails?> {
  final WidgetRef ref;

  LocationSearchDelegate(this.ref) : super(
    searchFieldLabel: 'Buscar dirección (ej. Polanco)',
    searchFieldStyle: const TextStyle(fontSize: 16),
  );

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
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

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 3) {
      return const Center(
        child: Text('Escribe al menos 3 caracteres para buscar...'),
      );
    }

    final locationService = ref.read(locationServiceProvider);

    return FutureBuilder<List<PlacePrediction>>(
      future: locationService.getAutocomplete(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No se encontraron resultados.'),
          );
        }

        final predictions = snapshot.data!;

        return ListView.separated(
          itemCount: predictions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final prediction = predictions[index];
            return ListTile(
              leading: const Icon(Icons.location_on_outlined, color: AppTheme.textMuted),
              title: Text(prediction.mainText, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(prediction.secondaryText, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () async {
                // Show a loading dialog while fetching details
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                final details = await locationService.getPlaceDetails(prediction.placeId);
                
                // Hide loading
                if (context.mounted) Navigator.of(context).pop();

                if (details != null && context.mounted) {
                  close(context, details);
                }
              },
            );
          },
        );
      },
    );
  }
}
