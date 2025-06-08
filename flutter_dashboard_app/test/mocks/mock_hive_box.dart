import 'package:hive/hive.dart';
import 'dart:async';

// A simple in-memory mock for Hive Box.
class MockHiveBox<E> implements Box<E> {
  final Map<dynamic, E> _store = {};

  @override
  E? get(dynamic key, {E? defaultValue}) {
    return _store[key] ?? defaultValue;
  }

  @override
  Future<void> put(dynamic key, E value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    _store.remove(key);
  }

  @override
  Map<dynamic, E> toMap() {
    return Map<dynamic, E>.from(_store);
  }

  @override
  Iterable<E> get values => _store.values;

  @override
  bool containsKey(dynamic key) {
    return _store.containsKey(key);
  }

  @override
  Future<int> clear() async { // Changed to Future<int> and return 0
    _store.clear();
    return 0;
  }

  @override
  bool get isOpen => true; // Assume always open for mock

  @override
  String get name => 'mockBox'; // Dummy name

  @override
  String? get path => null; // No path for in-memory mock

  @override
  Future<void> close() async {
    // No-op for mock
  }

  @override
  Future<int> add(E value) async {
    // Simple auto-incrementing int key for add, similar to Hive's behavior
    int key = _store.keys.whereType<int>().fold(0, (max, k) => k > max ? k : max) + 1;
    await put(key, value);
    return key;
  }

  @override
  Future<Iterable<int>> addAll(Iterable<E> values) async {
    List<int> keys = [];
    for (var value in values) {
      keys.add(await add(value));
    }
    return keys;
  }

  @override
  Future<void> deleteAll(Iterable<dynamic> keys) async {
    for (var key in keys) {
      await delete(key);
    }
  }

  @override
  E? getAt(int index) {
    if (index < 0 || index >= _store.length) return null;
    return _store.values.elementAt(index);
  }

  @override
  dynamic keyAt(int index) {
     if (index < 0 || index >= _store.length) return null;
    return _store.keys.elementAt(index);
  }

  @override
  Future<void> putAt(int index, E value) async {
    // This is tricky without ordered keys, using keyAt then put
    if (index < 0 || index >= _store.length) throw RangeError.index(index, this);
    final key = keyAt(index);
    await put(key, value);
  }

  @override
  Future<void> compact() async { /* no-op */ }

  @override
  bool get isEmpty => _store.isEmpty;

  @override
  bool get isNotEmpty => _store.isNotEmpty;

  @override
  int get length => _store.length;

  @override
  Iterable<dynamic> get keys => _store.keys;

  @override
  Stream<BoxEvent> watch({dynamic key}) {
    // Basic stream, can be enhanced if needed for specific tests
    // For most service tests, direct verification of box content is enough.
    // Using a real StreamController that we can add events to if needed for advanced tests.
    final controller = StreamController<BoxEvent>.broadcast();
    return controller.stream;
  }

  @override
  Future<void> flush() async { /* no-op */ }

  @override
  Future<void> deleteFromDisk() async {
    _store.clear();
  }

  @override
  bool get lazy => false; // Mock as non-lazy box

  // --- Missing methods to implement ---
  @override
  Future<void> deleteAt(int index) async {
    if (index < 0 || index >= _store.length) throw RangeError.index(index, this);
    final key = _store.keys.elementAt(index);
    await delete(key);
  }

  @override
  Future<void> putAll(Map<dynamic, E> entries) async {
    for (var entry in entries.entries) {
      await put(entry.key, entry.value);
    }
  }

  @override
  Iterable<E> valuesBetween({dynamic startKey, dynamic endKey}) {
    // This is a simplified mock. A full implementation would need sorted keys
    // and knowledge of their order if startKey/endKey are not just indices.
    // For many tests, this might not be strictly needed if not testing this exact method.
    // Returning all values as a fallback.
    print("Warning: MockHiveBox.valuesBetween is not fully implemented and returns all values.");
    return values;
  }
}
