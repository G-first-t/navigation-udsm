import 'package:flutter/material.dart';
import 'package:navigation/models/locations.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<bool> onFocusChange;
  final ValueChanged<String> onSearchChanged;
  final UdsmPlace? selectedPlace;
  final VoidCallback onClearSelection;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onFocusChange,
    required this.onSearchChanged,
    this.selectedPlace,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 49,
      left: 32,
      right: 32,
      child: GestureDetector(
        onTap: selectedPlace != null ? onClearSelection : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
          child: selectedPlace == null
              ? TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Search for a location',
                    border: InputBorder.none,
                    icon: Icon(Icons.search),
                  ),
                  onTap: () => onFocusChange(true),
                  onChanged: onSearchChanged,
                )
              : Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClearSelection,
                    ),
                    Expanded(
                      child: Text(
                        selectedPlace!.name,
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
