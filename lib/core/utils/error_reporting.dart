import 'package:sentry_flutter/sentry_flutter.dart';

/// Subsystem tags used as the `area` tag on Sentry events so failures can be
/// filtered/grouped by where in the app they originate.
class ErrorArea {
  static const sync = 'sync';
  static const saleWrite = 'sale_write';
  static const tabWrite = 'tab_write';
  static const invoiceWrite = 'invoice_write';
  static const stockWrite = 'stock_write';
  static const dataParse = 'data_parse';
}

/// Reports a data error to Sentry with structured tags so it is searchable
/// across the fleet (e.g. filter by `area:sale_write` or `pg_code:23503`).
///
/// Use this for errors that would otherwise be swallowed (caught-and-ignored,
/// dead-lettered, or shown only as a transient SnackBar). Never throws — error
/// reporting must not be able to crash the app.
Future<void> reportDataError(
  Object error, {
  StackTrace? stackTrace,
  required String area,
  required String operation,
  SentryLevel level = SentryLevel.error,
  Map<String, String> tags = const {},
  Map<String, dynamic> data = const {},
}) async {
  try {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.level = level;
        scope.setTag('area', area);
        scope.setTag('operation', operation);
        tags.forEach(scope.setTag);
        if (data.isNotEmpty) {
          scope.setContexts('data_error', data);
        }
      },
    );
  } catch (_) {
    // Swallow: reporting failures must never propagate.
  }
}

/// Runs a data-write [action]; on failure reports it to Sentry with context and
/// rethrows, so existing UI error handling (SnackBars, etc.) still runs.
///
/// Wrap the critical local writes (sales, tabs, invoices, stock) so a failed or
/// partially-applied transaction is always visible to us, not just to the user.
Future<T> guardWrite<T>(
  String area,
  String operation,
  Future<T> Function() action, {
  Map<String, String> tags = const {},
  Map<String, dynamic> data = const {},
}) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    await reportDataError(
      error,
      stackTrace: stackTrace,
      area: area,
      operation: operation,
      tags: tags,
      data: data,
    );
    rethrow;
  }
}
