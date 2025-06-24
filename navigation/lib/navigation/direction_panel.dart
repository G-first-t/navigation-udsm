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

    return Stack(
      children: [
        // Tappable top container (closes on tap)
        Positioned(
          top: 49,
          left: 32,
          right: 32,
          child: GestureDetector(
            onTap: widget.onClose,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.fiber_manual_record,
                        size: 16,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 8),
                      Expanded(
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

        // Bottom panel
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
                // Walking/Driving TextButtons with underline
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 32, right: 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            TextButton(
                              onPressed: () =>
                                  widget.onModeChanged?.call('walking'),
                              child: Text(
                                'Walking ${widget.walkTime}',
                                style: TextStyle(
                                  fontWeight: widget.navigationMode == 'walking'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            if (widget.navigationMode == 'walking')
                              Container(height: 2, color: Colors.blue),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            TextButton(
                              onPressed: () =>
                                  widget.onModeChanged?.call('driving'),
                              child: Text(
                                'Driving ${widget.driveTime}',
                                style: TextStyle(
                                  fontWeight: widget.navigationMode == 'driving'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            if (widget.navigationMode == 'driving')
                              Container(height: 2, color: Colors.blue),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Time & distance display
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    widget.navigationMode == 'walking'
                        ? '${widget.walkTime} ${widget.walkDistance}'
                        : '${widget.driveTime} ${widget.driveDistance}',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFFB8860B), // dark goldenrod-like yellow
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                const Spacer(),

                // Start Button (unchanged)
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
      ],
    );
  }
}
