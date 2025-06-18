import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:navigation/models/locations.dart';

class LocationDetails extends StatefulWidget {
  final UdsmPlace place;
  final VoidCallback onClose;
  final VoidCallback onDirections;
  final VoidCallback onStart;

  const LocationDetails({
    super.key,
    required this.place,
    required this.onClose,
    required this.onDirections,
    required this.onStart,
  });

  @override
  State<LocationDetails> createState() => LocationDetailsState();
}

class LocationDetailsState extends State<LocationDetails> {
  String? _fullScreenImage;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return _fullScreenImage != null
        ? GestureDetector(
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
          )
        : Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: screenHeight * 0.48, // Adjusted to ~48% height
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
                              onPressed: widget.onDirections,
                              icon: const Icon(Icons.directions),
                              label: const Text('Directions'),
                            ),
                            ElevatedButton.icon(
                              onPressed: widget.onStart,
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
          );
  }

  Widget _buildThreeImageLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large left image
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () =>
                  setState(() => _fullScreenImage = widget.place.images[0]),
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

          // Two stacked right images
          Expanded(
            flex: 1,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () =>
                      setState(() => _fullScreenImage = widget.place.images[1]),
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
                  onTap: () =>
                      setState(() => _fullScreenImage = widget.place.images[2]),
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
      ),
    );
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
