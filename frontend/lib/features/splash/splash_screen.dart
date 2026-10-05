import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/theme/tokens.dart';

/// Animated RUVA splash, matched frame-by-frame to the supplied video
/// (1.5 s, cream background): the lime body is there from the start, the
/// forest arm draws outward from its middle, U·V·A pop in one by one and the
/// head dot pulses until the logo completes at ~1.2 s. If loading takes
/// longer, the head keeps a gentle heartbeat. Static when the system asks for
/// reduced motion.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Length of the build-up animation.
  static const intro = Duration(milliseconds: 1200);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final _intro = AnimationController(vsync: this, duration: SplashScreen.intro);
  late final _beat = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward().whenComplete(() {
        if (mounted) _beat.repeat();
      });
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.sizeOf(context).width * 0.32).clamp(100.0, 160.0);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Semantics(
        label: context.l10n.splashLoading,
        excludeSemantics: true,
        child: Center(
          child: SizedBox.square(
            dimension: size,
            child: AnimatedBuilder(
              animation: Listenable.merge([_intro, _beat]),
              builder: (_, _) => AnimatedLogo(t: _intro.value * 1.2, beat: _beat.isAnimating ? _beat.value : null),
            ),
          ),
        ),
      ),
    );
  }
}

/// The six logo layers (same 741×741 canvas, so they stack exactly).
class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({super.key, required this.t, this.beat});

  /// Seconds into the build-up (0 … 1.2).
  final double t;

  /// 0…1 phase of the post-intro heartbeat, or null while building up.
  final double? beat;

  static Widget _layer(String name) => Image.asset('assets/brand/splash/$name.png', fit: BoxFit.contain);

  // Measured from the video (30 fps): the arm grows linearly from nothing to
  // full size about its own centre (canvas box x 0…544, y 64…337) from 0.10 s
  // to 1.17 s, keeping its hooked shape.
  static const _armStart = 0.10, _armEnd = 1.17;
  static const _armAlign = Alignment(272 / 741 * 2 - 1, 200.5 / 741 * 2 - 1);
  // Head dot centre on the canvas, for scaling about its middle.
  static const _headAlign = Alignment(589.5 / 741 * 2 - 1, 77.5 / 741 * 2 - 1);

  /// Head scale: pops tiny↔full every 0.267 s, settles full at ~1.17 s.
  double get headScale {
    if (beat != null) return _heartbeat(beat!);
    const tiny = 0.15, period = 0.2667;
    if (t >= 1.167) return 1;
    if (t >= 1.067) return tiny + (1 - tiny) * ((t - 1.067) / 0.1);
    return tiny + (1 - tiny) * math.sin(math.pi * t / period).abs();
  }

  /// Lub-dub, then rest.
  static double _heartbeat(double p) {
    double bump(double at, double width, double height) {
      final d = (p - at).abs() / width;
      return d >= 1 ? 0 : height * (1 - d * d);
    }

    return 1 + bump(0.12, 0.10, 0.18) + bump(0.34, 0.09, 0.10);
  }

  @override
  Widget build(BuildContext context) {
    final arm = ((t - _armStart) / (_armEnd - _armStart)).clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        _layer('body'),
        Transform.scale(scale: arm, alignment: _armAlign, child: _layer('arm')),
        if (t >= 0.30) _layer('u'),
        if (t >= 0.60) _layer('v'),
        if (t >= 0.90) _layer('a'),
        Transform.scale(scale: headScale, alignment: _headAlign, child: _layer('head')),
      ],
    );
  }
}
