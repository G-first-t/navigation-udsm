import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:navigation/models/locations.dart';
import 'package:navigation/navigation/direction_panel.dart';
import 'package:navigation/navigation/start_navigation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:navigation/utils/logger.dart';

class LocationDetails extends StatefulWidget {
  final UdsmPlace place;
  final VoidCallback onClose;
  final MapboxMap? mapboxMap;
  final geo.Position? currentPosition;
  final String walkTime;
  final String walkDistance;
  final String driveTime;
  final String driveDistance;
  final String navigationMode;
  
  final Function(String)? onModeChanged;
  final Function(bool)? onDirectionsRequested;

  const LocationDetails({
    super.key,
    required this.place,
    required this.onClose,
    this.mapboxMap,
    this.currentPosition,
    required this.walkTime,
    required this.walkDistance,
    required this.driveTime,
    required this.driveDistance,
    required this.navigationMode,
    this.onModeChanged,
    this.onDirectionsRequested,
  });

  @override
  State<LocationDetails> createState() => LocationDetailsState();
}

enum ViewState { details, directions, start }

class LocationDetailsState extends State<LocationDetails> {
  String? _fullScreenImage;
  ViewState _currentView = ViewState.details;
  bool _fromDirections = false;
  

  void _showDirections() {
    setState(() {
      _currentView = ViewState.directions;
      _fromDirections = true;
    });
    widget.onDirectionsRequested?.call(true);
  }
  void _showStartNavigation() {
    setState(() {
      _currentView = ViewState.start;
    });
  }

  void _returnToPreviousView() {
    setState(() {
      if (_currentView == ViewState.start && _fromDirections) {
        _currentView = ViewState.directions;
      } else {
        _currentView = ViewState.details;
        _fromDirections = false;
      }
    });
    if (_currentView == ViewState.details) {
      widget.onDirectionsRequested?.call(false);
    }
  }

  
  void _changeMode(String mode) {
    widget.onModeChanged?.call(mode);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (_fullScreenImage != null) {
      return GestureDetector(
        onTap: () => setState(() => _fullScreenImage = null),
        child: Stack(
          children: [
            Image.asset(
              _fullScreenImage!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _fullScreenImage = null),
              ),
            ),
          ],
        ),
      );
    }

    switch (_currentView) {
      case ViewState.directions:
        return DirectionsPanel(
          place: widget.place,
          onClose: _returnToPreviousView,
          onStart: _showStartNavigation,
          mapboxMap: widget.mapboxMap,
          currentPosition: widget.currentPosition,
          navigationMode: widget.navigationMode,
          walkTime: widget.walkTime,
          walkDistance: widget.walkDistance,
          driveTime: widget.driveTime,
          driveDistance: widget.driveDistance,
          onModeChanged: _changeMode,
        );
      case ViewState.start:
        return StartNavigationPanel(
          place: widget.place,
          onClose: _returnToPreviousView,
        );
      case ViewState.details:
      default:
        return Stack(
          children: [
            Positioned(
              top: 49,
              left: 32,
              right: 32,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.place.name,
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: screenHeight * 0.48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 0),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and close icon
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.place.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: widget.onClose,
                              ),
                            ],
                          ),
                        ),
                        // Action buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _showDirections,
                                icon: const Icon(Icons.directions),
                                label: const Text('Directions'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _showStartNavigation,
                                icon: const Icon(Icons.navigation),
                                label: const Text('Start'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Images
                        if (widget.place.images.isNotEmpty)
                          widget.place.images.length == 3
                              ? _buildThreeImageLayout()
                              : _buildCarouselLayout(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildThreeImageLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () => setState(() => _fullScreenImage = widget.place.images[0]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  widget.place.images[0],
                  height: 320,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _fullScreenImage = widget.place.images[1]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      widget.place.images[1],
                      height: 154,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _fullScreenImage = widget.place.images[2]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      widget.place.images[2],
                      height: 154,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ));
     
  }

  Widget _buildCarouselLayout() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 320,
          viewportFraction: widget.place.images.length > 1 ? 0.85 : 1.0,
          enableInfiniteScroll: widget.place.images.length > 1,
          enlargeCenterPage: true,
        ),
        items: widget.place.images.map((imagePath) {
          return GestureDetector(
            onTap: () => setState(() => _fullScreenImage = imagePath),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}