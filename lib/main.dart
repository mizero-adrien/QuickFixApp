import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quickfix/config/supabase_config.dart';
import 'package:quickfix/models/homeowner.dart';
import 'package:quickfix/services/supabase_service.dart';
import 'package:quickfix/l10n/app_localizations.dart';
import 'package:quickfix/screens/artisan_detail_screen.dart';
import 'package:quickfix/screens/artisan_setup_screen.dart';
import 'package:quickfix/screens/booking_form_screen.dart';
import 'package:quickfix/screens/home_screen.dart';
import 'package:quickfix/screens/login_screen.dart';
import 'package:quickfix/screens/signup_screen.dart';
import 'package:quickfix/screens/splash_screen.dart';
import 'package:quickfix/screens/password_recovery_screen.dart';
import 'package:quickfix/theme/app_theme.dart';
import 'package:quickfix/screens/job_post_screen.dart';
import 'package:quickfix/screens/artisan_edit_profile_screen.dart';
import 'package:quickfix/screens/homeowner_edit_profile_screen.dart';
import 'package:quickfix/screens/notifications_screen.dart';
import 'package:quickfix/screens/bids_management_screen.dart';
import 'package:quickfix/screens/job_status_screen.dart';
import 'package:quickfix/screens/job_detail_screen.dart';
import 'package:quickfix/screens/conversations_screen.dart';
import 'package:quickfix/screens/chat_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  // Restore session before first frame so screens see correct UserSession
  await SupabaseService.loadUserSession();
  debugPrint('[Main] Session restore complete. UserType: ${UserSession.userType}');

  // Listen for password-recovery deep link event on mobile
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      debugPrint('[Main] passwordRecovery event — navigating to /password-recovery');
      navigatorKey.currentState?.pushReplacementNamed('/password-recovery');
    }
  });

  runApp(const QuickFixApp());
}

class QuickFixApp extends StatelessWidget {
  const QuickFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleProvider.locale,
      builder: (_, locale, __) {
        final routes = {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/password-recovery': (context) => const PasswordRecoveryScreen(),
          '/artisan-setup': (context) => const ArtisanSetupScreen(),
          '/home': (context) => const HomeScreen(),
          '/artisan-detail': (context) => const ArtisanDetailScreen(),
          '/booking-form': (context) => const BookingFormScreen(),
          '/post-job': (context) => const JobPostScreen(),
          '/artisan-edit-profile': (context) => const ArtisanEditProfileScreen(),
          '/homeowner-edit-profile': (context) => const HomeownerEditProfileScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/bids-management': (context) => const BidsManagementScreen(),
        };

        return AppLocalizationsProvider(
          localizations: AppLocalizations(locale),
          child: MaterialApp(
            navigatorKey: navigatorKey,
            title: 'QuickFix',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            locale: _materialLocaleFor(locale),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('fr'), Locale('rw')],

            // Named routes — covers D1
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/password-recovery': (context) => const PasswordRecoveryScreen(),
              '/artisan-setup': (context) => const ArtisanSetupScreen(),
              '/home': (context) => const HomeScreen(),
              '/artisan-detail': (context) => const ArtisanDetailScreen(),
              '/booking-form': (context) => const BookingFormScreen(),
              '/post-job': (context) => const JobPostScreen(),
              '/artisan-edit-profile': (context) => const ArtisanEditProfileScreen(),
              '/homeowner-edit-profile': (context) => const HomeownerEditProfileScreen(),
              '/notifications': (context) => const NotificationsScreen(),
              '/bids-management': (context) => const BidsManagementScreen(),
              '/job-status': (context) => const JobStatusScreen(),
              '/job-detail': (context) => const JobDetailScreen(),
              '/chat': (context) => const ChatScreen(),
            },
          ),
        );
      },
    );
  }

  Locale _materialLocaleFor(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return const Locale('fr');
      case 'rw':
        return const Locale('en');
      default:
        return const Locale('en');
    }
  }

  String _resolveInitialRoute(Set<String> availableRoutes) {
    final uri = Uri.base;
    if (uri.fragment.isNotEmpty) {
      final routeSegment = uri.fragment.split('?').first;
      final routePath = routeSegment.startsWith('/') ? routeSegment : '/$routeSegment';
      if (availableRoutes.contains(routePath)) {
        return routePath;
      }
    }
    if (uri.path.isNotEmpty && availableRoutes.contains(uri.path)) {
      return uri.path;
    }
    return '/';
  }
}