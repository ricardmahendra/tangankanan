import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Singleton instance of PocketBase
PocketBase? _pbInstance;

PocketBase get pb {
  final instance = _pbInstance;
  if (instance == null) {
    throw StateError('PocketBase belum diinisialisasi. Panggil initPocketBase() terlebih dahulu.');
  }
  return instance;
}

set pb(PocketBase value) {
  _pbInstance = value;
}

bool get isPocketBaseInitialized => _pbInstance != null;

// Initialize PocketBase AuthStore with SharedPreferences
// This ensures that the user remains logged in even after refreshing/restarting the app.
Future<void> initPocketBase() async {
  final prefs = await SharedPreferences.getInstance();

  final store = AsyncAuthStore(
    save: (String data) async => prefs.setString('pb_auth', data),
    initial: prefs.getString('pb_auth'),
  );

  pb = PocketBase('http://192.168.110.151:8090', authStore: store);
}
