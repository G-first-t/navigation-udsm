import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:navigation/models/locations.dart';
import 'package:navigation/services/navigation_service.dart';
import 'package:navigation/utils/logger.dart';
import 'package:navigation/constants/constant.dart';

class StartNavigationPanel extends StatefulWidget {
  final UdsmPlace place;
  final geo.Position? currentPosition;
  final String navigationMode;
  final VoidCallback onClose;

  const StartNavigationPanel({
    super.key,
    required this.place,
    required this.currentPosition,
    required this.navigationMode,
    required this.onClose,
  });

  @override
  State<StartNavigationPanel> createState() => StartNavigationState();
}

class StartNavigationState extends State<StartNavigationPanel> {
  MapboxMap? mapboxMap;
  late CameraOptions initialCamera;
  StreamSubscription<geo.Position>? _positionStream;
  final MapboxDirectionsService _mapboxDirectionsService =
      MapboxDirectionsService(mapboxAccessToken);

  final FlutterTts _flutterTts = FlutterTts();
  Map<String, dynamic>? _currentVoiceInstruction;
  Map<String, dynamic>? _currentBannerInstruction;
  double? _totalDistanceMeters;
  double? _totalDurationSeconds;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();

    final currentLat = widget.currentPosition?.latitude ?? 0.0;
    final currentLng = widget.currentPosition?.longitude ?? 0.0;

    initialCamera = CameraOptions(
      center: Point(coordinates: Position(currentLng, currentLat)),
      zoom: 18.0,
      bearing: 0,
    );

    _startNavigation();
  }

  Future<void> _clearRoute() async {
    try {
      if (mapboxMap != null) {
        await mapboxMap!.annotations.createPolylineAnnotationManager().then((manager) async {
          await manager.deleteAll();
          AppLogger.info('Route cleared successfully');
        });
      } else {
        AppLogger.error('Map not initialized');
      }
    } catch (e) {
      AppLogger.error('Error clearing route: $e');
    }
  }

  List<Position> _decodePolyline(String encoded) {
    List<Position> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(Position(lng / 1e5, lat / 1e5));
    }
    return points;
  }

  void _startNavigation() {
    geo.Position? _lastPosition;
    DateTime _lastCameraUpdate = DateTime.now().subtract(const Duration(seconds: 2));
    DateTime _lastRouteUpdate = DateTime.now().subtract(const Duration(seconds: 10));

    _positionStream = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((position) async {
      if (_isPaused || mapboxMap == null) return;

      final userLat = position.latitude;
      final userLng = position.longitude;
      final userHeading = (position.heading >= 0 && position.heading < 360)
          ? position.heading
          : (_lastPosition?.heading ?? 0.0);

      final now = DateTime.now();

      if (now.difference(_lastCameraUpdate) > const Duration(seconds: 1)) {
        mapboxMap!.easeTo(
          CameraOptions(
            center: Point(coordinates: Position(userLng, userLat)),
            zoom: 18.0,
            bearing: userHeading,
          ),
          MapAnimationOptions(duration: 1000),
        );
        _lastCameraUpdate = now;
      }

      final movedFarEnough = _lastPosition == null ||
          geo.Geolocator.distanceBetween(
                  _lastPosition!.latitude,
                  _lastPosition!.longitude,
                  userLat,
                  userLng) >
              20;

      if (movedFarEnough &&
          now.difference(_lastRouteUpdate) > const Duration(seconds: 10)) {
        _lastRouteUpdate = now;
        _lastPosition = position;

        final updatedRoute = await _mapboxDirectionsService.getRoute(
          originLat: userLat,
          originLng: userLng,
          destinationLat: widget.place.latitude,
          destinationLng: widget.place.longitude,
          profile: widget.navigationMode,
        );

        if (updatedRoute != null) {
          final geometry = updatedRoute['route']['geometry'];
          final steps = updatedRoute['steps'] as List<dynamic>?;
          _totalDistanceMeters = updatedRoute['distance']?.toDouble();
          _totalDurationSeconds = updatedRoute['duration']?.toDouble();

          if (geometry != null) {
            await _clearRoute();

            final coordinates = _decodePolyline(geometry);
            final lineString = LineString(coordinates: coordinates);

            final polylineAnnotationOptions = PolylineAnnotationOptions(
              geometry: lineString,
              lineColor: Colors.blue.value,
              lineWidth: 5.0,
              lineOpacity: 0.8,
            );

            await mapboxMap!.annotations
                .createPolylineAnnotationManager()
                .then((manager) async {
              await manager.create(polylineAnnotationOptions);
            });
          }

          if (steps != null) {
            for (final step in steps) {
              final voiceList = step['voiceInstructions'] as List<dynamic>?;
              final bannerList = step['bannerInstructions'] as List<dynamic>?;

              if (voiceList != null && voiceList.isNotEmpty) {
                final newInstruction = voiceList.first;
                if (_currentVoiceInstruction == null ||
                    _currentVoiceInstruction!['announcement'] !=
                        newInstruction['announcement']) {
                  _currentVoiceInstruction = newInstruction;
                  await _flutterTts.speak(newInstruction['announcement']);
                }
              }

              if (bannerList != null && bannerList.isNotEmpty) {
                _currentBannerInstruction = bannerList.first;
              }

              if (_currentVoiceInstruction != null &&
                  _currentBannerInstruction != null) break;
            }

            setState(() {});
          }
        }
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  IconData _getDirectionIcon(String? modifier) {
    switch (modifier) {
      case 'left':
        return Icons.turn_left;
      case 'right':
        return Icons.turn_right;
      case 'straight':
      default:
        return Icons.straight;
    }
  }

  String _formatDuration(double? seconds) {
    if (seconds == null) return '-- min';
    final mins = (seconds / 60).round();
    return '$mins min';
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '-- km';
    final km = (meters / 1000).toStringAsFixed(1);
    return '$km km';
  }

  @override
  void dispose() {
    _clearRoute();
    _positionStream?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            onMapCreated: (map) async {
              mapboxMap = map;
              map.setCamera(initialCamera);

              await map.location.updateSettings(
                LocationComponentSettings(
                  enabled: true,
                  pulsingEnabled: true,
                ),
              );
            },
          ),

          if (_currentVoiceInstruction != null || _currentBannerInstruction != null)
            Positioned(
              top: 32,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_currentVoiceInstruction != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[700],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.straight, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _currentVoiceInstruction!['announcement'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_currentBannerInstruction != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getDirectionIcon(_currentBannerInstruction!['primary']?['modifier']),
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_currentVoiceInstruction?['distanceAlongGeometry']?.toStringAsFixed(0) ?? '--'} ft',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentBannerInstruction!['primary']?['modifier'] ?? 'Continue',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          Positioned(
            bottom: 16,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_totalDurationSeconds),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatDistance(_totalDistanceMeters),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: _togglePause,
                    child: Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.blue,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: const Icon(Icons.close, color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
