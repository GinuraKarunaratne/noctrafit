import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

/// Firestore client - Centralized Firestore access
///
/// Features:
/// - Firestore instance management
/// - Collection references
/// - Error handling
/// - Logging
class FirestoreClient {
  final FirebaseFirestore _firestore;
  final Logger _logger;

  FirestoreClient({
    FirebaseFirestore? firestore,
    Logger? logger,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _logger = logger ?? Logger();

  /// Get catalog_sets collection reference
  /// App-provided workout sets (read-only for users)
  CollectionReference<Map<String, dynamic>> get catalogSets =>
      _firestore.collection('catalog_sets');

  /// Get community_sets collection reference
  /// User-created workout sets (read: all, write: own sets only)
  CollectionReference<Map<String, dynamic>> get communitySets =>
      _firestore.collection('community_sets');

  /// Get metadata collection reference
  /// App metadata (version info, etc.)
  CollectionReference<Map<String, dynamic>> get metadata =>
      _firestore.collection('metadata');

  /// Enable offline persistence
  Future<void> enablePersistence() async {
    try {
      await _firestore.settings.persistenceEnabled;
      _logger.i('Firestore offline persistence enabled');
    } catch (e) {
      _logger.w('Firestore offline persistence already enabled or not supported: $e');
    }
  }

  /// Disable network (for testing offline mode)
  Future<void> disableNetwork() async {
    try {
      await _firestore.disableNetwork();
      _logger.i('Firestore network disabled');
    } catch (e) {
      _logger.e('Failed to disable Firestore network: $e');
    }
  }

  /// Enable network
  Future<void> enableNetwork() async {
    try {
      await _firestore.enableNetwork();
      _logger.i('Firestore network enabled');
    } catch (e) {
      _logger.e('Failed to enable Firestore network: $e');
    }
  }

  /// Execute a Firestore operation with error handling
  Future<T> executeOperation<T>({
    required Future<T> Function() operation,
    required String operationName,
  }) async {
    try {
      _logger.d('Executing Firestore operation: $operationName');
      final result = await operation();
      _logger.d('Firestore operation completed: $operationName');
      return result;
    } on FirebaseException catch (e) {
      _logger.e('Firestore error in $operationName: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected error in $operationName: $e');
      rethrow;
    }
  }

  /// Batch write operation
  WriteBatch batch() => _firestore.batch();

  /// Transaction operation
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return executeOperation(
      operation: () => _firestore.runTransaction(
        transactionHandler,
        timeout: timeout,
      ),
      operationName: 'runTransaction',
    );
  }
}
