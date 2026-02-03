import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:google_sign_in/google_sign_in.dart' as gsi;

import '../firebase_options.dart'; // pour récupérer le clientId iOS

class AuthService {
  final fa.FirebaseAuth _auth = fa.FirebaseAuth.instance;

  // GoogleSignIn (avec clientId iOS pour fiabilité sur simulateur iOS)
  final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn(
    clientId: DefaultFirebaseOptions.ios.iosClientId,
    // scopes: ['email', 'profile'], // optionnel
  );

  /// Connexion avec Google
  Future<fa.UserCredential> signInWithGoogle() async {
    final gsi.GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Connexion Google annulée');
    }

    final gsi.GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final fa.OAuthCredential credential = fa.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  /// Connexion Email/Mot de passe
  Future<fa.UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Création de compte Email/Mot de passe
  Future<fa.UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Déconnexion (Google + Firebase)
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }
}