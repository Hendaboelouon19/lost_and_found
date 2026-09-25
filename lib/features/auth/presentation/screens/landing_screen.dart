import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:errasoft/features/auth/login/presentation/screens/login_screen.dart';
import 'package:errasoft/features/auth/register/presentation/screens/register_screen.dart';
import 'package:errasoft/themes/app_theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  Timer? _slideTimer;
  int _currentPage = 0;

  static const _slides = [
    _LandingSlide(
      word: 'Return',
      eyebrow: 'A better way back',
      description: 'Turn lost moments into clear, trusted connections.',
      background: AppTheme.coolHorizon,
      foreground: AppTheme.nightBordeaux,
      product: _ProductType.earbuds,
      accents: [
        _ProductType.keys,
        _ProductType.card,
        _ProductType.phone,
        _ProductType.bag,
      ],
    ),
    _LandingSlide(
      word: 'Recognize',
      eyebrow: 'Details matter',
      description: 'Share the details that help the right person find you.',
      background: AppTheme.ivoryMist,
      foreground: AppTheme.nightBordeaux,
      product: _ProductType.phone,
      accents: [
        _ProductType.wallet,
        _ProductType.keys,
        _ProductType.earbuds,
        _ProductType.bag,
      ],
    ),
    _LandingSlide(
      word: 'Reconnect',
      eyebrow: 'Made for real people',
      description: 'A calm, considered home for lost and found items.',
      background: AppTheme.nightBordeaux,
      foreground: AppTheme.ivoryMist,
      product: _ProductType.bag,
      accents: [
        _ProductType.card,
        _ProductType.phone,
        _ProductType.keys,
        _ProductType.earbuds,
      ],
    ),
    _LandingSlide(
      word: 'Restore',
      eyebrow: 'Nothing stays lost',
      description: 'Give important things a clearer way home.',
      background: AppTheme.coolHorizon,
      foreground: AppTheme.nightBordeaux,
      product: _ProductType.wallet,
      accents: [
        _ProductType.earbuds,
        _ProductType.bag,
        _ProductType.card,
        _ProductType.phone,
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => _currentPage = (_currentPage + 1) % _slides.length);
    });
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    super.dispose();
  }

  void _changeSlide(int page) {
    if (page == _currentPage) return;
    setState(() => _currentPage = page);
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity < -120) {
            _changeSlide((_currentPage + 1) % _slides.length);
          } else if (velocity > 120) {
            _changeSlide((_currentPage - 1 + _slides.length) % _slides.length);
          }
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: _LandingSlideView(
            key: ValueKey(_currentPage),
            slide: _slides[_currentPage],
            currentPage: _currentPage,
            onSignIn: () => _open(const LoginScreen()),
            onGetStarted: () => _open(const RegisterScreen()),
          ),
        ),
      ),
    );
  }
}

class _LandingSlideView extends StatelessWidget {
  const _LandingSlideView({
    super.key,
    required this.slide,
    required this.currentPage,
    required this.onSignIn,
    required this.onGetStarted,
  });

  final _LandingSlide slide;
  final int currentPage;
  final VoidCallback onSignIn;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 650;
    final contentColor = slide.foreground;
    final mutedColor = contentColor.withValues(alpha: .68);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      color: slide.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(isCompact ? 20 : 42, 22, isCompact ? 20 : 42, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'returna',
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .2,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onSignIn,
                    style: TextButton.styleFrom(foregroundColor: contentColor),
                    child: const Text('Sign in'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onGetStarted,
                    style: FilledButton.styleFrom(
                      backgroundColor: contentColor,
                      foregroundColor: slide.background,
                    ),
                    child: const Text('Join Returna'),
                  ),
                ],
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              slide.word,
                              style: TextStyle(
                                color: contentColor.withValues(alpha: .34),
                                fontSize: isCompact ? 116 : 200,
                                fontWeight: FontWeight.w900,
                                height: .9,
                                shadows: [
                                  Shadow(
                                    color: slide.background.withValues(alpha: .18),
                                    blurRadius: 2,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: _FloatingProducts(
                        color: contentColor,
                        products: slide.accents,
                      ),
                    ),
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final rotation = Tween<double>(
                            begin: -.08,
                            end: 0,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          );
                          return RotationTransition(
                            turns: rotation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: _AnimatedProductAsset(
                          key: ValueKey('${slide.word}-$currentPage'),
                          type: slide.product,
                          size: slide.product == _ProductType.wallet
                              ? (isCompact ? 220 : 340)
                              : (isCompact ? 280 : 420),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      Text(
                        slide.eyebrow.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        slide.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: contentColor,
                          fontSize: isCompact ? 16 : 18,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: onGetStarted,
                        style: TextButton.styleFrom(foregroundColor: contentColor),
                        child: const Text('Start returning items'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _SlideDots(
                count: _LandingScreenState._slides.length,
                activeIndex: currentPage,
                color: contentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingProducts extends StatelessWidget {
  const _FloatingProducts({required this.color, required this.products});

  final Color color;
  final List<_ProductType> products;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 52,
          left: 18,
          child: Transform.rotate(
            angle: -.28,
            child: _ProductAsset(type: products[0], size: 78),
          ),
        ),
        Positioned(
          top: 36,
          right: 12,
          child: Transform.rotate(
            angle: .34,
            child: _ProductAsset(type: products[1], size: 82),
          ),
        ),
        Positioned(
          bottom: 14,
          left: 8,
          child: Transform.rotate(
            angle: .22,
            child: _ProductAsset(type: products[2], size: 72),
          ),
        ),
        Positioned(
          bottom: 24,
          right: 28,
          child: Transform.rotate(
            angle: -.2,
            child: _ProductAsset(type: products[3], size: 72),
          ),
        ),
      ],
    );
  }
}

enum _ProductType { earbuds, phone, keys, bag, wallet, card }

class _AnimatedProductAsset extends StatefulWidget {
  const _AnimatedProductAsset({
    super.key,
    required this.type,
    required this.size,
  });

  final _ProductType type;
  final double size;

  @override
  State<_AnimatedProductAsset> createState() => _AnimatedProductAssetState();
}

class _AnimatedProductAssetState extends State<_AnimatedProductAsset>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 780),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: _ProductAsset(type: widget.type, size: widget.size),
      builder: (context, child) {
        final wave = Curves.easeOutCubic.transform(_controller.value);
        final tilt = (1 - wave) * -.48;
        final lift = (1 - wave) * 26;
        final depth = .78 + (wave * .22);
        final opacity = .45 + (wave * .55);
        final blurSigma = (1 - wave) * 2.4;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, .003)
          ..rotateX(tilt * .32)
          ..rotateY(tilt)
          ..scaleByDouble(depth, depth, depth, 1.0)
          ..translateByDouble(0.0, lift, 0.0, 1.0);

        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            child: Opacity(opacity: opacity, child: child),
          ),
        );
      },
    );
  }
}

class _ProductAsset extends StatelessWidget {
  const _ProductAsset({
    required this.type,
    required this.size,
  });

  final _ProductType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath = switch (type) {
      _ProductType.earbuds => 'assets/products/earbuds.png',
      _ProductType.phone => 'assets/products/mobilephone.png',
      _ProductType.keys => 'assets/products/keys.png',
      _ProductType.bag => 'assets/products/bag.png',
      _ProductType.wallet => 'assets/products/walllet.png',
      _ProductType.card => 'assets/products/card.png',
    };

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class _LandingSlide {
  const _LandingSlide({
    required this.word,
    required this.eyebrow,
    required this.description,
    required this.background,
    required this.foreground,
    required this.product,
    required this.accents,
  });

  final String word;
  final String eyebrow;
  final String description;
  final Color background;
  final Color foreground;
  final _ProductType product;
  final List<_ProductType> accents;
}

class _SlideDots extends StatelessWidget {
  const _SlideDots({
    required this.count,
    required this.activeIndex,
    required this.color,
  });

  final int count;
  final int activeIndex;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == activeIndex ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: color.withValues(alpha: index == activeIndex ? .95 : .38),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}