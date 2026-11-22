import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/imdb_image_provider.dart';

/// Poster for a SWAPI film, with an elegant numeric fallback.
class FilmPoster extends ConsumerStatefulWidget {
  const FilmPoster({
    super.key,
    required this.title,
    required this.year,
    required this.episode,
    this.width = 76,
    this.height = 108,
  });

  final String title;
  final int year;
  final int episode;
  final double width;
  final double height;

  @override
  ConsumerState<FilmPoster> createState() => _FilmPosterState();
}

class _FilmPosterState extends ConsumerState<FilmPoster> {
  late Future<String?> _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(FilmPoster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title || oldWidget.year != widget.year) {
      _load();
    }
  }

  void _load() {
    _image = ref.read(imdbImageResolverProvider).imageFor(
          title: widget.title,
          year: widget.year,
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _image,
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null) return _placeholder(context);
        return Semantics(
          label: 'Pôster de ${widget.title}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: url,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
              imageBuilder: (context, imageProvider) => Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              progressIndicatorBuilder: (_, __, ___) => _placeholder(context),
              errorWidget: (_, __, ___) => _placeholder(context),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[colors.primaryContainer, colors.surfaceContainerHighest],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'EPISÓDIO',
            style: TextStyle(
              color: colors.primary,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            '${widget.episode}',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
