
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> registerWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
    String role = 'citizen',
    String organization = '',
    String organizationDetails = '',
    String verificationIdType = '',
  }) async {
    if (role != 'citizen' && role != 'volunteer') {
      throw Exception('Invalid account type.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) throw Exception('Account creation failed.');

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'status': 'active',
        'organization': role == 'volunteer' ? organization : '',
        'organizationDetails':
            role == 'volunteer' ? organizationDetails : '',
        'verificationIdType':
            role == 'volunteer' ? verificationIdType : '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } catch (_) {
      await user.delete();
      rethrow;
    }
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    await _googleSignIn.initialize();
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
