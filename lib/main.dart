// Import Flutter and Supabase packages
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import application screens
import 'screens/login_screen.dart';
import 'screens/map_screen.dart';

// Main function of the application
Future<void> main() async {
  // Ensure Flutter is initialized before running async code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase connection
  await Supabase.initialize(
    url: 'https://jclqunbdthbwhspoisrz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjbHF1bmJkdGhid2hzcG9pc3J6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0MDgxOTIsImV4cCI6MjA5MTk4NDE5Mn0.TceD7yQKHZsbNdnejlAx_HO_8ZpnXUdD4Z0uNYc7FkU',
  );

  // Run the application
  runApp(const AccessibleOmanApp());
}

// Main application class
class AccessibleOmanApp extends StatelessWidget {
  const AccessibleOmanApp({super.key});

  // Application colors
  static const Color primaryColor = Color(0xFF12372A);
  static const Color secondaryColor = Color(0xFF436850);
  static const Color backgroundColor = Color(0xFFF7F8F3);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Hide debug banner
      debugShowCheckedModeBanner: false,

      // Application title
      title: 'Accessible Oman Map',

      // Application theme settings
      theme: ThemeData(
        useMaterial3: true,

        // Background color of the app
        scaffoldBackgroundColor: backgroundColor,

        // Color scheme settings
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: secondaryColor,
          surface: Colors.white,
        ),

        // AppBar styling
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),

        // Card widget styling
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),

        // Input field styling
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          // Default border
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),

          // Enabled border
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),

          // Focused border
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
        ),

        // Elevated button styling
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // Floating action button styling
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),

      // Decide which screen to show based on login state
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {

          // Get current user session
          final session = Supabase.instance.client.auth.currentSession;

          // If user is not logged in → show LoginScreen
          // If user is logged in → show MapScreen
          return session == null ? const LoginScreen() : const MapScreen();
        },
      ),
    );
  }
}