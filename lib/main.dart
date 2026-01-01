import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:sendit/providers/AddressProvider.dart';
import 'package:sendit/providers/favourite.dart';
import 'package:sendit/themes.dart';
import 'Main_Navigation.dart';
import 'firebase_options.dart';
import 'auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SendItApp());
}

class SendItApp extends StatelessWidget {
  const SendItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        // Register AddressProvider
        ChangeNotifierProvider(create: (_) => AddressProvider()..init()),
      ],
      child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return MaterialApp(
              title: 'Send It',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              home: auth.isAuthenticated ? const MainWrapper() : const LoginScreen(),
              routes: {
                '/main': (context) => const MainWrapper(),
                '/login': (context) => const LoginScreen(),
              },
            );
          }
      ),
    );
  }
}