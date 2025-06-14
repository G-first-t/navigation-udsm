import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

// Class for initializing UDSM locations
class UdsmPlace {
  final String name;
  final double latitude;
  final double longitude;
  final List<String> images;

  UdsmPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.images,
  });

  factory UdsmPlace.fromGeoJson(Map<String, dynamic> feature) {
    final properties = feature['properties'] ?? {};
    final geometry = feature['geometry'] ?? {};

    final dynamic rawImages = properties['images'];
    List<String> imageList = [];

    if (rawImages is List) {
      imageList = List<String>.from(rawImages);
    } else if (rawImages is String) {
      imageList = [rawImages];
    }

    return UdsmPlace(
      name: properties['name'] ?? 'Unnamed',
      latitude: geometry['coordinates'][1],
      longitude: geometry['coordinates'][0],
      images: imageList,
    );
  }
}

Future<List<UdsmPlace>> loadUdsmPlaces() async {
  final String jsonStr = await rootBundle.loadString(
    'assets/udsm_locations.geojson',
  );
  final Map<String, dynamic> geoJson = json.decode(jsonStr);
  final List features = geoJson['features'];
  return features.map((f) => UdsmPlace.fromGeoJson(f)).toList();
}
