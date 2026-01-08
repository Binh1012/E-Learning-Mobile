import 'package:flutter/material.dart';

class DotWidget extends StatelessWidget {
  final bool isActive;

  const DotWidget({
    super.key,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3DD598) : const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}