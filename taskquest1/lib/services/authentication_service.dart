import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth;

  AuthenticationService(this._firebaseAuth);

  // Stream to listen for auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign in method
  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return "Signed in";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Sign up method with Firestore user profile creation
  Future<String?> signUp({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'points': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return "Signed up";
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Sign in with Google Credential
  Future<String?> signInWithGoogleCredential(AuthCredential credential) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      // Check if the user is new or existing to create Firestore document
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': userCredential.user!.email,
          'displayName': userCredential.user!.displayName,
          'photoURL': userCredential.user!.photoURL,
          'points': 0,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // Use merge to avoid overwriting if somehow exists
      }
      return "Signed in";
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Sign out method
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
