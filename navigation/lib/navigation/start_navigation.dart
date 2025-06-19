import 'package:flutter/material.dart';
import 'package:navigation/models/locations.dart';

class StartNavigationPanel extends StatelessWidget {
  final UdsmPlace place;
  final VoidCallback onClose;

  const StartNavigationPanel({
    super.key,
    required this.place,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // Navigation Info
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: screenHeight * 0.3,
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
                  child: Text(
                    'Navigating to ${place.name}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Text(
                  'Follow the route on the map',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Navigation'),
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
            onPressed: onClose,
          ),
        ),
      ],
    );
  }
}