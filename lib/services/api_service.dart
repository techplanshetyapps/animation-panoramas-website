import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio();

  // 1. Open-Meteo API: Fetches live temperature_2m and relative_humidity_2m
  Future<Map<String, dynamic>?> fetchWeather(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lng,
          'current': 'temperature_2m,relative_humidity_2m',
        },
      );
      if (response.statusCode == 200) {
        return response.data['current'];
      }
    } catch (e) {
      print("Weather fetch error: $e");
    }
    return null;
  }

  // 2. Sunrise-Sunset API v2: Computes precise sunrise and sunset timestamps
  Future<Map<String, dynamic>?> fetchSolarTimes(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://api.sunrise-sunset.org/v2',
        queryParameters: {
          'lat': lat,
          'lng': lng,
        },
      );
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print("Solar times fetch error: $e");
    }
    return null;
  }

  // 3. GBIF API: Queries geo-referenced species occurrence records
  Future<String?> fetchWildlifeSample(double lat, double lng) async {
    try {
      // Using a small bounding box or coordinate filter via GBIF occurrence search
      final response = await _dio.get(
        'https://api.gbif.org/v1/occurrence/search',
        queryParameters: {
          'decimalLatitude': lat,
          'decimalLongitude': lng,
          'limit': 1,
        },
      );
      if (response.statusCode == 200) {
        final results = response.data['results'] as List?;
        if (results != null && results.isNotEmpty) {
          return results[0]['scientificName'] ?? 
                 results[0]['vernacularName'] ?? 
                 'Uncataloged Specimen';
        }
      }
    } catch (e) {
      print("GBIF wildlife fetch error: $e");
    }
    return 'No regional sample found';
  }
}