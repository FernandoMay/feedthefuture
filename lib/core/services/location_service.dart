import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides the API Key, ideally this should come from flutter_dotenv or env variables
final googleMapsApiKeyProvider = Provider<String>((ref) {
  // TODO: Replace this with your actual environment variable loader
  return const String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
});

final locationServiceProvider = Provider<LocationService>((ref) {
  final apiKey = ref.watch(googleMapsApiKeyProvider);
  return LocationService(Dio(), apiKey);
});

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'],
      description: json['description'],
      mainText: json['structured_formatting']['main_text'],
      secondaryText: json['structured_formatting']['secondary_text'],
    );
  }
}

class PlaceDetails {
  final double lat;
  final double lng;
  final String address;

  PlaceDetails({required this.lat, required this.lng, required this.address});
}

class LocationService {
  final Dio _dio;
  final String _apiKey;

  LocationService(this._dio, this._apiKey);

  Future<List<PlacePrediction>> getAutocomplete(String query) async {
    if (query.isEmpty || _apiKey.isEmpty) return [];

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': _apiKey,
          'components': 'country:mx', // Limit to Mexico as this is for Feed the Future Mexico
          'language': 'es',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((p) => PlacePrediction.fromJson(p))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (_apiKey.isEmpty) return null;

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'fields': 'geometry,formatted_address',
          'language': 'es',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final result = data['result'];
          return PlaceDetails(
            lat: result['geometry']['location']['lat'],
            lng: result['geometry']['location']['lng'],
            address: result['formatted_address'],
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
