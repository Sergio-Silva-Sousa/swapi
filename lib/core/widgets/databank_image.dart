import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/databank_image_provider.dart';

/// Circular Databank portrait/planet image with a graceful letter fallback.
class DatabankImage extends ConsumerStatefulWidget {
  const DatabankImage.person({
    super.key,
    required this.name,
    this.size = 52,
  }) : _isPerson = true;

  const DatabankImage.planet({
    super.key,
    required this.name,
    this.size = 52,
  }) : _isPerson = false;

  final String name;
  final double size;
  final bool _isPerson;

  @override
  ConsumerState<DatabankImage> createState() => _DatabankImageState();
}

class _DatabankImageState extends ConsumerState<DatabankImage> {
  late Future<String?> _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(DatabankImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) _load();
  }

  void _load() {
    final resolver = ref.read(databankImageResolverProvider);
    _image = widget._isPerson
        ? resolver.personImage(widget.name)
        : resolver.planetImage(widget.name);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _image,
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null) return _fallback(context);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: Semantics(
            label: 'Imagem de ${widget.name}',
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: url,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
                placeholder: (_, __) => _fallback(context),
                errorWidget: (_, __, ___) => _fallback(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _fallback(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = widget.name.isEmpty ? '?' : widget.name[0].toUpperCase();
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[colors.primaryContainer, colors.surfaceContainerHighest],
        ),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: colors.primary,
            fontSize: widget.size * 0.36,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
