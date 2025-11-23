import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _cartController;
  late AnimationController _textController;
  late Animation<double> _cartAnimation;
  late Animation<double> _textOpacity1;
  late Animation<double> _textOpacity2;
  late Animation<double> _textOpacity3;

  @override
  void initState() {
    super.initState();

    // Cart movement animation (moves completely across screen)
    _cartController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _cartAnimation = Tween<double>(
      begin: -1.5, // Start completely off-screen left
      end: 1.5, // End completely off-screen right
    ).animate(CurvedAnimation(
      parent: _cartController,
      curve: Curves.easeInOutCubic,
    ));

    // Text animation controller for word-by-word appearance
    _textController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // "Smart" appears when cart passes through left-center area
    _textOpacity1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.35, 0.50, curve: Curves.easeOut),
      ),
    );

    // "Cart" appears when cart passes through right-center area
    _textOpacity2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.55, 0.70, curve: Curves.easeOut),
      ),
    );

    // Tagline appears after cart exits
    _textOpacity3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.75, 0.90, curve: Curves.easeIn),
      ),
    );

    // Start animations
    _cartController.forward();
    _textController.forward();

    // Navigate to next screen after animation completes
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _cartController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Animated text appearing word by word behind the cart
            Center(
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Smart" word appears first
                      AnimatedOpacity(
                        opacity: _textOpacity1.value,
                        duration: const Duration(milliseconds: 200),
                        child: Transform.scale(
                          scale: 0.5 + (_textOpacity1.value * 0.5),
                          child: Text(
                            'Smart',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),

                      // "Cart" word appears second AFTER "Smart"
                      AnimatedOpacity(
                        opacity: _textOpacity2.value,
                        duration: const Duration(milliseconds: 200),
                        child: Transform.scale(
                          scale: 0.5 + (_textOpacity2.value * 0.5),
                          child: Text(
                            'Cart',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Animated cart moving from left to right across screen
            AnimatedBuilder(
              animation: _cartAnimation,
              builder: (context, child) {
                // Hide cart after it passes (when animation > 0.75)
                final cartOpacity = _cartAnimation.value > 0.4
                    ? (1.0 - ((_cartAnimation.value - 0.4) / 0.6)).clamp(0.0, 1.0)
                    : 1.0;

                return Opacity(
                  opacity: cartOpacity,
                  child: Align(
                    alignment: Alignment(_cartAnimation.value, 0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_cart,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Tagline at bottom
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return AnimatedOpacity(
                    opacity: _textOpacity3.value,
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      'Reduce food waste, one scan at a time',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
