import 'package:drift/drift.dart';

import '../../../core/database/drift_executor_opener.dart';
import 'favorite.dart';

class FavoritesRepository {
  FavoritesRepository(this._executor);

  final QueryExecutor _executor;
  var _ready = false;

  static Future<FavoritesRepository> open(QueryExecutor executor) async {
    final repository = FavoritesRepository(executor);
    await repository.initialize();
    return repository;
  }

  Future<void> initialize() async {
    if (_ready) return;
    await ensureDriftExecutorOpen(_executor);
    await _executor.runCustom('''
      CREATE TABLE IF NOT EXISTS favorites (
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        item_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        PRIMARY KEY(user_id, type, item_id)
      )
    ''');
    _ready = true;
  }

  Future<List<Favorite>> list(int userId) async {
    await initialize();
    final rows = await _executor.runSelect(
      'SELECT type, item_id, title FROM favorites WHERE user_id = ? ORDER BY title',
      <Object?>[userId],
    );
    return rows
        .map(
          (row) => Favorite(
            type: row['type']! as String,
            itemId: row['item_id']! as int,
            title: row['title']! as String,
          ),
        )
        .toList();
  }

  Future<void> toggle(int userId, Favorite favorite) async {
    await initialize();
    final existing = await _executor.runSelect(
      'SELECT 1 FROM favorites WHERE user_id = ? AND type = ? AND item_id = ?',
      <Object?>[userId, favorite.type, favorite.itemId],
    );
    if (existing.isEmpty) {
      await _executor.runInsert(
        'INSERT INTO favorites(user_id, type, item_id, title) VALUES(?, ?, ?, ?)',
        <Object?>[userId, favorite.type, favorite.itemId, favorite.title],
      );
    } else {
      await _executor.runDelete(
        'DELETE FROM favorites WHERE user_id = ? AND type = ? AND item_id = ?',
        <Object?>[userId, favorite.type, favorite.itemId],
      );
    }
  }
}
