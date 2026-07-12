import 'package:flutter/material.dart';
import 'core/pocketbase/pb.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize PocketBase with local storage
  await initPocketBase();
  
  runApp(const TanganKananApp());
}

class TanganKananApp extends StatelessWidget {
  const TanganKananApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tangan Kanan',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
