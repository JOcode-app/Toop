import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // <- pour les actions (appel, email, maps)

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const Color deepBlue = Color(0xFF123252);

  // Coordonnées (tu peux les déplacer dans un fichier de config)
  static const String phone = '+2250160745119';
  static const String email = 'contact@toopressing.com';
  static const String addressLabel = 'Abidjan, Cocody Angré 8ème Tranche';
  // Lien Google Maps (remplace par ton lien précis)
  static final Uri mapsUri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=Abidjan+Cocody+Angr%C3%A9+8eme+Tranche',
  );

  // Helpers pour lancer les intents
  Future<void> _launchTel() async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri)) {
      throw 'Impossible de lancer l’appel : $phone';
    }
  }

  Future<void> _launchMail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: Uri(queryParameters: {
        'subject': 'Demande d’information – Too Pressing',
      }).query,
    );
    if (!await launchUrl(uri)) {
      throw 'Impossible d’ouvrir l’e-mail : $email';
    }
  }

  Future<void> _launchMaps() async {
    if (!await launchUrl(mapsUri, mode: LaunchMode.externalApplication)) {
      throw 'Impossible d’ouvrir la localisation';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("À propos"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Too Pressing : ",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            
          "Nous sommes dédiés à offrir un service de pressing de qualité supérieure, "
            "Plus qu’une simple application, c’est votre partenaire quotidien pour un look impeccable sans le moindre effort. Nous avons fusionné le savoir-faire artisanal du pressing traditionnel avec la simplicité du numérique. "
        
          ,
            style: TextStyle(fontSize: 14.5, height: 1.4),
          ),
          const SizedBox(height: 18),
          const _AboutTile(
            icon: Icons.local_shipping_outlined,
            title: "Collecte & Livraison",
            subtitle: "Disponible sur rendez-vous, créneaux flexibles.",
          ),
          const _AboutTile(
            icon: Icons.verified_outlined,
            title: "Qualité garantie",
            subtitle: "Procédés professionnels et respect des textiles.",
          ),
          const _AboutTile(
            icon: Icons.schedule_outlined,
            title: "Délais",
            subtitle: "24–72h selon le service choisi.",
          ),
          const _AboutTile(
            icon: Icons.call_outlined,
            title: "Support",
            subtitle: "Assistance du lundi au samedi, 8h–20h.",
          ),

          const SizedBox(height: 24),

          // ======== ZONE CONTACT BLEU FONCÉ ========
          Container(
            decoration: BoxDecoration(
              color: deepBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Nous contacter",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),

                // Téléphone
                _ContactRow(
                  icon: Icons.phone_in_talk_rounded,
                  label: phone,
                  onTap: _launchTel,
                ),
                const SizedBox(height: 10),

                // Email
                _ContactRow(
                  icon: Icons.email_outlined,
                  label: email,
                  onTap: _launchMail,
                ),
                const SizedBox(height: 10),

                // Localisation
                _ContactRow(
                  icon: Icons.location_on_outlined,
                  label: addressLabel,
                  onTap: _launchMaps,
                ),

                const SizedBox(height: 12),
                // Petites actions rapides (boutons)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _launchTel,
                        icon: const Icon(Icons.call, color: Colors.white),
                        label: const Text('Appel', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _launchMail,
                        icon: const Icon(Icons.email_outlined, color: Colors.white),
                        label: const Text('Écrire', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _launchMaps,
                        icon: const Icon(Icons.map_outlined, color: Colors.white),
                        label: const Text('Lieu', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AboutTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AboutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF2E5BFF)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}