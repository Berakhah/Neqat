// This is a stub file to provide mock implementations of dart:html for non-web platforms

class Window {
  // Mock localStorage implementation
  final Storage localStorage = Storage();
}

class Storage {
  final Map<String, String> _storage = {};

  String? operator [](String key) => _storage[key];

  void operator []=(String key, String value) {
    _storage[key] = value;
  }

  void remove(String key) {
    _storage.remove(key);
  }

  void clear() {
    _storage.clear();
  }
}

// Mock window object
final Window window = Window();