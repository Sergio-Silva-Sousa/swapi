import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:swapo/features/films/presentation/films_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  var _index = 0;

  static const _destinations = <_Destination>[
    _Destination('Filmes', Icons.movie_outlined),
    _Destination('Personagens', Icons.people_outline),
    _Destination('Planetas', Icons.public_outlined),
    _Destination('Favoritos', Icons.favorite_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final destination = _destinations[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text(destination.label),
        actions: [
          IconButton(
            tooltip: 'Perfil',
            onPressed: () => context.push('/perfil'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: _index == 0 ? const FilmsScreen() : Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(destination.icon, size: 64),
              const SizedBox(height: 16),
              Text(
                destination.label,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'O catálogo será conectado à fonte de dados na próxima fatia.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon);

  final String label;
  final IconData icon;
}
