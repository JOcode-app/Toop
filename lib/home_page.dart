import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;

import 'package:pressing_too/pages/about_page.dart';
import 'package:pressing_too/pages/orders_page.dart';
import 'package:pressing_too/pages/estimate_costs_page.dart';
import 'package:pressing_too/widgets/edit_profile_sheet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Palette
  static const Color deepBlue = Color(0xFF123252);
  static const Color primaryBlue = Color(0xFF2E5BFF);
  static const Color softBg = Color(0xFFF7F9FC);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color chipBg = Color(0xFFF1F3F5);

  String _displayName(fa.User? u) {
    if (u == null) return 'Utilisateur';
    final name = u.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = u.email?.trim();
    if (email != null && email.isNotEmpty) {
      final beforeAt = email.split('@').first;
      return beforeAt.isNotEmpty ? beforeAt : 'Utilisateur';
    }
    return 'Utilisateur';
  }

  String _initialsFromUser(fa.User? u) {
    if (u == null) return 'U';
    final name = u.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return _initialsFromText(name);
    }
    final email = u.email?.trim();
    if (email != null && email.isNotEmpty) {
      return _initialsFromText(email.split('@').first);
    }
    return 'U';
  }

  // Extrait 1–2 initiales de façon robuste (UTF-16/graphemes via `characters`)
  String _initialsFromText(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    String first = '';
    String last = '';
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      first = parts.first.characters.take(1).toString();
    }
    if (parts.length > 1 && parts.last.isNotEmpty) {
      last = parts.last.characters.take(1).toString();
    }
    String ini = (first + last).toUpperCase();
    if (ini.isEmpty && text.isNotEmpty) {
      ini = text.characters.take(2).toString().toUpperCase();
    }
    return ini.isEmpty ? 'U' : ini;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return StreamBuilder<fa.User?>(
      stream: fa.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final user = snap.data;
        final titleText = _displayName(user);
        final initials = _initialsFromUser(user);
        final photoURL = user?.photoURL;

        Future<void> _openProfile() async {
          await showEditProfileSheet(context);
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0.5,
            backgroundColor: Colors.white,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 18),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Retour',
            ),
            title: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _openProfile,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar (photo ou initiales)
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFE8F0FF),
                    backgroundImage: (photoURL != null && photoURL.isNotEmpty)
                        ? NetworkImage(photoURL)
                        : null,
                    child: (photoURL == null || photoURL.isEmpty)
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: Color(0xFF2E5BFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      titleText,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // -------------------- HERO (carrousel) --------------------
                _HeroCarousel(
                  height: size.height * 0.18,
                  title: 'Fini la corvée de lessive !',
                  images: const [
                    AssetImage('assets/hero_laundry_1.png'),
                    AssetImage('assets/hero_laundry_2.png'),
                    AssetImage('assets/hero_laundry_3.png'),
                    AssetImage('assets/hero_laundry_4.png'),
                  ],
                  autoPlayInterval: const Duration(seconds: 3),
                ),

                // -------------------- CARTE PRINCIPALE --------------------
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),

                      const Text(
                        'BIENVENUE CHEZ TOO PRESSING',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _ServicePill(
                              icon: Icons.verified_user_outlined,
                              title: 'À\npropos',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AboutPage()),
                                );
                              },
                            ),
                            _ServicePill(
                              icon: Icons.receipt_long_outlined,
                              title: 'Mes\ncommandes',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const OrdersPage()),
                                );
                              },
                            ),
                            _ServicePill(
                              icon: Icons.local_atm_outlined,
                              title: 'Estimer\nles coûts',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const EstimateCostsPage()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),
                      const Divider(height: 1, color: Color(0xFFE7EBF0)),
                      const SizedBox(height: 14),

                      const _SectionTitle(title: 'Comment ça marche ? (Étapes simples)'),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StepCard(
                                stepNumber: 1,
                                title: 'Collecte à\nDomicile',
                                image: AssetImage('assets/step_1.png'),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _StepCard(
                                stepNumber: 2,
                                title: 'Lavage\nProfessionnel',
                                image: AssetImage('assets/step_2.png'),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _StepCard(
                                stepNumber: 3,
                                title: 'Livraison\nImpeccable',
                                image: AssetImage('assets/step_3.png'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const _SectionTitle(title: 'Pourquoi nous choisir ?'),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _BulletList(items: [
                          'Simplicité',
                          'Qualité garantie',
                          'Rapidité et fiabilité',
                        ]),
                      ),
                      const SizedBox(height: 18),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EstimateCostsPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: deepBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Planifier une collecte',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),

                const SizedBox(height: 6),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  height: 6,
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// Widgets internes (inchangés)
// ---------------------------------------------------------

class _HeroCarousel extends StatefulWidget {
  final double height;
  final String title;
  final List<ImageProvider> images;
  final Duration autoPlayInterval;

  const _HeroCarousel({
    required this.height,
    required this.title,
    required this.images,
    required this.autoPlayInterval,
  });

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    Future.delayed(widget.autoPlayInterval, () {
      if (mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoPlay();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      color: HomePage.softBg,
      child: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index % widget.images.length;
              });
            },
            children: widget.images
                .map(
                  (image) => Image(
                    image: image,
                    fit: BoxFit.cover,
                  ),
                )
                .toList(),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? HomePage.primaryBlue
                          : Colors.grey.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicePill extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _ServicePill({
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 62,
              width: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF2E5BFF), size: 30),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final ImageProvider? image;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFF9AA3AF)),
      ),
    );

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.15,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image != null
                ? Image(image: image!, fit: BoxFit.cover)
                : placeholder,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$stepNumber. $title',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: Color(0xFF34A853),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e,
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}