import 'package:flutter/material.dart';

/// Compact heart toggle used on catalog list items.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.onPressed,
    this.isFavorite = false,
    this.tooltip = 'Favoritar',
  });

  final VoidCallback onPressed;
  final bool isFavorite;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavorite ? colors.error : colors.onSurfaceVariant,
      ),
    );
  }
}
