import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ai_stock_analyzer/presentation/widgets/ilm_logo.dart';
import 'package:ai_stock_analyzer/theme/app_theme.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with TickerProviderStateMixin {
  // Initial fade-in
  late final AnimationController _entryController;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  // Rotating text
  late AnimationController _rotateController;
  late Animation<double> _fadeOut;
  late Animation<Offset> _slideOut;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  Timer? _timer;
  int _currentIndex = 0;
  int _nextIndex = 1;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _entryFade = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _setupRotateAnimations();

    _entryController.forward().then((_) {
      _startRotationTimer();
    });
  }

  void _setupRotateAnimations() {
    // First half: old text fades out + slides up
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _rotateController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );
    _slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.5),
    ).animate(
      CurvedAnimation(
        parent: _rotateController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeIn),
      ),
    );

    // Second half: new text fades in + slides up from below
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rotateController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _rotateController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  void _startRotationTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _rotateToNext();
    });
  }

  void _rotateToNext() {
    if (_isTransitioning) return;

    final items = AppThemeScope.of(context).strings.heroRotatingItems;
    if (items.length <= 1) return;

    _isTransitioning = true;
    _nextIndex = (_currentIndex + 1) % items.length;

    _rotateController.forward(from: 0).then((_) {
      setState(() {
        _currentIndex = _nextIndex;
        _isTransitioning = false;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entryController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppThemeScope.of(context);
    final c = t.colors;
    final s = t.strings;
    final items = s.heroRotatingItems;
    final isWide = MediaQuery.of(context).size.width > 960;
    final fontSize = isWide ? 48.0 : 32.0;

    final titleStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      color: c.textPrimary,
      height: 1.1,
      letterSpacing: -1,
    );

    final logoSize = isWide ? 90.0 : 64.0;

    return SizedBox(
      width: double.infinity,
      height: isWide ? 320 : 270,
      child: Center(
        child: FadeTransition(
          opacity: _entryFade,
          child: SlideTransition(
            position: _entrySlide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IlmLogo(size: logoSize),
                  SizedBox(height: isWide ? 20 : 14),
                  // Rotating title area
                  SizedBox(
                    height: fontSize * 2.2 + 4,
                    child: AnimatedBuilder(
                      animation: _rotateController,
                      builder: (context, _) {
                        final current = items[_currentIndex];
                        final next = items[_nextIndex % items.length];

                        if (!_isTransitioning) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(current.line1, textAlign: TextAlign.center, style: titleStyle),
                              Text(current.line2, textAlign: TextAlign.center, style: titleStyle),
                            ],
                          );
                        }

                        return ClipRect(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Old text sliding out
                              FractionalTranslation(
                                translation: _slideOut.value,
                                child: Opacity(
                                  opacity: _fadeOut.value,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(current.line1, textAlign: TextAlign.center, style: titleStyle),
                                      Text(current.line2, textAlign: TextAlign.center, style: titleStyle),
                                    ],
                                  ),
                                ),
                              ),
                              // New text sliding in
                              FractionalTranslation(
                                translation: _slideIn.value,
                                child: Opacity(
                                  opacity: _fadeIn.value,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(next.line1, textAlign: TextAlign.center, style: titleStyle),
                                      Text(next.line2, textAlign: TextAlign.center, style: titleStyle),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.heroSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isWide ? 17 : 14,
                      color: c.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
