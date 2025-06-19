import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:navigation/models/locations.dart';
import 'package:navigation/widgets/maps/mapbox_utils.dart';
import 'package:navigation/widgets/maps/mapbox_location_details.dart';
import 'package:navigation/widgets/maps/mapbox_directions_widget.dart';
import 'package:navigation/utils/logger.dart';

class MapBoxWidget extends StatefulWidget {
  final UdsmPlace? selectedPlace;
  final Function(String walkTime, String walkDistance, String driveTime, String driveDistance)? onTimesUpdated;
  final String selectedTransportMode;
  final Function(String)? onModeChanged;
  final Function(MapboxMap, geo.Position?)? onMapCreated;
  final bool showDirections;

  const MapBoxWidget({
    super.key,
    required this.selectedPlace,
    this.onTimesUpdated,
    required this.selectedTransportMode,
    this.onModeChanged,
    this.onMapCreated,
    this.showDirections = false,
  });

  @override
  State<MapBoxWidget> createState() => _MapBoxWidgetState();
}

class _MapBoxWidgetState extends State<MapBoxWidget> {
  geo.Position? _currentPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    AppLogger.info('MapBoxWidget: initState -> initializing location...');
  }

  @override
  void didUpdateWidget(covariant MapBoxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPlace != widget.selectedPlace ||
        oldWidget.selectedTransportMode != widget.selectedTransportMode ||
        oldWidget.showDirections != widget.showDirections) {
      AppLogger.info(
        'MapBoxWidget props updated: selectedPlace=${widget.selectedPlace?.name}, '
        'mode=${widget.selectedTransportMode}, showDirections=${widget.showDirections}',
      );
      setState(() {}); // Trigger rebuild to reflect changes
    }
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await initializeLocation(context);
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
      AppLogger.info('Location initialized: $_currentPosition');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppLogger.info('Location initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentPosition == null && widget.selectedPlace == null) {
      return const Center(child: Text('Unable to get user location'));
    }

    AppLogger.info(
      'Rendering MapBoxWidget: showDirections=${widget.showDirections}, '
      'mode=${widget.selectedTransportMode}, selectedPlace=${widget.selectedPlace?.name}',
    );

    const validModes = ['walking', 'driving'];

    if (widget.showDirections && validModes.contains(widget.selectedTransportMode)) {
      return MapBoxDirectionsWidget(
        selectedPlace: widget.selectedPlace,
        currentPosition: _currentPosition,
        selectedTransportMode: widget.selectedTransportMode,
        onTimesUpdated: widget.onTimesUpdated,
        onModeChanged: widget.onModeChanged,
        onMapCreated: widget.onMapCreated,
      );
    }

    return MapBoxLocationDetailsWidget(
      key: ValueKey(widget.selectedPlace?.name ?? 'default'), // Ensure rebuild on place change
      selectedPlace: widget.selectedPlace,
      currentPosition: _currentPosition,
      onMapCreated: widget.onMapCreated,
    );
  }
}