import 'dart:convert';
import 'package:dio/dio.dart';

class OlapApiService {
  final Dio _dio = Dio();
  
  static final Map<String, Map<String, dynamic>> _cache = {};
  
  static const String _clickHouseUrl = String.fromEnvironment(
    'CLICKHOUSE_URL',
    defaultValue: 'https://ynu691xtll.germanywestcentral.azure.clickhouse.cloud:8443',
  );
  static const String _clickHouseUser = String.fromEnvironment(
    'CLICKHOUSE_USER',
    defaultValue: 'default',
  );
  static const String _clickHousePass = String.fromEnvironment('CLICKHOUSE_PASS');

  Options get _clickHouseAuthOptions {
    return Options(
      headers: {
        'authorization': 'Basic ${base64Encode(utf8.encode('$_clickHouseUser:$_clickHousePass'))}',
        'Content-Type': 'text/plain; charset=utf-8',
      },
      responseType: ResponseType.json,
    );
  }

  Future<Map<String, dynamic>> fetchEcosystemWithParallelAI(String slug, double lat, double lng) async {
    final cacheKey = "${lat.toStringAsFixed(2)}_${lng.toStringAsFixed(2)}";
    if (_cache.containsKey(cacheKey)) {
      var cached = Map<String, dynamic>.from(_cache[cacheKey]!);
      cached['status'] = 'CACHED (FREE TIER PROTECTED)';
      return cached;
    }

    try {
      final futures = await Future.wait([
        _dio.get('https://api.open-meteo.com/v1/forecast', queryParameters: {
          'latitude': lat,
          'longitude': lng,
          'current': 'temperature_2m,apparent_temperature,relative_humidity_2m,precipitation,cloud_cover,surface_pressure,wind_speed_10m,wind_direction_10m,wind_gusts_10m,weather_code',
        }),
        _dio.get('https://api.sunrise-sunset.org/json', queryParameters: {
          'lat': lat,
          'lng': lng,
          'formatted': 0,
        }),
        _dio.get('https://api.gbif.org/v1/occurrence/search', queryParameters: {
          'decimalLatitude': lat,
          'decimalLongitude': lng,
          'limit': 1,
        }),
      ]);

      final current = futures[0].data['current'] ?? {};
      final solarData = futures[1].data['results'] ?? {};
      final gbifResults = futures[2].data['results'] as List?;
      final specimen = (gbifResults != null && gbifResults.isNotEmpty)
          ? (gbifResults[0]['scientificName'] ?? 'Field Specimen')
          : 'Generic Biome Node';

      final result = {
        'temperature_2m': current['temperature_2m'] ?? 21.0,
        'apparent_temperature': current['apparent_temperature'] ?? 22.0,
        'relative_humidity_2m': current['relative_humidity_2m'] ?? 55.0,
        'precipitation': current['precipitation'] ?? 0.0,
        'cloud_cover': current['cloud_cover'] ?? 15.0,
        'surface_pressure': current['surface_pressure'] ?? 1012.0,
        'wind_speed_10m': current['wind_speed_10m'] ?? 8.5,
        'wind_direction_10m': current['wind_direction_10m'] ?? 140.0,
        'wind_gusts_10m': current['wind_gusts_10m'] ?? 15.0,
        'weather_code': current['weather_code'] ?? 0,
        'sunrise': solarData['sunrise'] ?? '06:00:00 AM',
        'sunset': solarData['sunset'] ?? '06:00:00 PM',
        'specimen': specimen,
        'status': 'ONLINE_SYNCHRONIZED',
      };

      _cache[cacheKey] = result;
      return result;
    } catch (e) {
      return {
        'temperature_2m': 21.0,
        'apparent_temperature': 22.0,
        'relative_humidity_2m': 55.0,
        'precipitation': 0.0,
        'cloud_cover': 15.0,
        'surface_pressure': 1012.0,
        'wind_speed_10m': 8.5,
        'wind_direction_10m': 140.0,
        'wind_gusts_10m': 15.0,
        'weather_code': 0,
        'sunrise': '06:00:00 AM',
        'sunset': '06:00:00 PM',
        'specimen': 'Fallback Record ($slug)',
        'status': 'OFFLINE_CACHED',
      };
    }
  }

  Future<List<Map<String, dynamic>>> queryClickHouseAnalytics(String slug) async {
    try {
      final response = await _dio.post(
        _clickHouseUrl,
        data: "SELECT toStartOfHour(event_timestamp) as hr, avg(metric_reading) as avg_metric FROM telemetry_germanywestcentral.grafana_mcp_analytics WHERE service_source = '$slug' GROUP BY hr ORDER BY hr DESC LIMIT 10 FORMAT JSON",
        options: _clickHouseAuthOptions,
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as List?;
        if (data != null) {
          return data.map((e) => e as Map<String, dynamic>).toList();
        }
      }
    } catch (e) {
      print("ClickHouse query exception: $e");
    }
    return [];
  }
}