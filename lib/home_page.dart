// lib/home_page.dart
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color appBlue = Color(0xFF1F7BB6); // barre de titre
// pastilles/accents
  static const Color pillBlue = Color(0xFF3B97D3);
  static const Color greenBtn = Color(0xFF3CB371);
  static const Color blueBtn = Color(0xFF2D84B7);

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'PRESSING EXPRESS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Nom/Logo en-tête
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_laundry_service, size: 24, color: appBlue),
                  SizedBox(width: 8),
                  Text(
                    'Pressing Express',
                    style: TextStyle(
                      color: appBlue,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 3 pastilles rondes
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _RoundFeature(
                    icon: Icons.checkroom,
                    label: 'Commander\nun Lavage',
                    bgColor: Color(0xFFE8F4FB),
                    iconBg: Color(0xFF62B5E5),
                  ),
                  _RoundFeature(
                    icon: Icons.route,
                    label: 'Suivre ma\nCommande',
                    bgColor: Color(0xFFEFF8EC),
                    iconBg: Color(0xFF7BC67E),
                  ),
                  _RoundFeature(
                    icon: Icons.person,
                    label: 'Mon Compte',
                    bgColor: Color(0xFFEAF2FA),
                    iconBg: Color(0xFF5F9ED6),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Ruban "Service à Domicile Rapide et Fiable"
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: pillBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Service à Domicile Rapide et Fiable',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // Gros bouton vert "Planifier un Ramassage"
              SizedBox(
                width: w,
                height: 54,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.event_available, color: Colors.white),
                  label: const Text(
                    'Planifier un Ramassage',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenBtn,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // TODO: Aller vers l’écran de planification
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Gros bouton bleu "Estimer les Coûts"
              SizedBox(
                width: w,
                height: 54,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.price_change, color: Colors.white),
                  label: const Text(
                    'Estimer les Coûts',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: blueBtn,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // TODO: Aller vers un calculateur / simulateur
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // Barre de navigation du bas
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: appBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Commandes'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Promos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _RoundFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconBg;

  const _RoundFeature({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: iconBg.withOpacity(0.25)),
          ),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF334155),
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}