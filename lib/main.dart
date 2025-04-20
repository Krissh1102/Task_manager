// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task/app/theme_provider.dart';
import 'app/theme.dart';
import 'auth/auth_service.dart';
import 'auth/login_screen.dart';
import 'dashboard/dashboard_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zadddjomqursodzebioz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InphZGRkam9tcXVyc29kemViaW96Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUxMjUyMjUsImV4cCI6MjA2MDcwMTIyNX0.uJCTc0KHsT5mL_-tkb3r6-qJnczS5jdmzpueZdVFha0',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()), 
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'TaskHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light, 
      home: Consumer<AuthService>(
        builder: (context, authService, _) {
          if (authService.isAuthenticated) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
