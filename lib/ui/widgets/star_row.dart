import 'package:flutter/material.dart';

import '../theme.dart';

class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.filled,
    this.size = 28,
    this.total = 3,
  });

  final int filled;
  final double size;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < filled ? CoolColors.sun : CoolColors.ink.withValues(alpha: 0.25),
              size: size,
            ),
          ),
      ],
    );
  }
}
