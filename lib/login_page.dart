import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;

import 'services/auth_service.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // === Constantes & UI ===
  static const String kAdminEmail = 'gnouangui.joel@gmail.com';

  static const Color deepBlue = Color(0xFF123252);
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color emailGreen = Color(0xFF34A853);
  static const Color chipGrey = Color(0xFFF1F3F5);
  static const Color textGrey = Color(0xFF6B7280);

  /// Ouvre un loader, exécute [action], ferme le loader, puis route selon email.
  Future<void> _handleAuth(
    BuildContext context, {
    required Future<void> Function() action,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await action();

      if (!context.mounted) return;
      Navigator.of(context).pop(); // ferme le loader

      final user = fa.FirebaseAuth.instance.currentUser;
      final email = (user?.email ?? '').toLowerCase();

      if (email == kAdminEmail.toLowerCase()) {
        Navigator.of(context).pushNamedAndRemoveUntil('/admin', (r) => false);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // ferme le loader si erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Échec de la connexion: ${_readableAuthError(e)}'),
          ),
        );
      }
    }
  }

  String _readableAuthError(Object e) {
    if (e is fa.FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'Utilisateur introuvable';
        case 'wrong-password':
          return 'Mot de passe incorrect';
        case 'invalid-email':
          return 'Email invalide';
        case 'account-exists-with-different-credential':
          return 'Ce compte existe avec un autre mode de connexion';
        case 'network-request-failed':
          return 'Problème de connexion réseau';
        default:
          return e.message ?? e.code;
      }
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

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

              // Bandeau d’info
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
                      'Veuillez-vous connecter ou créer un compte pour passer votre commande.',
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

              // --- GOOGLE ---
              _SocialButton(
                color: googleBlue,
                icon: Icons.g_mobiledata, // Remplace par un asset Google si tu veux
                label: "Se connecter avec Google",
                onPressed: () {
                  _handleAuth(
                    context,
                    action: () async {
                      await auth.signInWithGoogle();
                    },
                  );
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

              // --- EMAIL ---
              _SocialButton(
                color: emailGreen,
                icon: Icons.email_outlined,
                label: "Se connecter avec mon Email",
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EmailAuthPage()),
                  );
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

// --------- PAGE EMAIL ----------
class EmailAuthPage extends StatelessWidget {
  const EmailAuthPage({super.key});

  @override
  Widget build(BuildContext context) => const _EmailAuthView();
}

class _EmailAuthView extends StatefulWidget {
  const _EmailAuthView();

  @override
  State<_EmailAuthView> createState() => _EmailAuthViewState();
}

class _EmailAuthViewState extends State<_EmailAuthView> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _isLogin = true;
  bool _obscure = true;
  bool _loading = false;

  static const String kAdminEmail = LoginPage.kAdminEmail;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      } else {
        await _auth.registerWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      }

      if (!mounted) return;

      final user = fa.FirebaseAuth.instance.currentUser;
      final mail = (user?.email ?? '').toLowerCase();

      if (mail == kAdminEmail.toLowerCase()) {
        Navigator.of(context).pushNamedAndRemoveUntil('/admin', (r) => false);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      }
    } on fa.FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg = e.message ?? e.code;
      if (e.code == 'user-not-found') msg = 'Utilisateur introuvable';
      if (e.code == 'wrong-password') msg = 'Mot de passe incorrect';
      if (e.code == 'email-already-in-use') msg = 'Email déjà utilisé';
      if (e.code == 'invalid-email') msg = 'Email invalide';
      if (e.code == 'weak-password') msg = 'Mot de passe trop faible (min. 6 caractères)';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? 'Connexion' : 'Création de compte';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailCtrl,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email requis';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _passwordCtrl,
                    autofillHints: const [AutofillHints.password],
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Mot de passe requis';
                      if (!_isLogin && v.length < 6) {
                        return 'Min. 6 caractères';
                      }
                      return null;
                    },
                  ),

                  if (!_isLogin) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (!_isLogin && v != _passwordCtrl.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(_isLogin ? 'Se connecter' : 'Créer un compte'),
                    ),
                  ),

                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _loading ? null : () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin
                          ? "Pas de compte ? Créer un compte"
                          : "Déjà un compte ? Se connecter",
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}