import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/select_images_screen.dart';
import 'screens/process_screen.dart';
import 'screens/preview_screen.dart';
import 'screens/albums_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const ITRApp(),
    ),
  );
}

class ITRApp extends StatelessWidget {
  const ITRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TextEraser',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
      routes: {
        '/select': (context) => const SelectImagesScreen(),
        '/process': (context) => const ProcessScreen(),
        '/preview': (context) => const PreviewScreen(),
        '/albums': (context) => const AlbumsScreen(),
      },
    );
  }
}
