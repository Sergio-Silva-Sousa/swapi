
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/planets_repository.dart';

final planetsRepositoryProvider = Provider<PlanetsRepository>(
  (ref) => throw UnimplementedError(),
);

final planetsProvider = FutureProvider.family(
  (ref, String query) {
    return ref.watch(planetsRepositoryProvider).list(search: query);
  },
);

class PlanetsScreen extends ConsumerStatefulWidget {
  const PlanetsScreen({super.key});

  @override
  ConsumerState<PlanetsScreen> createState() => _PlanetsScreenState();
}

class _PlanetsScreenState extends ConsumerState<PlanetsScreen> {
  String q = '';
  String filter = '';

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(planetsProvider(q));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: const InputDecoration(
              labelText: 'Buscar planeta',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),

        Expanded(
          child: s.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Center(
              child: Text('$e'),
            ),
            data: (items) {
              final x = items.where((p) {
                return filter.isEmpty ||
                    p.climate.contains(filter) ||
                    p.terrain.contains(filter);
              }).toList();

              return ListView(
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      '',
                      'arid',
                      'temperate',
                      'desert',
                      'grasslands',
                    ].map((v) {
                      return ChoiceChip(
                        label: Text(v.isEmpty ? 'Todos' : v),
                        selected: filter == v,
                        onSelected: (_) {
                          setState(() => filter = v);
                        },
                      );
                    }).toList(),
                  ),

                  ...x.map((p) {
                    return ListTile(
                      leading: const Icon(Icons.public),
                      title: Text(p.name),
                      subtitle: Text('${p.climate} · ${p.terrain}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => Scaffold(
                              appBar: AppBar(
                                title: Text(p.name),
                              ),
                              body: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Residentes: ${p.residentUrls.length}\n'
                                  'Filmes: ${p.filmUrls.length}',
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
