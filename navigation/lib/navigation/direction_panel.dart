import 'package:flutter/material.dart';
import 'package:navigation/models/locations.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:navigation/utils/logger.dart';

class DirectionsPanel extends StatefulWidget {
  final UdsmPlace place;
  final VoidCallback onClose;
  final VoidCallback onStart;
  final geo.Position? currentPosition;

  final Function(String) onModeChanged; // To notify parent when transport mode changes
  final Function(bool) onNavigationChanged;

  const DirectionsPanel({
    super.key,
    required this.place,
    required this.onClose,
    required this.onStart,
    required this.onModeChanged,
    required this.onNavigationChanged,
    this.currentPosition,
  });

  @override
  State<DirectionsPanel> createState() => _DirectionsPanelState();
}

class _DirectionsPanelState extends State<DirectionsPanel> {
  String _selectedTransportMode = 'walking'; // or 'driving'

  String _walkTime = 'Calculating...';
  String _driveTime = 'Calculating...';

  String _walkDistance = '';
  String _driveDistance = '';

  /// Methods to set estimated times externally
  void setWalkTime(String time, String distance) {
    setState(() {
      _walkTime = time;
      _walkDistance = distance;
    });
  }

  void setDriveTime(String time, String distance) {
    setState(() {
      _driveTime = time;
      _driveDistance = distance;
    });
  }

  /// Handle mode change
  void _handleTransportSelect(String mode) {
    setState(() {
      _selectedTransportMode = mode;
      widget.onModeChanged(mode); // Notify parent
      AppLogger.debug('Transport mode changed to: $mode');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final time = _selectedTransportMode == 'walking' ? _walkTime : _driveTime;
    final distance = _selectedTransportMode == 'walking' ? _walkDistance : _driveDistance;

    return Stack(
      children: [
        // Location info card
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
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.fiber_manual_record, size: 16, color: Colors.blue),
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleTransportSelect('walking'),
                          icon: const Icon(Icons.directions_walk),
                          label: Text('Walking $_walkTime'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedTransportMode == 'walking'
                                ? Colors.blue[100]
                                : Colors.white,
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleTransportSelect('driving'),
                          icon: const Icon(Icons.directions_car),
                          label: Text('Driving $_driveTime'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedTransportMode == 'driving'
                                ? Colors.blue[100]
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$time $distance',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.yellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
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

        // Close icon
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
