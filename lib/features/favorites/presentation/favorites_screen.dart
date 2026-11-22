import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_components.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/favorite.dart';
import '../data/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => throw UnimplementedError(
    'FavoritesRepository must be provided at startup.',
  ),
);

final favoritesProvider = FutureProvider<List<Favorite>>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return Future<List<Favorite>>.value(const <Favorite>[]);
  return ref.watch(favoritesRepositoryProvider).list(user.id);
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  static const _tabs = <(String label, IconData icon, String type)>[
    ('Filmes', Icons.movie_outlined, 'film'),
    ('Personagens', Icons.people_outline, 'person'),
    ('Planetas', Icons.public_outlined, 'planet'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(favoritesProvider);

    return DefaultTabController(
      length: _tabs.length,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: colors.primary,
                unselectedLabelColor: colors.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                tabs: <Widget>[
                  for (final tab in _tabs)
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(tab.$2, size: 16),
                          const SizedBox(width: 6),
                          Text(tab.$1),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AsyncErrorView(
                message: 'Não foi possível carregar os favoritos.',
                onRetry: () => ref.invalidate(favoritesProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.favorite_border_rounded,
                          size: 56,
                          color: colors.primary.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum favorito ainda',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Toque no coração dos itens para salvá-los aqui.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                return TabBarView(
                  children: <Widget>[
                    for (final tab in _tabs)
                      _FavoriteList(
                        favorites: items
                            .where((item) => item.type == tab.$3)
                            .toList(),
                        icon: tab.$2,
                        onRemove: (favorite) => _remove(ref, favorite),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void _remove(WidgetRef ref, Favorite favorite) {
  final user = ref.read(authControllerProvider).valueOrNull;
  if (user == null) return;
  ref
      .read(favoritesRepositoryProvider)
      .toggle(user.id, favorite)
      .then((_) => ref.invalidate(favoritesProvider));
}

class _FavoriteList extends StatelessWidget {
  const _FavoriteList({
    required this.favorites,
    required this.icon,
    required this.onRemove,
  });

  final List<Favorite> favorites;
  final IconData icon;
  final ValueChanged<Favorite> onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (favorites.isEmpty) {
      return Center(
        child: Text(
          'Nada por aqui ainda.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: favorites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final favorite = favorites[index];
        return AppCard(
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                child: Icon(icon, color: colors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      favorite.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InfoChip(favorite.type),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remover dos favoritos',
                onPressed: () => onRemove(favorite),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
