import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/favorite_button.dart';
import '../../../core/widgets/film_poster.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../favorites/data/favorite.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../data/film.dart';
import 'films_provider.dart';

class FilmsScreen extends ConsumerStatefulWidget {
  const FilmsScreen({super.key});

  @override
  ConsumerState<FilmsScreen> createState() => _FilmsScreenState();
}

class _FilmsScreenState extends ConsumerState<FilmsScreen> {
  String _query = '';
  String? _director;
  int? _year;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(filmsProvider);
    final favoriteIds = ref
            .watch(favoritesProvider)
            .valueOrNull
            ?.where((item) => item.type == 'film')
            .map((item) => item.itemId)
            .toSet() ??
        <int>{};
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AsyncErrorView(
        message: 'Não foi possível carregar os filmes.',
        onRetry: () => ref.invalidate(filmsProvider),
      ),
      data: (result) {
        final directors = result.films.map((film) => film.director).toSet().toList()
          ..sort();
        final years = result.films
            .map((film) => film.releaseDate.year)
            .toSet()
            .toList()
          ..sort();
        final filtered = result.films.where((film) {
          return film.title.toLowerCase().contains(_query.toLowerCase()) &&
              (_director == null || film.director == _director) &&
              (_year == null || film.releaseDate.year == _year);
        }).toList();

        return Column(
          children: <Widget>[
            if (result.isStale) const OfflineBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: AppSearchField(
                label: 'Buscar filme',
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    FilterDropdown<String?>(
                      label: 'Diretor',
                      value: _director,
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos os diretores'),
                        ),
                        ...directors.map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => _director = value),
                    ),
                    const SizedBox(width: 8),
                    FilterDropdown<int?>(
                      label: 'Ano',
                      value: _year,
                      items: <DropdownMenuItem<int?>>[
                        const DropdownMenuItem(value: null, child: Text('Todos os anos')),
                        ...years.map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value'),
                          ),
                        ),
                      ],
                      onChanged: (value) => setState(() => _year = value),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filtered.length} ${filtered.length == 1 ? 'filme' : 'filmes'}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Nenhum filme encontrado.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final film = filtered[index];
                        return AppCard(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => FilmDetailScreen(film: film),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              FilmPoster(
                                title: film.title,
                                year: film.releaseDate.year,
                                episode: film.episodeId,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      film.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: <Widget>[
                                        InfoChip(
                                          '${film.releaseDate.year}',
                                          icon: Icons.calendar_month_outlined,
                                        ),
                                        InfoChip(
                                          film.director,
                                          icon: Icons.person_outline_rounded,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              FavoriteButton(
                                isFavorite: favoriteIds.contains(film.id),
                                onPressed: () => _toggleFavorite(ref, film),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

void _toggleFavorite(WidgetRef ref, Film film) {
  final user = ref.read(authControllerProvider).valueOrNull;
  if (user == null) return;
  ref
      .read(favoritesRepositoryProvider)
      .toggle(
        user.id,
        Favorite(type: 'film', itemId: film.id, title: film.title),
      )
      .then((_) => ref.invalidate(favoritesProvider));
}

class FilmDetailScreen extends ConsumerWidget {
  const FilmDetailScreen({super.key, required this.film});

  final Film film;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(film.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Center(
            child: FilmPoster(
              title: film.title,
              year: film.releaseDate.year,
              episode: film.episodeId,
              width: 170,
              height: 250,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            film.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: <Widget>[
              InfoChip('Episódio ${film.episodeId}'),
              InfoChip('${film.releaseDate.year}', icon: Icons.calendar_month_outlined),
              InfoChip(film.director, icon: Icons.person_outline_rounded),
            ],
          ),
          const SizedBox(height: 26),
          const SectionTitle('Abertura'),
          const SizedBox(height: 10),
          AppCard(
            child: Text(
              film.openingCrawl.replaceAll('\r\n', ' ').replaceAll('\n', ' '),
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.6),
            ),
          ),
          const SizedBox(height: 26),
          const SectionTitle('Relações'),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              StatTile(
                value: '${film.characterUrls.length}',
                label: 'Personagens',
                icon: Icons.people_outline_rounded,
              ),
              const SizedBox(width: 12),
              StatTile(
                value: '${film.planetUrls.length}',
                label: 'Planetas',
                icon: Icons.public_outlined,
              ),
            ],
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => _toggleFavorite(ref, film),
            icon: const Icon(Icons.favorite_border_rounded),
            label: const Text('Adicionar aos favoritos'),
          ),
        ],
      ),
    );
  }
}
