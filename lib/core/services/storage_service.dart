// File: lib/core/services/storage_service.dart
// Purpose: Local key-value storage wrapper using GetStorage.

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class StorageService extends GetxService {
  late final GetStorage _box;

  /// Initializes the storage container. Must be called before calling write/read.
  Future<StorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  /// Writes a value to storage with the specified key.
  Future<void> write(String key, dynamic value) async {
    await _box.write(key, value);
  }

  /// Reads a value from storage for the specified key. Returns null if not found.
  T? read<T>(String key) {
    return _box.read<T>(key);
  }

  /// Removes a value associated with the specified key.
  Future<void> remove(String key) async {
    await _box.remove(key);
  }

  /// Erases all stored keys.
  Future<void> clearAll() async {
    await _box.erase();
  }

  /// Checks if a key exists in storage.
  bool hasKey(String key) {
    return _box.hasData(key);
  }
}
