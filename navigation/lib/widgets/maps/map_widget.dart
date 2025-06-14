import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:async';

class MapBoxWidget extends StatefulWidget {
  const MapBoxWidget({super.key});

  @override
  State<MapBoxWidget> createState() => _MapBoxWidgetState();
}

class _MapBoxWidgetState extends State<MapBoxWidget> {
  MapboxMap? _mapboxMap;
  CameraOptions? _cameraOptions;
  bool _isLoading = true;
  geo.Position? _currentPosition;
  StreamSubscription<geo.Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        setState(() => _isLoading = false);
        _showError('Location permission required');
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
    _positionStreamSubscription = geo.Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((geo.Position position) {
      setState(() {
        _currentPosition = position;
      });

      if (_mapboxMap != null) {
        _mapboxMap!.setCamera(
          CameraOptions(
            center: Point(
              coordinates: Position(position.longitude, position.latitude),
            ),
            zoom: 15.0,
            pitch: 45.0,
            bearing: position.heading,
          ),
        );
      }
    }, onError: (e) {
      _showError('Failed to update location');
    });
  }

  Future<void> _loadGeoJson() async {
    try {
      final geoJson = await rootBundle.loadString('assets/campus_points.geojson');
      await _mapboxMap?.style.addSource(GeoJsonSource(id: 'campus-points', data: geoJson));
      await _mapboxMap?.style.addLayer(CircleLayer(
        id: 'campus-points-layer',
        sourceId: 'campus-points',
        circleRadius: 10.0,
        circleColor: Colors.red.value,
        circleStrokeWidth: 2.0,
        circleStrokeColor: Colors.white.value,
        circleOpacity: 0.8,
      ));
      // Optional: Use SymbolLayer for custom markers
      /*
      await _mapboxMap?.style.addLayer(SymbolLayer(
        id: 'campus-points-layer',
        sourceId: 'campus-points',
        iconImage: 'marker-15',
        iconSize: 1.5,
        textField: '{name}',
        textOffset: [0.0, 1.5],
        textAnchor: TextAnchor.top,
      ));
      */
    } catch (e) {
      print('Error loading GeoJSON: $e');
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
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
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cameraOptions == null) {
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