import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import 'core/api/api_client.dart';
import 'core/api/databank_image_provider.dart';
import 'core/api/databank_image_resolver.dart';
import 'core/api/imdb_image_provider.dart';
import 'core/api/imdb_image_resolver.dart';
import 'core/cache/api_cache_store.dart';
import 'core/database/app_database.dart';
import 'core/network/connectivity_network_status.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/auth/presentation/profile_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/films/data/films_repository.dart';
import 'features/films/presentation/films_provider.dart';
import 'features/people/data/people_repository.dart';
import 'features/people/presentation/people_screen.dart';
import 'features/planets/data/planets_repository.dart';
import 'features/planets/presentation/planets_screen.dart';
import 'features/favorites/data/favorites_repository.dart';
import 'features/favorites/presentation/favorites_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await AppDatabase.open();
  final cache = DriftApiCacheStore(database.executor);
  await cache.initialize();
  final authRepository = await LocalAuthRepository.open(database.executor);
  final favoritesRepository = await FavoritesRepository.open(database.executor);
  final apiClient = ApiClient(
    dio: Dio(),
    cache: cache,
    networkStatus: ConnectivityNetworkStatus(Connectivity()),
  );
  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        filmsRepositoryProvider.overrideWithValue(FilmsRepository(apiClient)),
        peopleRepositoryProvider.overrideWithValue(PeopleRepository(apiClient)),
        planetsRepositoryProvider.overrideWithValue(PlanetsRepository(apiClient)),
        favoritesRepositoryProvider.overrideWithValue(favoritesRepository),
        databankImageResolverProvider.overrideWithValue(DatabankImageResolver(apiClient)),
        imdbImageResolverProvider.overrideWithValue(ImdbImageResolver(apiClient)),
      ],
      child: const SwapoApp(),
    ),
  );
}

class SwapoApp extends StatelessWidget {
  const SwapoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Star Wars Databank',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),
    GoRoute(
      path: '/cadastro',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/perfil', builder: (context, state) => const ProfileScreen()),
  ],
);
