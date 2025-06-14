import 'package:flutter/material.dart';
import '../../models/locations.dart';

class SearchResults extends StatelessWidget {
  final ValueChanged<UdsmPlace> onLocationSelect;
  final List<UdsmPlace> filteredPlaces;
  final bool isLoading;

  const SearchResults({
    super.key,
    required this.onLocationSelect,
    required this.filteredPlaces,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Positioned(
      top: 180,
      left: 0,
      right: 0,
      bottom: keyboardHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: filteredPlaces.length,
                itemBuilder: (ctx, index) => Column(
                  children: [
                    Container(
                      height: 72,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              0.05,
                            ), // light shadow
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),

                      child: ListTile(
                        leading: const Icon(Icons.near_me, color: Colors.blue),
                        title: Text(
                          filteredPlaces[index].name,
                          style: TextStyle(color: Colors.black),
                        ),
                        trailing: const Icon(Icons.turn_right_outlined),
                        onTap: () => onLocationSelect(filteredPlaces[index]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
