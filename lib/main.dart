import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nairaflow_new/theme.dart';
import 'package:nairaflow_new/utils/router.dart';
import 'package:nairaflow_new/services/api_service.dart';
import 'package:nairaflow_new/services/paystack_service.dart';
import 'package:nairaflow_new/services/notification_service.dart';
import 'package:nairaflow_new/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (optional for Google sign-in)
  try {
    await Firebase.initializeApp();
    // Initialize Push Notifications
    await NotificationService.initialize();
  } catch (e) {
    // Firebase initialization failed, continue without it
    print('Firebase initialization failed: $e');
  }
  
  // Initialize API service
  ApiService.initialize();
  
  // Initialize Paystack
  await PaystackService.initialize();
  
  runApp(const ProviderScope(child: MyApp()));
}



class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    return MaterialApp.router(
      title: 'NairaPay',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
