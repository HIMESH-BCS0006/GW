import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class TokenStorage {
  static const _tokenKey = 'waypoint_access_token';
  static const _deviceIdKey = 'waypoint_device_id';
  static const _clientSeqKey = 'waypoint_client_seq';
  static const _activeDepotKey = 'waypoint_active_depot';
  static const _mockExampleKey = 'waypoint_mock_example';

  final FlutterSecureStorage _storage;
  final Map<String, String> _inMemoryFallback = {};

  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    _inMemoryFallback[_tokenKey] = token;
    try {
      await _storage.write(key: _tokenKey, value: token).timeout(const Duration(milliseconds: 100));
    } catch (_) {}
  }

  Future<String?> getToken() async {
    try {
      final val = await _storage.read(key: _tokenKey).timeout(const Duration(milliseconds: 100));
      return val ?? _inMemoryFallback[_tokenKey];
    } catch (_) {
      return _inMemoryFallback[_tokenKey];
    }
  }

  Future<void> saveMockExample(String example) async {
    _inMemoryFallback[_mockExampleKey] = example;
    try {
      await _storage.write(key: _mockExampleKey, value: example);
    } catch (_) {}
  }

  Future<String?> getMockExample() async {
    try {
      return await _storage.read(key: _mockExampleKey) ?? _inMemoryFallback[_mockExampleKey];
    } catch (_) {
      return _inMemoryFallback[_mockExampleKey];
    }
  }

  Future<void> clearToken() async {
    _inMemoryFallback.remove(_tokenKey);
    _inMemoryFallback.remove(_mockExampleKey);
    try {
      await _storage.delete(key: _mockExampleKey);
    } catch (_) {}
    try {
      await _storage.delete(key: _tokenKey).timeout(const Duration(milliseconds: 100));
    } catch (_) {}
  }

  /// Get or create unique persistent device_id
  Future<String> getDeviceId() async {
    try {
      String? deviceId = await _storage.read(key: _deviceIdKey) ?? _inMemoryFallback[_deviceIdKey];
      if (deviceId == null || deviceId.isEmpty) {
        deviceId = 'DEV-${const Uuid().v4().substring(0, 8).toUpperCase()}';
        _inMemoryFallback[_deviceIdKey] = deviceId;
        await _storage.write(key: _deviceIdKey, value: deviceId);
      }
      return deviceId;
    } catch (_) {
      return _inMemoryFallback[_deviceIdKey] ??= 'DEV-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    }
  }

  /// Get next monotonic client_seq for device
  Future<int> getNextClientSeq() async {
    try {
      final currentStr = await _storage.read(key: _clientSeqKey) ?? _inMemoryFallback[_clientSeqKey];
      final current = int.tryParse(currentStr ?? '0') ?? 0;
      final next = current + 1;
      _inMemoryFallback[_clientSeqKey] = next.toString();
      await _storage.write(key: _clientSeqKey, value: next.toString());
      return next;
    } catch (_) {
      final current = int.tryParse(_inMemoryFallback[_clientSeqKey] ?? '0') ?? 0;
      final next = current + 1;
      _inMemoryFallback[_clientSeqKey] = next.toString();
      return next;
    }
  }

  Future<int> getCurrentClientSeq() async {
    try {
      final currentStr = await _storage.read(key: _clientSeqKey) ?? _inMemoryFallback[_clientSeqKey];
      return int.tryParse(currentStr ?? '0') ?? 0;
    } catch (_) {
      return int.tryParse(_inMemoryFallback[_clientSeqKey] ?? '0') ?? 0;
    }
  }

  Future<void> saveActiveDepot(String depotId) async {
    _inMemoryFallback[_activeDepotKey] = depotId;
    try {
      await _storage.write(key: _activeDepotKey, value: depotId);
    } catch (_) {}
  }

  Future<String?> getActiveDepot() async {
    try {
      return await _storage.read(key: _activeDepotKey) ?? _inMemoryFallback[_activeDepotKey];
    } catch (_) {
      return _inMemoryFallback[_activeDepotKey];
    }
  }

  Future<void> clearAll() async {
    _inMemoryFallback.clear();
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
