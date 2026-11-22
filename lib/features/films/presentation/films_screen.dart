import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/film.dart';
import 'films_provider.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../favorites/data/favorite.dart';
import '../../favorites/presentation/favorites_screen.dart';

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
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: FilledButton(
          onPressed: () => ref.invalidate(filmsProvider),
          child: const Text('Tentar novamente'),
        ),
      ),
      data: (result) {
        final directors = result.films.map((film) => film.director).toSet().toList()..sort();
        final years = result.films.map((film) => film.releaseDate.year).toSet().toList()..sort();
        final filtered = result.films.where((film) {
          return film.title.toLowerCase().contains(_query.toLowerCase()) &&
              (_director == null || film.director == _director) &&
              (_year == null || film.releaseDate.year == _year);
        }).toList();
        return Column(children: [
          if (result.isStale) const MaterialBanner(content: Text('Dados offline e desatualizados.'), actions: []),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Buscar filme', border: OutlineInputBorder()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              DropdownButton<String?>(value: _director, hint: const Text('Diretor'), items: [const DropdownMenuItem(value: null, child: Text('Todos')), ...directors.map((value) => DropdownMenuItem(value: value, child: Text(value)))], onChanged: (value) => setState(() => _director = value)),
              const SizedBox(width: 16),
              DropdownButton<int?>(value: _year, hint: const Text('Ano'), items: [const DropdownMenuItem(value: null, child: Text('Todos')), ...years.map((value) => DropdownMenuItem(value: value, child: Text('$value')))], onChanged: (value) => setState(() => _year = value)),
            ]),
          ),
          Expanded(child: ListView.builder(itemCount: filtered.length, itemBuilder: (context, index) {
            final film = filtered[index];
            return ListTile(
              leading: CircleAvatar(child: Text('${film.episodeId}')),
              title: Text(film.title), subtitle: Text('${film.releaseDate.year} · ${film.director}'),
              trailing: IconButton(icon: const Icon(Icons.favorite_border), tooltip: 'Favoritar', onPressed: () { final user = ref.read(authControllerProvider).valueOrNull; if (user != null) { ref.read(favoritesRepositoryProvider).toggle(user.id, Favorite(type: 'film', itemId: film.id, title: film.title)).then((_) => ref.invalidate(favoritesProvider)); } }),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => FilmDetailScreen(film: film))),
            );
          })),
        ]);
      },
    );
  }
}

class FilmDetailScreen extends StatelessWidget {
  const FilmDetailScreen({super.key, required this.film});
  final Film film;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(film.title)),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text('Episódio ${film.episodeId}', style: Theme.of(context).textTheme.titleLarge),
      Text('${film.releaseDate.year} · Direção: ${film.director}'),
      const SizedBox(height: 24), Text(film.openingCrawl),
      const SizedBox(height: 24), Text('Personagens: ${film.characterUrls.length}'),
      Text('Planetas: ${film.planetUrls.length}'),
    ]),
  );
}
