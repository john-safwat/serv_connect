import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:serv_connect_mobile/core/storage/secure_storage.dart';
import 'package:serv_connect_mobile/core/storage/storage_keys.dart';

/// Encrypted local document store (`CLAUDE.md §7 & §12.1`).
///
/// Every Hive box is opened exclusively through [HiveStorage] using
/// [HiveAesCipher] with a 256-bit key stored in [SecureStorage]. Documents are
/// stored as JSON maps (`Map<String, dynamic>`) keyed by entity UUID.
@singleton
class HiveStorage {
  HiveStorage(this._secureStorage);

  final SecureStorage _secureStorage;
  HiveAesCipher? _cipher;
  bool _initialised = false;

  static const String servedMembersBox = 'served_members';
  static const String sensitiveRecordsBox = 'sensitive_records';
  static const String outboxMutationsBox = 'outbox_mutations';
  static const String orgConfigBox = 'org_config';

  bool get isInitialised => _initialised;

  /// Initializes Hive and loads or generates the 256-bit AES cipher key.
  Future<void> init({String? subDir}) async {
    if (_initialised) return;
    if (subDir != null) {
      Hive.init(subDir);
    } else {
      await Hive.initFlutter();
    }
    final keyBytes = await _loadOrCreateCipherKey();
    _cipher = HiveAesCipher(keyBytes);
    await _openCoreBoxes();
    _initialised = true;
  }

  Future<Box<Map<dynamic, dynamic>>> openDocumentBox(String name) async {
    final cipher = _cipher;
    if (cipher == null) {
      throw StateError(
        'HiveStorage.init() must be called before opening $name',
      );
    }
    if (Hive.isBoxOpen(name)) {
      return Hive.box<Map<dynamic, dynamic>>(name);
    }
    return Hive.openBox<Map<dynamic, dynamic>>(name, encryptionCipher: cipher);
  }

  Future<Map<String, dynamic>?> getDoc(String boxName, String id) async {
    final box = await openDocumentBox(boxName);
    final raw = box.get(id);
    if (raw == null) return null;
    return Map<String, dynamic>.from(raw);
  }

  Future<void> putDoc(
    String boxName,
    String id,
    Map<String, dynamic> doc,
  ) async {
    final box = await openDocumentBox(boxName);
    await box.put(id, doc);
  }

  Future<void> deleteDoc(String boxName, String id) async {
    final box = await openDocumentBox(boxName);
    await box.delete(id);
  }

  /// Immediately purges the isolated `sensitive_records` box (`FR-13.3`).
  Future<void> clearSensitiveRecords() async {
    if (!_initialised) return;
    final box = await openDocumentBox(sensitiveRecordsBox);
    await box.clear();
  }

  /// Wipes cached user-scoped domain boxes while preserving `outbox_mutations`
  /// (`CLAUDE.md §12.2`).
  Future<void> clearUserScopePreservingOutbox() async {
    if (!_initialised) return;
    await clearSensitiveRecords();
    final members = await openDocumentBox(servedMembersBox);
    await members.clear();
  }

  Future<Uint8List> _loadOrCreateCipherKey() async {
    final existing = await _secureStorage.read(StorageKey.hiveEncryptionKey);
    if (existing != null && existing.isNotEmpty) {
      return base64Url.decode(existing);
    }
    final generated = Hive.generateSecureKey();
    await _secureStorage.write(
      StorageKey.hiveEncryptionKey,
      base64UrlEncode(generated),
    );
    return Uint8List.fromList(generated);
  }

  Future<void> _openCoreBoxes() async {
    await openDocumentBox(servedMembersBox);
    await openDocumentBox(sensitiveRecordsBox);
    await openDocumentBox(outboxMutationsBox);
    await openDocumentBox(orgConfigBox);
  }
}
