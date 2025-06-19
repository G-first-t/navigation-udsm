import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:navigation/models/locations.dart';
import 'package:navigation/services/directions_service.dart';
import 'package:navigation/constants/constant.dart';
import 'package:navigation/widgets/maps/mapbox_utils.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'dart:convert';
import 'package:navigation/utils/logger.dart';

class MapBoxDirectionsWidget extends StatefulWidget {
  final UdsmPlace? selectedPlace;
  final geo.Position? currentPosition;
  final String selectedTransportMode;
  final Function(
    String walkTime,
    String walkDistance,
    String driveTime,
    String driveDistance,
  )?
  onTimesUpdated;
  final Function(String)? onModeChanged;
  final Function(MapboxMap, geo.Position?)? onMapCreated;

  const MapBoxDirectionsWidget({
    super.key,
    required this.selectedPlace,
    this.currentPosition,
    required this.selectedTransportMode,
    this.onTimesUpdated,
    this.onModeChanged,
    this.onMapCreated,
  });

  @override
  State<MapBoxDirectionsWidget> createState() => _MapBoxDirectionsWidgetState();
}

class _MapBoxDirectionsWidgetState extends State<MapBoxDirectionsWidget> {
  MapboxMap? _mapboxMap;
  late PointAnnotationManager _pointAnnotationManager;
  bool _isStyleLoaded = false;
  bool _isRouteLoading = false;
  String _walkTime = 'Calculating...';
  String _driveTime = 'Calculating...';
  String _walkDistance = '';
  String _driveDistance = '';
  final DirectionsService _directionsService = DirectionsService(
    mapboxAccessToken,
  );
  CameraOptions? _cameraOptions;

  @override
  void initState() {
    super.initState();
    _cameraOptions = widget.currentPosition != null
        ? CameraOptions(
            center: Point(
              coordinates: Position(
                widget.currentPosition!.longitude,
                widget.currentPosition!.latitude,
              ),
            ),
            zoom: 15.0,
            pitch: 45.0,
          )
        : null;
    _updateRouteDurations();
  }
  
   @override
  void didUpdateWidget(covariant MapBoxDirectionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPlace != widget.selectedPlace ||
        oldWidget.currentPosition != widget.currentPosition ||
        oldWidget.selectedTransportMode != widget.selectedTransportMode) {
      AppLogger.info(
        'MapBoxDirectionsWidget: Props updated - selectedPlace=${widget.selectedPlace?.name}, '
        'mode=${widget.selectedTransportMode}',
      );
      _updateRouteDurations();
      if (_isStyleLoaded) {
        _drawRoute();
      }
    }
  }

  Future<void> _updateRouteDurations() async {
    AppLogger.info('method update route duration started');
    if (widget.currentPosition == null || widget.selectedPlace == null) return;

    try {
      AppLogger.info('calculating the walk route duration');
      final walkRoute = await _directionsService.getRoute(
        origin: widget.currentPosition!,
        destLng: widget.selectedPlace!.longitude,
        destLat: widget.selectedPlace!.latitude,
        profile: 'walking',
      );
      final walkDuration = walkRoute['routes']?[0]['duration']?.toDouble() ?? 0;
      final walkDistance = walkRoute['routes']?[0]['distance']?.toDouble() ?? 0;
      final walkTime = _formatDuration(walkDuration);
      final walkDist = _formatDistance(walkDistance);

      //logs
      AppLogger.info(' walkDuration is $walkDuration');
      AppLogger.info(' walkDistance is $walkDistance');
      AppLogger.info(' walkTime is $walkTime');
      AppLogger.info(' walkTime is $walkTime');

      final driveRoute = await _directionsService.getRoute(
        origin: widget.currentPosition!,
        destLng: widget.selectedPlace!.longitude,
        destLat: widget.selectedPlace!.latitude,
        profile: 'driving',
      );
      final driveDuration =
          driveRoute['routes']?[0]['duration']?.toDouble() ?? 0;
      final driveDistance =
          driveRoute['routes']?[0]['distance']?.toDouble() ?? 0;
      final driveTime = _formatDuration(driveDuration);
      final driveDist = _formatDistance(driveDistance);

      //logs
      AppLogger.info(' driveDuration is $driveDuration');
      AppLogger.info(' driveDistance is $driveDistance');
      AppLogger.info(' driveTime is $driveTime');
      AppLogger.info(' driveTime is $driveTime');

      setState(() {
        _walkTime = walkTime;
        _driveTime = driveTime;
        _walkDistance = walkDist;
        _driveDistance = driveDist;
      });

      widget.onTimesUpdated?.call(walkTime, walkDist, driveTime, driveDist);
      AppLogger.info(' ontimesUpdated is ${widget.onTimesUpdated}');
    } catch (e) {
      setState(() {
        _walkTime = 'N/A';
        _driveTime = 'N/A';
        _walkDistance = '';
        _driveDistance = '';
      });
      widget.onTimesUpdated?.call('N/A', '', 'N/A', '');
      AppLogger.error('error in fetching time $e');
    }
  }

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.toInt());
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    } else {
      return '${duration.inHours} hr ${duration.inMinutes.remainder(60)} min';
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  Future<void> _drawRoute() async {
    AppLogger.info('drawing route started ');
    if (widget.currentPosition == null ||
        widget.selectedPlace == null ||
        widget.selectedTransportMode.isEmpty ||
        _mapboxMap == null ||
        !_isStyleLoaded) {
      return;
    }

    setState(() => _isRouteLoading = true);
    try {
      final profile = widget.selectedTransportMode == 'walk'
          ? 'walking'
          : 'driving';
      await _clearRoute();

      final route = await _directionsService.getRoute(
        origin: widget.currentPosition!,
        destLng: widget.selectedPlace!.longitude,
        destLat: widget.selectedPlace!.latitude,
        profile: profile,
      );

      if (route['routes'] == null || route['routes'].isEmpty) {
        throw Exception('No routes found');
      }

      final geometry = route['routes'][0]['geometry'];
      final line = {'type': 'Feature', 'properties': {}, 'geometry': geometry};

      await _mapboxMap!.style.addSource(
        GeoJsonSource(id: 'route-source', data: json.encode(line)),
      );

      await _mapboxMap!.style.addLayer(
        LineLayer(
          id: 'route-layer',
          sourceId: 'route-source',
          lineColor: widget.selectedTransportMode == 'walk'
              ? Colors.red.toARGB32()
              : Colors.blue.toARGB32(),
          lineWidth: 4.0,
          lineOpacity: 0.8,
          lineJoin: LineJoin.ROUND,
          lineCap: LineCap.ROUND,
        ),
      );

      await _addDestinationMarker();

      final coordinates = geometry['coordinates'] as List<dynamic>;
      if (coordinates.isEmpty) {
        throw Exception('Empty route coordinates');
      }

      final bounds = calculateBounds(
        coordinates,
        widget.currentPosition,
        widget.selectedPlace!,
      );

      await _mapboxMap!.setCamera(
        CameraOptions(
          center: bounds.center,
          zoom: bounds.zoom,
          padding: MbxEdgeInsets(left: 50, top: 50, right: 50, bottom: 50),
        ),
      );

      // Add tooltip for estimated time
      final duration = route['routes'][0]['duration']?.toDouble() ?? 0;
      final tooltipText = _formatDuration(duration);
      await _addTooltip(tooltipText, coordinates);
    } catch (e) {
      AppLogger.error('failed because $e');
    } finally {
      setState(() => _isRouteLoading = false);
    }
  }

  Future<void> _addTooltip(
    String tooltipText,
    List<dynamic> coordinates,
  ) async {
    AppLogger.info('addTooltip started');
    if (_mapboxMap == null) return;

    final midPoint = coordinates[coordinates.length ~/ 2];
    await _pointAnnotationManager.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(midPoint[0], midPoint[1])),
        textField: tooltipText,
        textColor: Colors.yellow.toARGB32(),
        textSize: 12.0,
        textOffset: [0.0, -2.0],
        textAnchor: TextAnchor.CENTER,
      ),
    );
  }

  Future<void> _clearRoute() async {
    if (_mapboxMap == null) return;
    AppLogger.info('Clear routes started');
    await _mapboxMap!.style.removeStyleLayer('route-layer').catchError((e) {});
    await _mapboxMap!.style
        .removeStyleSource('route-source')
        .catchError((e) {});
    await _pointAnnotationManager.deleteAll().catchError((e) {});
  }

  Future<void> _addDestinationMarker() async {
    AppLogger.info('adding destination marker started');
    if (_mapboxMap == null || widget.selectedPlace == null) return;

    final longitude = widget.selectedPlace!.longitude;
    final latitude = widget.selectedPlace!.latitude;

    try {
      await _mapboxMap!.style.addStyleImage(
        'location_marker',
        1.0,
        await loadImage('assets/icons/marker1.png'),
        false,
        [],
        [],
        null,
      );
    } catch (e) {
      AppLogger.info('failed to add image in route because $e');
      return;
    }

    await _pointAnnotationManager.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(longitude, latitude)),
        iconImage: 'location_marker',
        iconSize: 1.0,
        iconAnchor: IconAnchor.BOTTOM,
      ),
    );
  }

  void _onStyleLoaded(StyleLoadedEventData data) {
    setState(() => _isStyleLoaded = true);
    if (widget.selectedPlace != null && widget.currentPosition != null) {
      _drawRoute();
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _pointAnnotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();
    widget.onMapCreated?.call(mapboxMap, widget.currentPosition);

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
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapWidget(
          key: const ValueKey('mapWidget'),
          styleUri: 'mapbox://styles/mapbox/streets-v12',
          cameraOptions: _cameraOptions,
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoaded,
        ),
        if (_isRouteLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
