import 'package:flutter/material.dart';
import 'package:navigation/widgets/maps/mapbox_widget.dart';
import 'package:navigation/models/locations.dart';
import 'package:navigation/widgets/search/search_bar.dart';
import 'package:navigation/widgets/search/search_results.dart';
import 'package:navigation/widgets/details/location_details.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:navigation/utils/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UdsmPlace> allPlaces = [];
  List<UdsmPlace> filteredPlaces = [];
  bool isLoading = true;
  bool isSearching = false;
  UdsmPlace? selectedPlace;
  MapboxMap? _mapboxMap;
  geo.Position? _currentPosition;
  String _navigationMode = 'walking';
  String _walkTime = 'Calculating...';
  String _walkDistance = '';
  String _driveTime = 'Calculating...';
  String _driveDistance = '';
  bool _shouldShowRoute = false;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  void _handleSearchFocus(bool hasFocus) {
    setState(() {
      if (!hasFocus) {
        isSearching = false;
      } else if (selectedPlace == null) {
        isSearching = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      selectedPlace = null;
      isSearching = true;
      _searchController.clear();
      filteredPlaces = allPlaces;
      _navigationMode = 'walking';
      _shouldShowRoute = false;
    });
  }

  Future<void> _loadPlaces() async {
    final places = await loadUdsmPlaces();
    setState(() {
      allPlaces = places;
      filteredPlaces = places;
      isLoading = false;
    });
  }

  void _filterSearch(String query) {
    final results = allPlaces
        .where(
          (place) => place.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    setState(() {
      filteredPlaces = results;
    });
  }

  void _handleLocationSelect(UdsmPlace place) {
    setState(() {
      selectedPlace = place;
      isSearching = false;
      _shouldShowRoute = false;
    });
  }

  void _handleMapCreated(MapboxMap mapboxMap, geo.Position? position) {
    setState(() {
      _mapboxMap = mapboxMap;
      _currentPosition = position;
    });
    if (selectedPlace != null && !_shouldShowRoute) {
      mapboxMap.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              selectedPlace!.longitude,
              selectedPlace!.latitude,
            ),
          ),
          zoom: 18.0,
          pitch: 60.0,
        ),
        MapAnimationOptions(duration: 1000),
      );
    }
  }

  void _handleTimesUpdated(
    String walkTime,
    String walkDistance,
    String driveTime,
    String driveDistance,
  ) {
    AppLogger.debug(
      'HomeScreen: Times updated - walking=$walkTime ($walkDistance), driving=$driveTime ($driveDistance)',
    );
    setState(() {
      _walkTime = walkTime;
      _walkDistance = walkDistance;
      _driveTime = driveTime;
      _driveDistance = driveDistance;
    });
  }

  void _handleModeChanged(String mode) {
    setState(() {
      _navigationMode = mode;
    });
  }

  void _handleDirectionsRequested(bool showRoute) {
    setState(() {
      _shouldShowRoute = showRoute;
      if (!showRoute) {
        selectedPlace = null;
        isSearching = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'UDSM NAVIGATOR',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MapBoxWidget(
            selectedPlace: selectedPlace,
            onMapCreated: _handleMapCreated,
            onTimesUpdated: _handleTimesUpdated,
            selectedTransportMode: _navigationMode,
            onModeChanged: _handleModeChanged,
            showDirections: _shouldShowRoute,
          ),
          CustomSearchBar(
            controller: _searchController,
            onFocusChange: _handleSearchFocus,
            onSearchChanged: _filterSearch,
            selectedPlace: selectedPlace,
            onClearSelection: _clearSelection,
          ),
          if (isSearching)
            SearchResults(
              onLocationSelect: _handleLocationSelect,
              filteredPlaces: filteredPlaces,
              isLoading: isLoading,
            ),
          if (selectedPlace != null)
            LocationDetails(
              place: selectedPlace!,
              onClose: _clearSelection,
              mapboxMap: _mapboxMap,
              currentPosition: _currentPosition,
              walkTime: _walkTime,
              walkDistance: _walkDistance,
              driveTime: _driveTime,
              driveDistance: _driveDistance,
              onModeChanged: _handleModeChanged,
               navigationMode: _navigationMode,
              onDirectionsRequested: _handleDirectionsRequested,
            ),
        ],
      ),
    );
  }
}
