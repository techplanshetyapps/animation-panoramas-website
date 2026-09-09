import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://your-backend-api.com'));

  Future<Map<String, dynamic>?> fetchEcosystemLiveData(String slug) async {
    try {
      final response = await _dio.get('/api/ecosystems/$slug/live-data');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print("Could not load live ecosystem metrics: $e");
    }
    return null;
  }
}