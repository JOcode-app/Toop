import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:google_sign_in/google_sign_in.dart' as gsi;

import '../firebase_options.dart';

class AuthService {
  final fa.FirebaseAuth _auth = fa.FirebaseAuth.instance;

  // IMPORTANT :
  // - iOS/macOS : on passe le clientId iOS (REVERSED_CLIENT_ID dans Info.plist)
  // - Android   : NE PAS passer de clientId (chargé via google-services.json)
  late final gsi.GoogleSignIn _googleSignIn = _buildGoogleSignIn();

  gsi.GoogleSignIn _buildGoogleSignIn() {
    if (Platform.isIOS || Platform.isMacOS) {
      return gsi.GoogleSignIn(
        clientId: DefaultFirebaseOptions.ios.iosClientId,
        // scopes: ['email', 'profile'], // optionnel
      );
    }
    // Android (et autres) : pas de clientId
    return gsi.GoogleSignIn();
  }

  /// Connexion avec Google
  Future<fa.UserCredential> signInWithGoogle() async {
    try {
      // Optionnel : déconnecte une session précédente si elle bloque
      await _googleSignIn.signOut();

      final gsi.GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Connexion Google annulée');
      }

      final gsi.GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        throw Exception('Tokens Google manquants');
      }

      final fa.OAuthCredential credential = fa.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      // Aide au diagnostic (affiche le code d’erreur dans la console)
      // Erreurs fréquentes : ApiException: 10 (SHA manquant) / 12500 (config OAuth)
      // Tu verras le détail dans `flutter run -v`.
      // ignore: avoid_print
      print('Google sign-in error: $e');
      rethrow;
    }
  }

  /// Connexion Email/Mot de passe
  Future<fa.UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Création de compte Email/Mot de passe
  Future<fa.UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Déconnexion (Google + Firebase)
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // ignore
    }
    await _auth.signOut();
  }
}