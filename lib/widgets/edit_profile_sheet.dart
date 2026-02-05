import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:google_sign_in/google_sign_in.dart' as gsi;

import '../services/profile_service.dart';

/// Ouvre le popup. Retourne true si des changements ont été enregistrés.
Future<bool?> showEditProfileSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => const _EditProfileSheetBody(),
  );
}

class _EditProfileSheetBody extends StatefulWidget {
  const _EditProfileSheetBody();

  @override
  State<_EditProfileSheetBody> createState() => _EditProfileSheetBodyState();
}

class _EditProfileSheetBodyState extends State<_EditProfileSheetBody> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _currentPwdCtrl = TextEditingController(); // pour réauth email/password
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  final _profileService = ProfileService();
  fa.User? _user;

  @override
  void initState() {
    super.initState();
    _primeFormData();
  }

  Future<void> _primeFormData() async {
    final user = fa.FirebaseAuth.instance.currentUser;
    setState(() {
      _user = user;
    });
    if (user == null) {
      if (mounted) Navigator.pop(context, false);
      return;
    }
    // Pré-remplir depuis FirebaseAuth
    _nameCtrl.text = user.displayName ?? '';
    _emailCtrl.text = user.email ?? '';

    // Téléphone & adresse depuis Firestore
    final u = await _profileService.fetchProfile(user.uid);
    _phoneCtrl.text = u['phone'] ?? '';
    _addressCtrl.text = u['address'] ?? '';

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  bool get _isGoogleProvider {
    final providers = _user?.providerData.map((p) => p.providerId).toList() ?? const [];
    return providers.contains('google.com');
  }

  bool get _isPasswordProvider {
    final providers = _user?.providerData.map((p) => p.providerId).toList() ?? const [];
    return providers.contains('password');
  }

  Future<void> _reauthIfNeeded({
    required bool emailChanged,
    required bool passwordChanged,
  }) async {
    if (!emailChanged && !passwordChanged) return; // pas besoin

    final user = _user!;
    // 1) Essaye réauth via Google si provider Google
    if (_isGoogleProvider) {
      try {
        // Méthode moderne (si supportée par ta version)
        await user.reauthenticateWithProvider(fa.GoogleAuthProvider());
        return;
      } catch (_) {
        // Fallback: GoogleSignIn -> credential
        final g = gsi.GoogleSignIn(
          clientId: (Platform.isIOS || Platform.isMacOS)
              ? null // FirebaseAuth.reauthenticateWithProvider gère mieux iOS
              : null,
        );
        final account = await g.signIn();
        if (account == null) {
          throw Exception('Ré-authentification annulée (Google).');
        }
        final auth = await account.authentication;
        final cred = fa.GoogleAuthProvider.credential(
          idToken: auth.idToken,
          accessToken: auth.accessToken,
        );
        await user.reauthenticateWithCredential(cred);
        return;
      }
    }

    // 2) Réauth email/password si provider 'password'
    if (_isPasswordProvider) {
      final email = user.email;
      final currentPwd = _currentPwdCtrl.text.trim();
      if (email == null || email.isEmpty) {
        throw Exception('Email introuvable pour la ré-authentification.');
      }
      if (currentPwd.isEmpty) {
        throw Exception('Mot de passe actuel requis pour modifier email/mot de passe.');
      }
      final cred = fa.EmailAuthProvider.credential(email: email, password: currentPwd);
      await user.reauthenticateWithCredential(cred);
      return;
    }

    // 3) Autres providers : on bloque proprement
    throw Exception("Ré-authentification requise mais provider non géré.");
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final user = _user!;
      final oldName = user.displayName ?? '';
      final oldEmail = user.email ?? '';
      final newName = _nameCtrl.text.trim();
      final newEmail = _emailCtrl.text.trim();
      final newPhone = _phoneCtrl.text.trim();
      final newAddress = _addressCtrl.text.trim();
      final newPwd = _newPwdCtrl.text.trim();
      final confirmPwd = _confirmPwdCtrl.text.trim();

      final emailChanged = newEmail.isNotEmpty && newEmail != oldEmail;
      final passwordChanged = newPwd.isNotEmpty;

      if (passwordChanged && newPwd != confirmPwd) {
        throw Exception('Les deux mots de passe ne correspondent pas.');
      }

      // Ré-auth si nécessaire (email/password modifiés)
      await _reauthIfNeeded(emailChanged: emailChanged, passwordChanged: passwordChanged);

      // 1) Affichage du nom (FirebaseAuth)
      if (newName != oldName) {
        await user.updateDisplayName(newName);
      }

      // 2) Email (FirebaseAuth)
      if (emailChanged) {
        await user.updateEmail(newEmail);
      }

      // 3) Mot de passe (FirebaseAuth)
      if (passwordChanged) {
        await user.updatePassword(newPwd);
      }

      // 4) Téléphone & adresse (Firestore)
      await _profileService.upsertProfile(user.uid, phone: newPhone, address: newAddress);

      await user.reload();

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès.')),
        );
      }
    } on fa.FirebaseAuthException catch (e) {
      // Gestion des erreurs FirebaseAuth fréquentes
      String msg = 'Erreur: ${e.code}';
      if (e.code == 'requires-recent-login') {
        msg = 'Action sensible: ré-authentifie-toi puis réessaie.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'Cet email est déjà utilisé.';
      } else if (e.code == 'invalid-email') {
        msg = 'Email invalide.';
      } else if (e.code == 'weak-password') {
        msg = 'Mot de passe trop faible (min. 6 caractères).';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await fa.FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pop(context, false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur déconnexion: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.90,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Scaffold(
                  backgroundColor: Colors.white,
                  appBar: AppBar(
                    title: const Text('Mon profil'),
                    centerTitle: true,
                    backgroundColor: Colors.white,
                    elevation: 0.5,
                    foregroundColor: Colors.black87,
                    automaticallyImplyLeading: false,
                  ),
                  body: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      children: [
                        // Nom complet
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nom complet',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nom requis'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Téléphone (stocké Firestore)
                        TextFormField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Numéro de téléphone',
                            hintText: 'Ex: 07 00 00 00 00',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().length < 8) ? 'Numéro invalide' : null,
                        ),
                        const SizedBox(height: 12),

                        // Email (FirebaseAuth)
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return 'Email requis';
                            final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(t);
                            return ok ? null : 'Email invalide';
                          },
                        ),
                        const SizedBox(height: 12),

                        // Adresse (Firestore)
                        TextFormField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Adresse',
                            hintText: 'Ex: Cocody Angré, villa 12',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 18),

                        // Bloc sécurité (réauth) visible si password provider
                        if (_isPasswordProvider) ...[
                          const Text(
                            'Sécurité',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Mot de passe actuel (pour réauth si email/mdp changés)
                          TextFormField(
                            controller: _currentPwdCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Mot de passe actuel (si modification email/mot de passe)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Nouveau mot de passe
                          TextFormField(
                            controller: _newPwdCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Nouveau mot de passe (optionnel)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Confirmation
                          TextFormField(
                            controller: _confirmPwdCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirmer le nouveau mot de passe',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Enregistrer
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Enregistrer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF123252),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Déconnexion
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _signOut,
                            icon: const Icon(Icons.logout),
                            label: const Text('Se déconnecter'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}