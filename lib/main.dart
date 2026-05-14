import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/select_images_screen.dart';
import 'screens/preview_select_screen.dart';
import 'screens/process_screen.dart';
import 'screens/preview_screen.dart';
import 'screens/albums_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Premium UI setup
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bgDeep,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const ITRApp()),
  );
}

class ITRApp extends StatelessWidget {
  const ITRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TextEraser Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/select': (context) => const SelectImagesScreen(),
        '/preview-select': (context) => const PreviewSelectScreen(),
        '/process': (context) => const ProcessScreen(),
        '/preview': (context) => const PreviewScreen(),
        '/albums': (context) => const AlbumsScreen(),
      },
    );
  }
}
