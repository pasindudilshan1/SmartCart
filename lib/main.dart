import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'providers/inventory_provider.dart';
import 'providers/nutrition_provider.dart';
import 'services/azure_auth_service.dart';
import 'models/product.dart';
import 'models/nutrition.dart';
import 'models/sustainability.dart';
import 'models/household_member.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('📦 Initializing Hive...');
    // Initialize Hive
    await Hive.initFlutter();

    // Register Hive Adapters - check if already registered first
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ProductAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DailyNutritionAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(NutritionGoalsAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(SustainabilityMetricsAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(NutritionInfoAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(HouseholdMemberAdapter());
    }

    // Open Hive boxes
    await Hive.openBox('products');
    await Hive.openBox('settings');
    await Hive.openBox('nutrition');
    await Hive.openBox<HouseholdMember>('household_members');
    debugPrint('✅ Hive initialized successfully');
  } catch (e) {
    debugPrint('❌ Hive initialization error: $e');
  }

  debugPrint('🚀 Starting SmartCart app...');
  runApp(const SmartCartApp());
}

class SmartCartApp extends StatelessWidget {
  const SmartCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AzureAuthService()),
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
        // Start with login screen - auth flow will handle navigation
        home: const LoginScreen(),
      ),
    );
  }
}
