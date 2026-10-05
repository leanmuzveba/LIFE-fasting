import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';

/// Loading screen from the "LIFE Fasting" splash design: a ring logo that
/// beats like a heart, the wordmark, and bouncing dots. Shown by the root gate
/// while data loads. Still when the system asks for reduced motion.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  late final _bounce = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _beat.stop();
      _bounce.stop();
    } else {
      if (!_beat.isAnimating) _beat.repeat();
      if (!_bounce.isAnimating) _bounce.repeat();
    }
  }

  @override
  void dispose() {
    _beat.dispose();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const secondary = TextStyle(fontFamily: AppFonts.mono, fontWeight: FontWeight.w500, color: AppColors.textSecondary);
    return Scaffold(
      body: Semantics(
        label: l.splashLoading,
        excludeSemantics: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.background),
            const Positioned(top: -80, left: -80, child: _Glow(diameter: 256)),
            const Positioned(bottom: -80, right: -80, child: _Glow(diameter: 320)),
            SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Heartbeat(animation: _beat, child: const RingLogo(size: 128)),
                          const SizedBox(height: 32),
                          const _Wordmark(),
                          const SizedBox(height: 12),
                          Opacity(
                            opacity: 0.8,
                            child: Text(
                              l.splashTagline,
                              textAlign: TextAlign.center,
                              style: secondary.copyWith(fontSize: 10, letterSpacing: 0.25),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 48,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BouncingDots(animation: _bounce),
                        const SizedBox(height: 16),
                        Text(l.splashInitializing, style: secondary.copyWith(fontSize: 12, letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "LIFE" bold + "Fasting" light, as in the design.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) => const Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: 'LIFE',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text),
        ),
        WidgetSpan(child: SizedBox(width: 8)),
        TextSpan(
          text: 'Fasting',
          style: TextStyle(fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        ),
      ],
    ),
    textAlign: TextAlign.center,
    style: TextStyle(fontFamily: AppFonts.display, fontSize: 36, height: 40 / 36, letterSpacing: -0.9),
  );
}

/// Double "lub-dub" beat, then a rest — one cycle per animation period.
class _Heartbeat extends StatelessWidget {
  const _Heartbeat({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12).chain(CurveTween(curve: Curves.easeOut)), weight: 12),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 13),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.07).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
    TweenSequenceItem(tween: Tween(begin: 1.07, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 15),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
  ]);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (_, child) => Transform.scale(scale: _scale.evaluate(animation), child: child),
    child: child,
  );
}

class _BouncingDots extends StatelessWidget {
  const _BouncingDots({required this.animation});

  final Animation<double> animation;
  static const _dot = 6.0;

  double _offset(double t) {
    if (t < 0.5) return -0.25 * _dot * (1 - const Cubic(0.8, 0, 1, 1).transform(t / 0.5));
    return -0.25 * _dot * const Cubic(0, 0, 0.2, 1).transform((t - 0.5) / 0.5);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (_, _) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
            child: Transform.translate(
              offset: Offset(0, _offset(animation.value)),
              child: Container(
                width: _dot,
                height: _dot,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
            ),
          ),
      ],
    ),
  );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.diameter});
  final double diameter;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 64, sigmaY: 64),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.soft.withValues(alpha: 0.6)),
      ),
    ),
  );
}

/// The design's logo: track, ~70% sky arc and a deep-blue clock hand.
class RingLogo extends StatelessWidget {
  const RingLogo({super.key, this.size = 128});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _RingLogoPainter()),
  );
}

class _RingLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.shortestSide / 100); // drawn on a 100×100 grid
    const c = Offset(50, 50);
    const r = 42.0;
    Paint stroke(Color color, double w) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;

    canvas.drawCircle(
      c.translate(0, 1),
      r,
      stroke(const Color(0x0D000000), 8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.5),
    );
    canvas.drawCircle(c, r, stroke(AppColors.track, 8));
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * 184 / 264,
      false,
      stroke(AppColors.primary, 8)..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, 32, Paint()..color = AppColors.soft.withValues(alpha: 0.5));
    canvas.drawPath(
      Path()
        ..moveTo(50, 35)
        ..lineTo(50, 50)
        ..lineTo(60, 60),
      stroke(AppColors.primary, 4)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RingLogoPainter old) => false;
}
