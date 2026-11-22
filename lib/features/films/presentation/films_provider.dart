import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/films_repository.dart';

final filmsRepositoryProvider = Provider<FilmsRepository>((ref) {
  throw UnimplementedError('FilmsRepository must be provided at app startup.');
});

final filmsProvider = FutureProvider<FilmsResult>((ref) {
  return ref.watch(filmsRepositoryProvider).list();
});
