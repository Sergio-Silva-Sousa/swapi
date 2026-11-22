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
import '../data/people_repository.dart';
import '../data/person.dart';

final peopleRepositoryProvider = Provider<PeopleRepository>(
  (ref) => throw UnimplementedError('PeopleRepository must be provided at startup.'),
);

final peopleProvider = FutureProvider.family<PeoplePage, String>(
  (ref, query) => ref.watch(peopleRepositoryProvider).page(query: query),
);

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  String _query = '';
  String _gender = '';
  String _species = '';
  String _birthYear = '';
  int _pageNumber = 1;
  final List<Person> _loaded = <Person>[];
  bool _hasNext = true;
  bool _loadingMore = false;
  bool _isStale = false;
  String? _loadError;
  Timer? _debounce;

  Future<void> _loadNext() async {
    if (_loadingMore || !_hasNext) return;
    setState(() {
      _loadingMore = true;
      _loadError = null;
    });
    try {
      final result = await ref.read(peopleRepositoryProvider).page(
            page: _pageNumber,
            query: _query,
          );
      if (!mounted) return;
      setState(() {
        _loaded.addAll(result.people);
        _hasNext = result.hasNext;
        _isStale = result.isStale;
        _pageNumber++;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _loadError = 'Não foi possível carregar os personagens.';
      });
    }
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _query = value.trim();
        _pageNumber = 1;
        _loaded.clear();
        _hasNext = true;
        _loadError = null;
      });
      _loadNext();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNext());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final favoriteIds = ref
            .watch(favoritesProvider)
            .valueOrNull
            ?.where((item) => item.type == 'person')
            .map((item) => item.itemId)
            .toSet() ??
        <int>{};
    final people = _loaded.where((person) {
      final matchesGender = _gender.isEmpty || person.gender == _gender;
      final matchesBirth = _birthYear.isEmpty ||
          person.birthYear.toLowerCase().contains(_birthYear);
      final matchesSpecies = _species.isEmpty ||
          (_species == 'human'
              ? person.speciesUrls.isNotEmpty
              : person.speciesUrls.isEmpty);
      return matchesGender && matchesBirth && matchesSpecies;
    }).toList();

    return Column(
      children: <Widget>[
        if (_isStale) const OfflineBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: AppSearchField(
            label: 'Buscar personagem',
            onChanged: _search,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final entry in <String, String>{
                  '': 'Todos',
                  'male': 'Masculino',
                  'female': 'Feminino',
                  'unknown': 'Desconhecido',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _gender == entry.key,
                      onSelected: (_) => setState(() => _gender = entry.key),
                    ),
                  ),
                Container(width: 1, height: 24, color: colors.outlineVariant),
                const SizedBox(width: 8),
                for (final entry in <String, String>{
                  '': 'Todas espécies',
                  'human': 'Com espécie',
                  'other': 'Sem espécie',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _species == entry.key,
                      onSelected: (_) => setState(() => _species = entry.key),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: TextField(
            onChanged: (value) =>
                setState(() => _birthYear = value.trim().toLowerCase()),
            decoration: const InputDecoration(
              labelText: 'Ano de nascimento (ex.: 19BBY)',
              prefixIcon: Icon(Icons.cake_outlined),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: _loaded.isEmpty && _loadingMore
              ? const Center(child: CircularProgressIndicator())
              : _loaded.isEmpty && _loadError != null
                  ? AsyncErrorView(
                      message: _loadError!,
                      onRetry: _loadNext,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: people.length + (_hasNext ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (index == people.length) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _loadNext(),
                          );
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final person = people[index];
                        return AppCard(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PersonDetail(person: person),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              DatabankImage.person(name: person.name),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      person.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      children: <Widget>[
                                        InfoChip(person.gender),
                                        InfoChip(person.birthYear),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              FavoriteButton(
                                isFavorite: favoriteIds.contains(person.id),
                                onPressed: () => _toggleFavorite(ref, person),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
        if (_loadError != null && _loaded.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: AsyncErrorView(message: _loadError!, onRetry: _loadNext),
          ),
      ],
    );
  }
}

void _toggleFavorite(WidgetRef ref, Person person) {
  final user = ref.read(authControllerProvider).valueOrNull;
  if (user == null) return;
  ref
      .read(favoritesRepositoryProvider)
      .toggle(
        user.id,
        Favorite(type: 'person', itemId: person.id, title: person.name),
      )
      .then((_) => ref.invalidate(favoritesProvider));
}

class PersonDetail extends ConsumerWidget {
  const PersonDetail({super.key, required this.person});

  final Person person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(person.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Center(child: DatabankImage.person(name: person.name, size: 116)),
          const SizedBox(height: 20),
          Text(
            person.name,
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
              InfoChip(person.gender, icon: Icons.person_outline_rounded),
              InfoChip(person.birthYear, icon: Icons.cake_outlined),
            ],
          ),
          const SizedBox(height: 26),
          const SectionTitle('Relações'),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              StatTile(
                value: '${person.filmUrls.length}',
                label: 'Filmes',
                icon: Icons.movie_outlined,
              ),
              const SizedBox(width: 12),
              StatTile(
                value: '${person.speciesUrls.length}',
                label: 'Espécies',
                icon: Icons.pets_outlined,
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
                    'Planeta natal',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => _toggleFavorite(ref, person),
            icon: const Icon(Icons.favorite_border_rounded),
            label: const Text('Adicionar aos favoritos'),
          ),
        ],
      ),
    );
  }
}
