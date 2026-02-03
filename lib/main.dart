import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'login_page.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PressingApp());
}

class PressingApp extends StatelessWidget {
  const PressingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TOO PRESSING',
      theme: ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const StartScreen(),
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

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

            // --- BOUTON DÉMARRER -> HOME PAGE ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/home');
                  },
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

            // --- BOUTON CONNEXION -> LoginPage ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text(
                    'Connexion',
                    style: TextStyle(fontSize: 17, color: Colors.white),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _SmallButton(
                      label: 'Prix',
                      icon: Icons.attach_money,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SmallButton(
                      label: 'Coordonnées',
                      icon: Icons.info_outline,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Choisir un autre magasin',
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
                fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}