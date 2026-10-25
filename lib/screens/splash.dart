import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../i18n.dart';
import '../theme.dart';
import 'home.dart';

/// ~4 second animated splash: rings ripple out, the alarm-clock logo pops in
/// and rings, the name slides up, then "Powered By Sobky" fades in.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _main = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  );
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _main.forward().whenComplete(_goHome);
  }

  void _goHome() {
    if (!mounted) return;
    StoreScope.read(context).splashShown = true;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) => const HomeScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: child,
      ),
    ));
  }

  @override
  void dispose() {
    _main.dispose();
    _ripple.dispose();
    super.dispose();
  }

  double _interval(double begin, double end, [Curve curve = Curves.easeOut]) {
    final t = ((_main.value - begin) / (end - begin)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_main, _ripple]),
        builder: (context, _) {
          final pop = _interval(0.0, 0.32, Curves.elasticOut);
          final fadeIn = _interval(0.0, 0.15);
          final ring = _interval(0.30, 0.58, Curves.linear);
          final shake = math.sin(ring * math.pi * 8) * 0.09 * (1 - ring);
          final textT = _interval(0.42, 0.66, Curves.easeOutCubic);
          final tagT = _interval(0.55, 0.75, Curves.easeOutCubic);
          final sobkyT = _interval(0.62, 0.82);
          final floatY = math.sin(_main.value * math.pi * 2) * 4;
          final exit = _interval(0.93, 1.0);

          return Opacity(
            opacity: 1 - exit * 0.15,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppColors.dark
                      ? const [
                          Color(0xFF0E1726),
                          Color(0xFF13233A),
                          Color(0xFF142B2A)
                        ]
                      : const [
                          Colors.white,
                          Color(0xFFEAF5FC),
                          Color(0xFFE6F5E8)
                        ],
                ),
              ),
              child: Stack(
                children: [
                  // soft floating blobs
                  _Blob(
                      top: -60 + floatY * 3,
                      right: -40,
                      size: 200,
                      color: AppColors.sky.withValues(alpha: 0.10)),
                  _Blob(
                      bottom: 80 - floatY * 2,
                      left: -70,
                      size: 220,
                      color: AppColors.green.withValues(alpha: 0.10)),
                  _Blob(
                      top: 160 + floatY * 2,
                      left: 30,
                      size: 40,
                      color: AppColors.orange.withValues(alpha: 0.18)),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 260,
                          height: 260,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              for (var i = 0; i < 3; i++)
                                _rippleRing(i, fadeIn),
                              Opacity(
                                opacity: fadeIn,
                                child: Transform.translate(
                                  offset: Offset(0, floatY),
                                  child: Transform.rotate(
                                    angle: shake,
                                    child: Transform.scale(
                                      scale: 0.3 + 0.7 * pop,
                                      child: Image.asset(
                                        'assets/logo_icon.png',
                                        width: 170,
                                        filterQuality: FilterQuality.high,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Opacity(
                          opacity: textT,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - textT)),
                            child: AppColors.dark
                                ? Text(
                                    tr('علاجي', 'Elagy'),
                                    style: GoogleFonts.cairo(
                                      fontSize: 46,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  )
                                : isAr
                                    ? Image.asset(
                                        'assets/logo_text.png',
                                        width: 150,
                                        filterQuality: FilterQuality.high,
                                      )
                                    : Text(
                                        'Elagy',
                                        style: GoogleFonts.poppins(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.navy,
                                        ),
                                      ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Opacity(
                          opacity: tagT,
                          child: Transform.translate(
                            offset: Offset(0, 16 * (1 - tagT)),
                            child: Text(
                              tr('دواك في ميعاده.. لكل اللي بتحبهم',
                                  'Every dose on time, for everyone you love'),
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Opacity(
                          opacity: tagT,
                          child: SizedBox(
                            width: 120,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _main.value,
                                minHeight: 5,
                                backgroundColor: AppColors.skyLight,
                                valueColor: AlwaysStoppedAnimation(
                                    AppColors.green),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 34,
                    child: SafeArea(
                      top: false,
                      child: Opacity(
                        opacity: sobkyT,
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - sobkyT)),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Powered By ',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.muted,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Sobky',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _rippleRing(int i, double visible) {
    final t = (_ripple.value + i / 3) % 1.0;
    return IgnorePointer(
      child: Opacity(
        opacity: (1 - t) * 0.55 * visible,
        child: Container(
          width: 130 + 130 * t,
          height: 130 + 130 * t,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: i.isEven ? AppColors.sky : AppColors.green,
              width: 2.5 * (1 - t) + 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double? top, bottom, left, right;
  final double size;
  final Color color;
  const _Blob({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Positioned(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      );
}
