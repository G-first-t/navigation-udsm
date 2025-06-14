import 'package:flutter/material.dart';
import 'package:navigation/widgets/maps/map_widget.dart';
import 'package:navigation/models/locations.dart';
import 'package:navigation/widgets/search/search_bar.dart';
import 'package:navigation/widgets/search/search_results.dart';

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

  bool showLocationView = false;
  bool isSearching = false;
  UdsmPlace? selectedPlace;

  void _handleSearchFocus(bool hasFocus) {
    setState(() => isSearching = hasFocus && !showLocationView);
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
      showLocationView = true;
      isSearching = false;
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'UDSM NAVIGATOR',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),

      body: Stack(
        children: [
          MapBoxWidget(),
          CustomSearchBar(
            controller: _searchController,
            onFocusChange: _handleSearchFocus,
            onSearchChanged: _filterSearch,
          ),
          if (isSearching)
              SearchResults(
                onLocationSelect: _handleLocationSelect,
                filteredPlaces: filteredPlaces,
                isLoading: isLoading,
              ),
        ],
      ),
    );
  }
}
