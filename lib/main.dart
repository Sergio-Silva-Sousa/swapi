import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import 'core/api/api_client.dart';
import 'core/cache/api_cache_database.dart';
import 'core/network/assumed_online_network_status.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'features/auth/presentation/profile_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/films/data/films_repository.dart';
import 'features/films/presentation/films_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authRepository = await LocalAuthRepository.open();
  final cache = await ApiCacheDatabase.open();
  final apiClient = ApiClient(
    dio: Dio(),
    cache: cache,
    networkStatus: const AssumedOnlineNetworkStatus(),
  );
  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        filmsRepositoryProvider.overrideWithValue(FilmsRepository(apiClient)),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xfff7c948)),
        useMaterial3: true,
      ),
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
