import 'package:dio/dio.dart';

class OlapApiService {
  final Dio _dio = Dio();
  
  // Parallel API multi-stream fetch combining Open-Meteo, Solar API, and GBIF
  Future<Map<String, dynamic>> fetchParallelEcosystemTelemetry(String slug, double lat, double lng) async {
    try {
      final futures = await Future.wait([
        _dio.get('https://api.open-meteo.com/v1/forecast', queryParameters: {
          'latitude': lat,
          'longitude': lng,
          'current': 'temperature_2m,relative_humidity_2m',
        }),
        _dio.get('https://api.sunrise-sunset.org/v2', queryParameters: {
          'lat': lat,
          'lng': lng,
        }),
        _dio.get('https://api.gbif.org/v1/occurrence/search', queryParameters: {
          'decimalLatitude': lat,
          'decimalLongitude': lng,
          'limit': 1,
        }),
      ]);

      final weatherData = futures[0].data['current'];
      final solarData = futures[1].data['results'];
      final gbifResults = futures[2].data['results'] as List?;
      final specimen = (gbifResults != null && gbifResults.isNotEmpty)
          ? (gbifResults[0]['scientificName'] ?? 'Field Specimen')
          : 'Generic Biome Node';

      return {
        'temperature': weatherData['temperature_2m'],
        'humidity': weatherData['relative_humidity_2m'],
        'sunrise': solarData['sunrise'],
        'sunset': solarData['sunset'],
        'specimen': specimen,
        'status': 'ONLINE_SYNCHRONIZED',
      };
    } catch (e) {
      return {
        'temperature': 0.0,
        'humidity': 0.0,
        'sunrise': '06:00:00 AM',
        'sunset': '06:00:00 PM',
        'specimen': 'Fallback Record',
        'status': 'OFFLINE_CACHED',
      };
    }
  }

  // ClickHouse HTTP interface query runner for OLAP historical aggregates
  Future<List<Map<String, dynamic>>> queryClickHouseAnalytics(String slug) async {
    try {
      final response = await _dio.post(
        'http://localhost:8123/',
        data: "SELECT toStartOfHour(timestamp) as hr, avg(temperature) as avg_temp FROM ecosystem_analytics.telemetry_logs WHERE ecosystem_slug = '$slug' GROUP BY hr ORDER BY hr DESC LIMIT 10 FORMAT JSON",
      );
      if (response.statusCode == 200) {
        final data = response.data['data'] as List?;
        if (data != null) {
          return data.map((e) => e as Map<String, dynamic>).toList();
        }
      }
    } catch (e) {
      print("ClickHouse analytical engine query exception: $e");
    }
    return [];
  }
}