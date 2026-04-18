import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/app_routes.dart';
import 'providers/auth_provider.dart';
import 'providers/conversation_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/account_screen.dart';
import 'screens/conversation_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/backend_api_service.dart';
import 'services/local_storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase can be unavailable in local development until platform setup is complete.
  }

  final storageService = LocalStorageService();
  final authService = AuthService();

  runApp(
    FluentFlowApp(
      storageService: storageService,
      authService: authService,
    ),
  );
}

class FluentFlowApp extends StatelessWidget {
  const FluentFlowApp({
    this.storageService,
    this.authService,
    super.key,
  });

  final LocalStorageService? storageService;
  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final resolvedStorage = storageService ?? LocalStorageService();
    final resolvedAuth = authService ?? AuthService();
    final backendApi = BackendApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            authService: resolvedAuth,
            storageService: resolvedStorage,
          )..initialize(),
        ),
        ChangeNotifierProvider<ConversationProvider>(
          create: (_) => ConversationProvider(
            storageService: resolvedStorage,
            apiService: backendApi,
          ),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(storageService: resolvedStorage)
            ..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'FluentFlow AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: (settings) {
          final page = _resolveRoute(settings.name);
          return PageRouteBuilder<void>(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) => page,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              final fade = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.03),
                    end: Offset.zero,
                  ).animate(fade),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 260),
          );
        },
      ),
    );
  }

  Widget _resolveRoute(String? name) {
    switch (name) {
      case AppRoutes.splash:
        return const SplashScreen();
      case AppRoutes.onboarding:
        return const OnboardingScreen();
      case AppRoutes.welcome:
        return const WelcomeScreen();
      case AppRoutes.login:
        return const LoginScreen();
      case AppRoutes.signup:
        return const SignupScreen();
      case AppRoutes.home:
        return const HomeScreen();
      case AppRoutes.conversation:
        return const ConversationScreen();
      case AppRoutes.progress:
        return const ProgressScreen();
      case AppRoutes.settings:
        return const SettingsScreen();
      case AppRoutes.account:
        return const AccountScreen();
      default:
        return const SplashScreen();
    }
  }
}
