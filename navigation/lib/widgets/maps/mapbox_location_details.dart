import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:navigation/models/locations.dart';
import 'package:navigation/widgets/maps/mapbox_utils.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:navigation/utils/logger.dart';

class MapBoxLocationDetailsWidget extends StatefulWidget {
  final UdsmPlace? selectedPlace;
  final geo.Position? currentPosition;
  final Function(MapboxMap, geo.Position?)? onMapCreated;

  const MapBoxLocationDetailsWidget({
    super.key,
    required this.selectedPlace,
    this.currentPosition,
    this.onMapCreated,
  });

  @override
  State<MapBoxLocationDetailsWidget> createState() =>
      _MapBoxLocationDetailsWidgetState();
}

class _MapBoxLocationDetailsWidgetState
    extends State<MapBoxLocationDetailsWidget> {
  MapboxMap? _mapboxMap;
  late PointAnnotationManager _pointAnnotationManager;
  bool _isStyleLoaded = false;
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
  }

  Future<void> _updateMapForSelectedPlace() async {
    AppLogger.info('updating location to selectedPlace');
    if (!mounted ||
        widget.selectedPlace == null ||
        _mapboxMap == null ||
        !_isStyleLoaded)
      return;

    final longitude = widget.selectedPlace!.longitude;
    final latitude = widget.selectedPlace!.latitude;
    AppLogger.info('selected place $longitude');
    AppLogger.info('selected place $latitude');

    await _pointAnnotationManager.deleteAll();

    await _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)),
        zoom: 18.0,
        pitch: 60.0,
        anchor: ScreenCoordinate(
          x: MediaQuery.of(context).size.width / 2,
          y: 40,
        ),
      ),
      MapAnimationOptions(duration: 1000),
    );

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
      AppLogger.error('failed to add image in location detail  $e');

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
    if (widget.selectedPlace != null) {
      _updateMapForSelectedPlace();
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
    return MapWidget(
      key: const ValueKey('mapWidget'),
      styleUri: 'mapbox://styles/mapbox/streets-v12',
      cameraOptions: _cameraOptions,
      onMapCreated: _onMapCreated,
      onStyleLoadedListener: _onStyleLoaded,
    );
  }
}
