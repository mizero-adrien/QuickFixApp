import 'package:flutter/material.dart';
import 'package:quickfix/screens/artisan_detail_screen.dart';
import 'package:quickfix/screens/artisan_setup_screen.dart';
import 'package:quickfix/screens/booking_form_screen.dart';
import 'package:quickfix/screens/home_screen.dart';
import 'package:quickfix/screens/login_screen.dart';
import 'package:quickfix/screens/signup_screen.dart';
import 'package:quickfix/screens/splash_screen.dart';
import 'package:quickfix/theme/app_theme.dart';
import 'package:quickfix/screens/job_post_screen.dart';

void main() {
  runApp(const QuickFixApp());
}

class QuickFixApp extends StatelessWidget {
  const QuickFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickFix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,

      // Named routes — covers D1
      initialRoute: '/',
      routes: {
  '/': (context) => const SplashScreen(),
  '/login': (context) => const LoginScreen(),
  '/signup': (context) => const SignupScreen(),
  '/artisan-setup': (context) => const ArtisanSetupScreen(),
  '/home': (context) => const HomeScreen(),
  '/artisan-detail': (context) => const ArtisanDetailScreen(),
  '/booking-form': (context) => const BookingFormScreen(),
  '/post-job': (context) => const JobPostScreen(),
},
    );
  }
}