
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/favorite.dart';
import '../data/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => throw UnimplementedError(),
);

final favoritesProvider = FutureProvider<List<Favorite>>((ref) {
  final u = ref.watch(authControllerProvider).valueOrNull;

  return u == null
      ? Future.value([])
      : ref.watch(favoritesRepositoryProvider).list(u.id);
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(favoritesProvider);

    return s.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (e, _) => Center(
        child: Text('$e'),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text('Nenhum favorito ainda.'),
          );
        }

        return ListView(
          children: items.map((f) {
            return ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(f.title),
              subtitle: Text(f.type),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  final u = ref
                      .read(authControllerProvider)
                      .valueOrNull;

                  if (u != null) {
                    ref
                        .read(favoritesRepositoryProvider)
                        .toggle(u.id, f)
                        .then((_) {
                          ref.invalidate(favoritesProvider);
                        });
                  }
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
