import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:navigation/models/locations.dart';
import 'package:navigation/utils/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

Future<geo.Position> initializeLocation(BuildContext context) async {
  final status = await Permission.locationWhenInUse.request();
  if (!status.isGranted) {
    AppLogger.error('Location permission denied');
    showError(context, 'Location permission required');
    throw Exception('Location permission denied');
  }

  final locationSettings = const geo.LocationSettings(
    accuracy: geo.LocationAccuracy.high,
    distanceFilter: 10,
  );

  final position = await geo.Geolocator.getCurrentPosition(
    locationSettings: locationSettings,
    timeLimit: const Duration(seconds: 10),
  );

  AppLogger.info('Initial user location: ${position.latitude}, ${position.longitude}');
  return position;
}

void showError(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
Future<MbxImage> loadImage(String assetPath) async {
  final byteData = await rootBundle.load(assetPath);
  final Uint8List data = byteData.buffer.asUint8List();

  // Decode the image to get actual dimensions
  final decodedImage = img.decodeImage(data);
  if (decodedImage == null) {
    throw Exception("Failed to decode image");
  }

  final width = decodedImage.width;
  final height = decodedImage.height;

  return MbxImage(width: width, height: height, data: data);
}


({Point center, double zoom}) calculateBounds(
  List<dynamic> coordinates,
  geo.Position? currentPosition,
  UdsmPlace selectedPlace,
) {
  // 1. Collect all lat/lng
  List<double> lats = [selectedPlace.latitude];
  List<double> lngs = [selectedPlace.longitude];

  if (currentPosition != null) {
    lats.add(currentPosition.latitude);
    lngs.add(currentPosition.longitude);
  }

  for (final coord in coordinates) {
    lngs.add(coord[0]);
    lats.add(coord[1]);
  }

  // 2. Compute bounds
  final minLat = lats.reduce(math.min);
  final maxLat = lats.reduce(math.max);
  final minLng = lngs.reduce(math.min);
  final maxLng = lngs.reduce(math.max);

  final centerLat = (minLat + maxLat) / 2;
  final centerLng = (minLng + maxLng) / 2;

  final latDelta = maxLat - minLat;
  final lngDelta = maxLng - minLng;

  // 3. Calculate zoom based on map size and deltas
  // These are safe defaults, tweak if you want
  const maxZoom = 18.0;
  const minZoom = 6.0;

  // Avoid division by zero
  final zoomLat = latDelta > 0 ? math.log(360 / latDelta) / math.log(2) : maxZoom;
  final zoomLng = lngDelta > 0 ? math.log(360 / lngDelta) / math.log(2) : maxZoom;

  // Final zoom is tightest fitting one
  final zoom = (zoomLat < zoomLng ? zoomLat : zoomLng).clamp(minZoom, maxZoom);

  // Optional padding zoom-out (like Google Maps does)
  const paddingZoomOffset = 0.5;

  return (
    center: Point(coordinates: Position(centerLng, centerLat)),
    zoom: (zoom - paddingZoomOffset).clamp(minZoom, maxZoom),
  );
}
