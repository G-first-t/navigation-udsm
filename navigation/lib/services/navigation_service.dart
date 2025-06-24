import 'dart:convert';
import 'package:http/http.dart' as http;

class MapboxDirectionsService {
  final String accessToken;

  MapboxDirectionsService(this.accessToken);

  Future<Map<String, dynamic>?> getRoute({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    String profile = 'driving', // Only 'driving' or 'walking' allowed
  }) async {
    if (!(profile == 'driving' || profile == 'walking')) {
      throw ArgumentError('Only "driving" or "walking" profiles are allowed.');
    }

    final coordinates =
        '$originLng,$originLat;$destinationLng,$destinationLat';

    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/$profile/$coordinates'
      '?alternatives=false'
      '&geometries=polyline'
      '&steps=true'
      '&overview=full'
      '&voice_instructions=true'
      '&banner_instructions=true'
      '&access_token=$accessToken',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'route': data['routes'][0], // Assuming first route is used
          'distance': data['routes'][0]['distance'],
          'duration': data['routes'][0]['duration'],
          'steps': data['routes'][0]['legs'][0]['steps'],
          'maneuvers': data['routes'][0]['legs'][0]['steps']
              .map((step) => step['maneuver'])
              .toList(),
          'voice_instructions': data['routes'][0]['legs'][0]['voice_instructions'],
          'banner_instructions': data['routes'][0]['legs'][0]['banner_instructions'],
        };
      } else {
        print('❌ Failed to fetch route: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching route: $e');
      return null;
    }
  }
}