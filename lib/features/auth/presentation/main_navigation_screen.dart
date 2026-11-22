import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:swapo/features/films/presentation/films_screen.dart';
import 'package:swapo/features/people/presentation/people_screen.dart';
import 'package:swapo/features/planets/presentation/planets_screen.dart';
import 'package:swapo/features/favorites/presentation/favorites_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  var _index = 0;

  static const _destinations = <_Destination>[
    _Destination('Filmes', Icons.movie_outlined, 'Os filmes da saga'),
    _Destination('Personagens', Icons.people_outline, 'Quem habita a galáxia'),
    _Destination('Planetas', Icons.public_outlined, 'Mundos para explorar'),
    _Destination('Favoritos', Icons.favorite_outline, 'Sua coleção pessoal'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final destination = _destinations[_index];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 84,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 6),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[colors.primary, colors.secondary],
              ),
            ),
            child: Icon(Icons.auto_awesome, color: colors.onPrimary, size: 22),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'STAR WARS',
              style: TextStyle(
                color: colors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              destination.label,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Perfil',
              onPressed: () => context.push('/perfil'),
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: colors.primary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                destination.subtitle,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _index == 0
          ? const FilmsScreen()
          : _index == 1
              ? const PeopleScreen()
              : _index == 2
                  ? const PlanetsScreen()
                  : const FavoritesScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.icon, color: colors.primary),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.subtitle);

  final String label;
  final IconData icon;
  final String subtitle;
}
