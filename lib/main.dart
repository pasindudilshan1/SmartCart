import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'providers/inventory_provider.dart';
import 'providers/nutrition_provider.dart';
import 'services/auth_service.dart';
import 'models/product.dart';
import 'models/nutrition.dart';
import 'models/sustainability.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive Adapters
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(DailyNutritionAdapter());
  Hive.registerAdapter(NutritionGoalsAdapter());
  Hive.registerAdapter(SustainabilityMetricsAdapter());
  
  // Open Hive boxes
  await Hive.openBox('products');
  await Hive.openBox('settings');
  
  runApp(const SmartCartApp());
}

class SmartCartApp extends StatelessWidget {
  const SmartCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
      ],
      child: MaterialApp(
        title: 'SmartCart',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: FutureBuilder<bool>(
          future: _checkFirstLaunch(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            // Check authentication status
            final authService = Provider.of<AuthService>(context, listen: false);
            
            if (snapshot.data == true) {
              // First launch - show onboarding
              return const OnboardingScreen();
            } else if (authService.currentUser == null) {
              // Not authenticated - show login
              return const LoginScreen();
            } else {
              // Authenticated - show home
              return const HomeScreen();
            }
          },
        ),
      ),
    );
  }

  Future<bool> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;
    if (isFirstLaunch) {
      await prefs.setBool('first_launch', false);
    }
    return isFirstLaunch;
  }
}
