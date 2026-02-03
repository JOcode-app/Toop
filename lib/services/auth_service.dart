import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Connexion avec Google
  Future<UserCredential> signInWithGoogle() async {
    // Lance le flux Google
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Connexion Google annulée');
    }

    // Récupère les tokens (⚠️ besoin de await)
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Crée la credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Connecte à Firebase
    return await _auth.signInWithCredential(credential);
  }

  /// Connexion avec Facebook
  Future<UserCredential> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );

    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw Exception('Connexion Facebook annulée ou échouée: ${result.message ?? ''}');
    }

    // Crée la credential
    final OAuthCredential credential =
        FacebookAuthProvider.credential(result.accessToken!.token);

    // Connecte à Firebase
    return await _auth.signInWithCredential(credential);
  }

  /// Connexion Email / Mot de passe
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Création de compte Email / Mot de passe
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    // Déconnexion des providers sociaux si utilisés
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
    await _auth.signOut();
  }
}