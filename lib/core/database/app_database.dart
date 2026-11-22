import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'drift_executor_opener.dart';

/// Single SQLite connection shared by the API cache, accounts and favorites.
///
/// All stores create their own tables (idempotently) but use this executor so
/// SQLite does not have to manage several writers on the same file.
class AppDatabase {
  AppDatabase._(this.executor);

  final QueryExecutor executor;

  static Future<AppDatabase> open() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}swapo.sqlite',
    );
    final executor = NativeDatabase(file);
    await ensureDriftExecutorOpen(executor);
    return AppDatabase._(executor);
  }

  Future<void> close() => executor.close();
}
