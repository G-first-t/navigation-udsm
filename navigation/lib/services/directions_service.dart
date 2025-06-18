import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:navigation/utils/logger.dart';

/// A model representing a route from the Mapbox Directions API.
class Route {
  final List<Position> coordinates; // Route geometry as list of coordinates
  final double distance; // Distance in meters
  final double duration; // Duration in seconds
  final List<Map<String, dynamic>>? steps; // Optional turn-by-turn instructions

  Route({
    required this.coordinates,
    required this.distance,
    required this.duration,
    this.steps,
  });

  /// Converts distance to kilometers (rounded to 1 decimal place).
  String get distanceKm => (distance / 1000).toStringAsFixed(1);

  /// Converts duration to minutes (rounded to nearest integer).
  String get durationMin => (duration / 60).round().toString();
}

class DirectionsService {
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';
  final String accessToken;

  DirectionsService(this.accessToken);

  /// Fetches a route from the Mapbox Directions API.
  ///
  /// Parameters:
  /// - [origin]: The starting point (user's current position).
  /// - [destLng]: Destination longitude.
  /// - [destLat]: Destination latitude.
  /// - [profile]: Navigation mode ('walking' or 'driving').
  /// - [steps]: Whether to include turn-by-turn instructions (default: true).
  /// - [language]: Language for instructions (default: 'en').
  ///
  /// Returns a [Route] object containing the route geometry, distance, and duration.
  /// Throws an [Exception] if the request fails or no route is found.
  Future<Route> getRoute({
    required geo.Position origin,
    required double destLng,
    required double destLat,
    required String profile, // 'walking' or 'driving'
    bool steps = true,
    String language = 'en',
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/$profile/${origin.longitude},${origin.latitude};$destLng,$destLat'
        '?geometries=geojson'
        '&steps=$steps'
        '&language=$language'
        '&access_token=$accessToken',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load route: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }

      final data = json.decode(response.body);

      // Check if routes are available
      if (data['routes'] == null || (data['routes'] as List).isEmpty) {
        throw Exception('No routes found for the given coordinates');
      }

      // Parse the first route
      final routeData = data['routes'][0];
      final geometry = routeData['geometry']['coordinates'] as List<dynamic>;
      final coordinates = geometry
          .map((coord) => Position(coord[0] as double, coord[1] as double))
          .toList();

      return Route(
        coordinates: coordinates,
        distance: (routeData['distance'] as num).toDouble(),
        duration: (routeData['duration'] as num).toDouble(),
        steps: steps
            ? (routeData['legs'][0]['steps'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>()
            : null,
      );
    } catch (e) {
      // Log the error (assuming AppLogger from your codebase)
      AppLogger.error('Failed to fetch route: $e');
      rethrow; // Rethrow to let the caller handle the error
    }
  }
}
