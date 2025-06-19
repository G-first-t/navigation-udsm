import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' as geo;

class DirectionsService {
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';
  final String accessToken;

  DirectionsService(this.accessToken);

  Future<Map<String, dynamic>> getRoute({
    required geo.Position origin,
    required double destLng,
    required double destLat,
    required String profile, // 'walking' or 'driving'
  }) async {
    final url =
        '$_baseUrl/$profile/${origin.longitude},${origin.latitude};$destLng,$destLat'
        '?geometries=geojson'
        '&access_token=$accessToken';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load route: ${response.statusCode}');
    }
  }
}