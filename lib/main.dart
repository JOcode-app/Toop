import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:url_launcher/url_launcher.dart';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';

// Pages (selon ta structure)
import 'login_page.dart';
import 'home_page.dart';
import 'pages/estimate_costs_page.dart';
import 'pages/about_page.dart';
import 'pages/admin_orders_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2) Intl (locales) — IMPORTANT pour éviter LocaleDataException
  await initializeDateFormatting('fr_FR'); // charge les données FR
  Intl.defaultLocale = 'fr_FR';            // optionnel mais pratique

  runApp(const PressingApp());
}

class PressingApp extends StatelessWidget {
  const PressingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOO PRESSING',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.white,
      ),
      // --- ROUTES ---
      initialRoute: '/',
      routes: {
        '/': (_) => const StartScreen(),
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/prices': (_) => const EstimateCostsPage(),
        '/about': (_) => const AboutPage(),
        '/admin': (_) => const AdminOrdersPage(),
      },
    );
  }
}

/// Écran d’accueil (logo + boutons)
/// ➜ Redirige automatiquement si utilisateur déjà connecté :
///    - email admin => /admin
///    - sinon       => /home
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  static const String _adminEmail = 'gnouangui.joel@gmail.com';

  @override
  void initState() {
    super.initState();
    _maybeRedirect();
  }

  Future<void> _maybeRedirect() async {
    await Future.delayed(const Duration(milliseconds: 120)); // laisse Firebase init
    final user = fa.FirebaseAuth.instance.currentUser;
    if (!mounted || user == null) return;

    final email = (user.email ?? '').toLowerCase();
    if (email == _adminEmail.toLowerCase()) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/admin', (r) => false);
    } else {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
    }
  }

  static const Color primaryBlue = Color.fromARGB(255, 97, 168, 249);
  static const Color deepBlue = Color(0xFF123252);
  static const Color textGrey = Color(0xFF9AA3AF);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // LOGO
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/logo_collar.png',
                  width: size.width * 0.80,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const Text(
              'TOO PRESSING',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: Color(0xFF7A7F85),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Le temple de la propreté',
              style: TextStyle(fontSize: 14, color: Color(0xFFB2B8BF)),
            ),
            const SizedBox(height: 25),

            // --- BOUTON DÉMARRER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Démarrer',
                    style: TextStyle(fontSize: 17, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // --- BOUTON CONNEXION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Connexion',
                    style: TextStyle(fontSize: 17, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- BOUTONS PRIX + COORDONNÉES ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _SmallButton(
                      label: 'Prix',
                      icon: Icons.attach_money,
                      onTap: () => Navigator.pushNamed(context, '/prices'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SmallButton(
                      label: 'Coordonnées',
                      icon: Icons.info_outline,
                      onTap: () => Navigator.pushNamed(context, '/about'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- LIEN FACEBOOK ---
            TextButton(
              onPressed: () async {
                const url = 'https://www.facebook.com/search/top/?q=too%20pressing';
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Impossible d'ouvrir le lien.")),
                  );
                }
              },
              child: const Text(
                'Nous suivre sur Facebook',
                style: TextStyle(color: textGrey, fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFEDEFF2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF9AA3AF)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9AA3AF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
