import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';
import 'package:navigation/models/locations.dart';
import 'package:navigation/utils/logger.dart';
import 'dart:typed_data';
import 'package:navigation/services/directions_service.dart';
import 'package:navigation/constants/constant.dart';

class MapBoxWidget extends StatefulWidget {
  final UdsmPlace? selectedPlace;
  final Function(MapboxMap, geo.Position?)? onMapCreated;
  const MapBoxWidget({
    super.key,
    required this.selectedPlace,
    this.onMapCreated,
  });

  @override
  State<MapBoxWidget> createState() => _MapBoxWidgetState();
}

class _MapBoxWidgetState extends State<MapBoxWidget> {
  MapboxMap? _mapboxMap;
  CameraOptions? _cameraOptions;
  bool _isLoading = true;
  geo.Position? _currentPosition;
  StreamSubscription<geo.Position>? _positionStreamSubscription;
  late PointAnnotationManager _pointAnnotationManager;
  late CircleAnnotationManager _circleAnnotationManager;

  final DirectionsService _directionsService = DirectionsService(
    mapboxAccessToken,
  );

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    AppLogger.info('map initialized');
  }

  @override
  void didUpdateWidget(MapBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPlace != widget.selectedPlace && _mapboxMap != null) {
      _updateMapForSelectedPlace();
      AppLogger.info(' map is updated to this location ');
    }
  }

  Future<void> _initializeLocation() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        setState(() => _isLoading = false);
        _showError('Location permission required');
        AppLogger.debug('Location permission required');
        return;
      }

      final locationSettings = const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10,
      );

      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _cameraOptions = CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 15.0,
          pitch: 45.0,
        );
        _isLoading = false;
      });

      if (_mapboxMap != null) {
        await _mapboxMap?.setCamera(_cameraOptions!);
      }

      _startLocationUpdates(locationSettings);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Unable to get location');
    }
  }

  void _startLocationUpdates(geo.LocationSettings locationSettings) {
    _positionStreamSubscription =
        geo.Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen(
          (geo.Position position) {
            if (widget.selectedPlace == null) {
              setState(() {
                _currentPosition = position;
              });
              if (_mapboxMap != null) {
                _mapboxMap!.setCamera(
                  CameraOptions(
                    center: Point(
                      coordinates: Position(
                        position.longitude,
                        position.latitude,
                      ),
                    ),
                    zoom: 15.0,
                    pitch: 45.0,
                    bearing: position.heading,
                  ),
                );
              }
            }
          },
          onError: (e) {
            _showError('Failed to update location');
          },
        );
  }

  // here I will implement the route drawing functionalities

  Future<void> _drawRoute() async {}

  //details view map zooming for selected place

  Future<void> _updateMapForSelectedPlace() async {
    if (!mounted) return;
    if (widget.selectedPlace != null && _mapboxMap != null) {
      final longitude = widget.selectedPlace!.longitude;
      final latitude = widget.selectedPlace!.latitude;

      // Clear existing annotations
      await _circleAnnotationManager.deleteAll();
      await _pointAnnotationManager.deleteAll();
      AppLogger.debug('Clearing the existing annotations');
      // Move the camera to selected location
      await _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(longitude, latitude)),
          zoom: 18.0, // Reasonable zoom level
          pitch: 60.0,
          anchor: ScreenCoordinate(
            x: MediaQuery.of(context).size.width / 2,
            y: 200,
          ),
        ),
        MapAnimationOptions(duration: 1000),
      );

      // Add a marker image for the map
      try {
        await _mapboxMap!.style.addStyleImage(
          'location_marker',
          1.0,
          await _loadImage('assets/icons/marker1.png'),
          false, // sdf
          [], // stretchX
          [], // stretchY
          null, // content
        );
        AppLogger.info('Image added');
      } catch (e) {
        AppLogger.debug('Error adding style image: $e');
      }

      // Add marker
      await _pointAnnotationManager.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(longitude, latitude)),
          iconImage: 'location_marker',
          iconSize: 1.0,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );

      // Add text annotation
    }
  }

  //adding image icons for navigation
  Future<MbxImage> _loadImage(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final Uint8List data = byteData.buffer.asUint8List();

    // You must specify the width and height of the image in pixels.
    // Replace these with your actual image dimensions.
    const int width = 63;
    const int height = 63;

    return MbxImage(width: width, height: height, data: data);
  }

  Future<void> _loadGeoJson() async {
    try {
      final geoJson = await rootBundle.loadString(
        'assets/udsm_locations.geojson',
      );
      await _mapboxMap?.style.addSource(
        GeoJsonSource(id: 'campus-points', data: geoJson),
      );
      await _mapboxMap?.style.addLayer(
        CircleLayer(
          id: 'campus-points-layer',
          sourceId: 'campus-points',
          circleRadius: 10.0,
          circleColor: Colors.red.value,
          circleStrokeWidth: 2.0,
          circleStrokeColor: Colors.white.value,
          circleOpacity: 0.8,
        ),
      );
    } catch (e) {
      AppLogger.error('failed  $e');
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _pointAnnotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();
    _circleAnnotationManager = await mapboxMap.annotations
        .createCircleAnnotationManager();

    await _mapboxMap!.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: Colors.blue.value,
      ),
    );

    if (_cameraOptions != null) {
      await _mapboxMap!.setCamera(_cameraOptions!);
    }

    await _loadGeoJson();
    await _updateMapForSelectedPlace();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cameraOptions == null && widget.selectedPlace == null) {
      return const Center(child: Text('Unable to get user location'));
    }

    return MapWidget(
      key: const ValueKey('mapWidget'),
      styleUri: 'mapbox://styles/mapbox/streets-v12',
      cameraOptions: _cameraOptions,
      onMapCreated: _onMapCreated,
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _mapboxMap?.location.updateSettings(
      LocationComponentSettings(enabled: false),
    );
    super.dispose();
  }
}
