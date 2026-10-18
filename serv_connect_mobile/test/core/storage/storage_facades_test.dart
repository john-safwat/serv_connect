import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:serv_connect_mobile/core/storage/hive_storage.dart';
import 'package:serv_connect_mobile/core/storage/preferences.dart';
import 'package:serv_connect_mobile/core/storage/secure_storage.dart';
import 'package:serv_connect_mobile/core/storage/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('SecureStorage & Preferences key isolation', () {
    test('secureStorage_nonSensitiveKey_throwsArgumentError', () async {
      final backing = _MockFlutterSecureStorage();
      final secure = SecureStorage.test(backing);
      expect(() => secure.read(StorageKey.appLanguage), throwsArgumentError);
    });

    test('preferences_sensitiveKey_throwsArgumentError', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final rawPrefs = await SharedPreferences.getInstance();
      final prefs = Preferences(rawPrefs);

      expect(
        () => prefs.getString(StorageKey.accessToken),
        throwsArgumentError,
      );
      await prefs.setString(StorageKey.appLanguage, 'ar');
      expect(prefs.getString(StorageKey.appLanguage), 'ar');
      await prefs.setInt(StorageKey.lastChangeSeq, 42);
      expect(prefs.getInt(StorageKey.lastChangeSeq), 42);
      await prefs.setBool(StorageKey.wifiOnlyMediaDownload, value: true);
      expect(prefs.getBool(StorageKey.wifiOnlyMediaDownload), isTrue);
      await prefs.remove(StorageKey.appLanguage);
      expect(prefs.getString(StorageKey.appLanguage), isNull);
    });
  });

  group('HiveStorage AES-256 encrypted boxes', () {
    late Directory tempDir;
    late _MockFlutterSecureStorage backing;
    late SecureStorage secureStorage;
    late HiveStorage hiveStorage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      backing = _MockFlutterSecureStorage();
      String? storedKey;
      when(
        () => backing.read(key: StorageKey.hiveEncryptionKey.value),
      ).thenAnswer((_) async => storedKey);
      when(
        () => backing.write(
          key: StorageKey.hiveEncryptionKey.value,
          value: any(named: 'value'),
        ),
      ).thenAnswer((invocation) async {
        storedKey = invocation.namedArguments[#value] as String?;
      });
      secureStorage = SecureStorage.test(backing);
      hiveStorage = HiveStorage(secureStorage);
      await hiveStorage.init(subDir: tempDir.path);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('putGetAndPurgeSensitivePreservingOutbox_succeeds', () async {
      await hiveStorage.putDoc(
        HiveStorage.servedMembersBox,
        'member-1',
        <String, dynamic>{'id': 'member-1', 'displayName': 'Synthetic One'},
      );
      await hiveStorage.putDoc(
        HiveStorage.sensitiveRecordsBox,
        'note-1',
        <String, dynamic>{'id': 'note-1'},
      );
      await hiveStorage.putDoc(
        HiveStorage.outboxMutationsBox,
        'mut-1',
        <String, dynamic>{'mutationId': 'mut-1'},
      );

      expect(
        (await hiveStorage.getDoc(
          HiveStorage.servedMembersBox,
          'member-1',
        ))?['id'],
        'member-1',
      );

      await hiveStorage.clearUserScopePreservingOutbox();

      expect(
        await hiveStorage.getDoc(HiveStorage.servedMembersBox, 'member-1'),
        isNull,
      );
      expect(
        await hiveStorage.getDoc(HiveStorage.sensitiveRecordsBox, 'note-1'),
        isNull,
      );
      expect(
        await hiveStorage.getDoc(HiveStorage.outboxMutationsBox, 'mut-1'),
        isNotNull,
      );
    });
  });
}
