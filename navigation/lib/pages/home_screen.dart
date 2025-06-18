import 'package:flutter/material.dart';
import 'package:navigation/widgets/maps/map_widget.dart';
import 'package:navigation/models/locations.dart';
import 'package:navigation/widgets/search/search_bar.dart';
import 'package:navigation/widgets/search/search_results.dart';
import 'package:navigation/widgets/details/location_details.dart';

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
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPlaces();
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
    });
  }

  void _handleDirections() {
    // Implement directions logic (e.g., open navigation)
    print('Directions to ${selectedPlace?.name}');
  }

  void _handleStart() {
    // Implement start navigation logic
    print('Start navigation to ${selectedPlace?.name}');
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
          MapBoxWidget(selectedPlace: selectedPlace),
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
              onDirections: _handleDirections,
              onStart: _handleStart,
            ),
        ],
      ),
    );
  }
}