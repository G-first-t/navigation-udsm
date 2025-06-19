import 'package:flutter/material.dart';
import 'package:navigation/models/locations.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;

class DirectionsPanel extends StatefulWidget {
  final UdsmPlace place;
  final VoidCallback onClose;
  final VoidCallback onStart;
  final MapboxMap? mapboxMap;
  final geo.Position? currentPosition;
  final String navigationMode;
  final String walkTime;
  final String walkDistance;
  final String driveTime;
  final String driveDistance;
  final Function(String)? onModeChanged;

  const DirectionsPanel({
    super.key,
    required this.place,
    required this.onClose,
    required this.onStart,
    this.mapboxMap,
    this.currentPosition,
    required this.navigationMode,
    required this.walkTime,
    required this.walkDistance,
    required this.driveTime,
    required this.driveDistance,
    this.onModeChanged,
  });

  @override
  State<DirectionsPanel> createState() => _DirectionsPanelState();
}

class _DirectionsPanelState extends State<DirectionsPanel> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;


    return Stack(
      children: [
        // Modified Search Bar
        Positioned(
          top: 49,
          left: 32,
          right: 32,
          child: GestureDetector(
            onTap: widget.onClose, // Returns to initial search bar state
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
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.fiber_manual_record, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Your Location',
                          style: TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
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
                ],
              ),
            ),
          ),
        ),
        // Bottom Container
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: screenHeight * 0.25,
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
            child: Column(
              children: [
                // Walking/Driving Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.onModeChanged?.call('walking');
                          },
                          icon: const Icon(Icons.directions_walk),
                          label: Text('Walking ${widget.walkTime}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.navigationMode == 'walking' ? Colors.blue[100] : Colors.white,
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.onModeChanged?.call('driving');
                          },
                          icon: const Icon(Icons.directions_car),
                          label: Text('Driving ${widget.driveTime}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.navigationMode == 'driving' ? Colors.blue[100] : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Estimated Time/Distance
                Text(
                  widget.navigationMode == 'walking'
                      ? '${widget.walkTime} ${widget.walkDistance}'
                      : '${widget.driveTime} ${widget.driveDistance}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Start Button
                ElevatedButton.icon(
                  onPressed: widget.onStart,
                  icon: const Icon(Icons.navigation),
                  label: const Text('Start'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // Close Button
        Positioned(
          top: 16,
          right: 16,
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
          ),
        ),
      ],
    );
  }
}