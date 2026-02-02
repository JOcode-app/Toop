
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';


class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // Couleurs UI
  static const Color deepBlue = Color(0xFF123252);
  static const Color fbBlue = Color(0xFF4267B2);
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color emailGreen = Color(0xFF34A853);
  static const Color chipGrey = Color(0xFFF1F3F5);
  static const Color textGrey = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Se connecter',
                style: TextStyle(
                  color: deepBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Heureux',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.1),
              ),
              const Text(
                'De Vous Rencontrer !',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.1),
              ),
              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: chipGrey,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOO PRESSING | AU BUREAU',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 0.2,
                        color: Color(0xFF7A7F85),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Veuillez-vous connecter ou créer un compte pour passer votre commande.\nPlease login or create an account to place your …',
                      style: TextStyle(fontSize: 14, color: textGrey, height: 1.35),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'afficher plus',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              _SocialButton(
                color: fbBlue,
                icon: Icons.facebook,
                label: "S'inscrire avec Facebook",
                onPressed: () {
                  // TODO: connexion Facebook
                },
              ),
              const SizedBox(height: 12),

              _SocialButton(
                color: googleBlue,
                icon: Icons.g_mobiledata, // Tu peux mettre une icône Google custom
                label: "S'inscrire avec Google",
                onPressed: () {
                  // TODO: connexion Google
                },
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('OU', style: TextStyle(color: textGrey)),
                  ),
                  Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
                ],
              ),

              const SizedBox(height: 16),

              _SocialButton(
                color: emailGreen,
                icon: Icons.email_outlined,
                label: "S'inscrire avec mon Email",
                onPressed: () {
                  // TODO: ouvrir un écran email/password
                },
              ),

              const SizedBox(height: 12),

              Text.rich(
                TextSpan(
                  text: 'En vous inscrivant, vous acceptez la ',
                  style: const TextStyle(color: textGrey, fontSize: 12.5),
                  children: [
                    TextSpan(
                      text: 'politique de confidentialité',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // TODO: ouvrir le lien de la politique
                        },
                    ),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.color,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1.5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
