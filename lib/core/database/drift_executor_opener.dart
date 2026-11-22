import 'package:drift/drift.dart';

/// Opens a low-level Drift executor before stores issue raw SQL statements.
///
/// The application stores deliberately use [QueryExecutor] so they can remain
/// small and testable without generated database code. Drift still requires an
/// executor user to perform its one-time connection setup.
Future<void> ensureDriftExecutorOpen(QueryExecutor executor) {
  return executor.ensureOpen(const _StoreExecutorUser());
}

class _StoreExecutorUser implements QueryExecutorUser {
  const _StoreExecutorUser();

  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}
}
