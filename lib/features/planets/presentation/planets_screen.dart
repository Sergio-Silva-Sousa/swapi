import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/databank_image.dart';
import '../../../core/widgets/favorite_button.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../favorites/data/favorite.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../data/planet.dart';
import '../data/planets_repository.dart';

final planetsRepositoryProvider = Provider<PlanetsRepository>(
  (ref) => throw UnimplementedError('PlanetsRepository must be provided at startup.'),
);

final planetsProvider = FutureProvider.family<PlanetsPage, String>(
  (ref, query) => ref.watch(planetsRepositoryProvider).list(search: query),
);

class PlanetsScreen extends ConsumerStatefulWidget {
  const PlanetsScreen({super.key});

  @override
  ConsumerState<PlanetsScreen> createState() => _PlanetsScreenState();
}

class _PlanetsScreenState extends ConsumerState<PlanetsScreen> {
  String _query = '';
  String _filter = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(planetsProvider(_query));
    final favoriteIds = ref
            .watch(favoritesProvider)
            .valueOrNull
            ?.where((item) => item.type == 'planet')
            .map((item) => item.itemId)
            .toSet() ??
        <int>{};
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => AsyncErrorView(
        message: 'Não foi possível carregar os planetas.',
        onRetry: () => ref.invalidate(planetsProvider(_query)),
      ),
      data: (page) {
        final climates = <String>{};
        for (final planet in page.items) {
          for (final value in planet.climate.split(',')) {
            if (value.trim().isNotEmpty) climates.add(value.trim());
          }
        }
        final options = <String>['', ...climates];
        final planets = page.items.where((planet) {
          return _filter.isEmpty ||
              planet.climate.toLowerCase().contains(_filter.toLowerCase()) ||
              planet.terrain.toLowerCase().contains(_filter.toLowerCase());
        }).toList();

        return Column(
          children: <Widget>[
            if (page.isStale) const OfflineBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: AppSearchField(
                label: 'Buscar planeta',
                onChanged: _search,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    for (final option in options)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(option.isEmpty ? 'Todos' : option),
                          selected: _filter == option,
                          onSelected: (_) => setState(() => _filter = option),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: planets.isEmpty
                  ? const Center(child: Text('Nenhum planeta encontrado.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: planets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final planet = planets[index];
                        return AppCard(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PlanetDetail(planet: planet),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              DatabankImage.planet(name: planet.name),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      planet.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      children: <Widget>[
                                        InfoChip(
                                          planet.climate,
                                          icon: Icons.thermostat_outlined,
                                        ),
                                        InfoChip(
                                          planet.terrain,
                                          icon: Icons.landscape_outlined,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              FavoriteButton(
                                isFavorite: favoriteIds.contains(planet.id),
                                onPressed: () => _toggleFavorite(ref, planet),
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

void _toggleFavorite(WidgetRef ref, Planet planet) {
  final user = ref.read(authControllerProvider).valueOrNull;
  if (user == null) return;
  ref
      .read(favoritesRepositoryProvider)
      .toggle(
        user.id,
        Favorite(type: 'planet', itemId: planet.id, title: planet.name),
      )
      .then((_) => ref.invalidate(favoritesProvider));
}

class PlanetDetail extends ConsumerWidget {
  const PlanetDetail({super.key, required this.planet});

  final Planet planet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(planet.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Center(child: DatabankImage.planet(name: planet.name, size: 116)),
          const SizedBox(height: 20),
          Text(
            planet.name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: <Widget>[
              InfoChip(planet.climate, icon: Icons.thermostat_outlined),
              InfoChip(planet.terrain, icon: Icons.landscape_outlined),
            ],
          ),
          const SizedBox(height: 26),
          const SectionTitle('Relações'),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              StatTile(
                value: '${planet.residentUrls.length}',
                label: 'Residentes',
                icon: Icons.people_outline_rounded,
              ),
              const SizedBox(width: 12),
              StatTile(
                value: '${planet.filmUrls.length}',
                label: 'Filmes',
                icon: Icons.movie_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              children: <Widget>[
                Icon(Icons.public_outlined, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Dados do catálogo salvos para uso offline',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => _toggleFavorite(ref, planet),
            icon: const Icon(Icons.favorite_border_rounded),
            label: const Text('Adicionar aos favoritos'),
          ),
        ],
      ),
    );
  }
}
