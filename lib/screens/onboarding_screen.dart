// Copilot Task 8: App Polish - Onboarding Screen
// Introduction screen for first-time users

import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: 'Welcome to SmartCart! 🛒',
          body:
              'Reduce household food waste by making smarter grocery decisions aligned with your nutritional needs.',
          image: _buildImage(Icons.shopping_cart, Colors.green),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: 'Scan & Track 📱',
          body:
              'Use QR code scanning to quickly add products and track their expiry dates, nutrition info, and storage tips.',
          image: _buildImage(Icons.qr_code_scanner, Colors.blue),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: 'Monitor Nutrition 🍎',
          body:
              'Track your daily nutritional intake and ensure your purchases match your health goals.',
          image: _buildImage(Icons.favorite, Colors.red),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: 'Reduce Waste 🌱',
          body:
              'Get alerts for expiring items, avoid over-purchasing, and see your sustainability impact!',
          image: _buildImage(Icons.eco, Colors.teal),
          decoration: _getPageDecoration(),
        ),
      ],
      onDone: () => _goToLogin(context),
      onSkip: () => _goToLogin(context),
      showSkipButton: true,
      skip: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: DotsDecorator(
        size: const Size.square(10.0),
        activeSize: const Size(20.0, 10.0),
        activeColor: Theme.of(context).colorScheme.primary,
        color: Colors.grey,
        spacing: const EdgeInsets.symmetric(horizontal: 3.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
        ),
      ),
    );
  }

  Widget _buildImage(IconData icon, Color color) {
    return Center(
      child: Icon(
        icon,
        size: 150.0,
        color: color,
      ),
    );
  }

  PageDecoration _getPageDecoration() {
    return const PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
      bodyTextStyle: TextStyle(fontSize: 18.0),
      bodyPadding: EdgeInsets.all(16.0),
      imagePadding: EdgeInsets.all(24.0),
    );
  }

  void _goToLogin(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}
