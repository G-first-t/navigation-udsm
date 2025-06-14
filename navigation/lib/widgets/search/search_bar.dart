import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<bool> onFocusChange;
  final ValueChanged<String> onSearchChanged;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onFocusChange,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 49,
      left: 32,
      right: 32,
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
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Search for a place',
            border: InputBorder.none,
            icon: Icon(Icons.search),
          ),
          onTap: () => onFocusChange(true),
          onChanged: onSearchChanged,
        ),
      ),
    );
  }
}