import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nairaflow_new/theme.dart';
import 'package:nairaflow_new/utils/router.dart';
import 'package:nairaflow_new/services/api_service.dart';
import 'package:nairaflow_new/services/paystack_service.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    print("Attempting to initialize Firebase...");
    await Firebase.initializeApp();
    print("Firebase initialized successfully.");
    
    print("Attempting to initialize ApiService...");
    ApiService.initialize();
    print("ApiService initialized successfully.");

    print("Attempting to initialize PaystackService...");
    await PaystackService.initialize();
    print("PaystackService initialized successfully.");
    
    runApp(const ProviderScope(child: MyApp()));
  } catch (e, stackTrace) {
    print("FATAL ERROR: App failed to start.");
    print("ERROR: $e");
    print("STACK TRACE: $stackTrace");
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'NairaPay',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
