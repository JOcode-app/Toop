import 'dart:async';
import 'package:flutter/material.dart';

/// Carrousel auto-play avec boucle infinie + pause/reprise sur interaction.
class HeroCarousel extends StatefulWidget {
  final double height;
  final String title;
  final List<ImageProvider> images;
  final Duration autoPlayInterval;       // Intervalle entre 2 slides
  final Duration slideDuration;          // Durée de l'animation de slide
  final Curve slideCurve;                // Courbe d'animation
  final BorderRadiusGeometry borderRadius;

  const HeroCarousel({
    super.key,
    required this.height,
    required this.title,
    required this.images,
    this.autoPlayInterval = const Duration(seconds: 2),
    this.slideDuration = const Duration(milliseconds: 420),
    this.slideCurve = Curves.easeInOut,
    this.borderRadius = const BorderRadius.only(
      bottomLeft: Radius.circular(22),
      bottomRight: Radius.circular(22),
    ),
  });

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> with WidgetsBindingObserver {
  // Index virtuel pour simuler une boucle infinie sans “saut”
  static const int _kVirtualBase = 10000;
  late final PageController _controller;
  Timer? _timer;
  int _virtualIndex = _kVirtualBase;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = PageController(initialPage: _virtualIndex);
    _startAutoPlay();
  }

  // --- AutoPlay management ---
  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.images.length <= 1) return; // inutile si moins de 2 images
    _timer = Timer.periodic(widget.autoPlayInterval, (_) async {
      if (!mounted) return;
      _virtualIndex++;
      await _controller.animateToPage(
        _virtualIndex,
        duration: widget.slideDuration,
        curve: widget.slideCurve,
      );
    });
  }

  void _pauseAutoPlay() {
    _timer?.cancel();
  }

  void _resumeAutoPlay() {
    // Ne relance le timer que s'il n'existe plus
    if (_timer == null || !_timer!.isActive) {
      _startAutoPlay();
    }
  }

  // --- Lifecycle (reprise quand l'app revient en foreground) ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause en arrière-plan, reprise en premier plan
    if (state == AppLifecycleState.resumed) {
      _resumeAutoPlay();
    } else if (state == AppLifecycleState.paused ||
               state == AppLifecycleState.inactive ||
               state == AppLifecycleState.detached) {
      _pauseAutoPlay();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  int _realIndexFrom(int virtualIndex) {
    final n = widget.images.length;
    if (n == 0) return 0;
    return virtualIndex % n;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          children: [
            // Listener pour pause/reprise (plus fiable que GestureDetector seul)
            Listener(
              onPointerDown: (_) => _pauseAutoPlay(),   // dès qu'on touche → pause
              onPointerUp:   (_) => _resumeAutoPlay(),  // doigt relevé → reprise
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (v) => setState(() => _virtualIndex = v),
                itemBuilder: (context, vIndex) {
                  final rIndex = _realIndexFrom(vIndex);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image(image: widget.images[rIndex], fit: BoxFit.cover),

                      // Dégradé sombre en bas
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.center,
                              colors: [
                                Colors.black.withOpacity(0.45),
                                Colors.black.withOpacity(0.10),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Titre
                      Positioned(
                        left: 18,
                        bottom: 18,
                        right: 18,
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Indicateurs (dots)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  final active = _realIndexFrom(_virtualIndex) == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: active ? 18 : 8,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white70,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}