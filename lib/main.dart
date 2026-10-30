import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'constants/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/study_tools_provider.dart';
import 'services/supabase_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations & system UI overlay style
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: EduTheme.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Supabase client
  await SupabaseService().initialize();

  runApp(const EduSyncApp());
}

class EduSyncApp extends StatelessWidget {
  const EduSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => StudyToolsProvider()),
      ],
      child: MaterialApp(
        title: 'EduSync',
        debugShowCheckedModeBanner: false,
        theme: EduTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
