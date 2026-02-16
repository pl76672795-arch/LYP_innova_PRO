import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_config.dart';

class LicenseService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  static Future<void> activateLicense(String uid, String code) async {
    DocumentSnapshot licenseDoc = await _firestore.collection('licenses').doc(code).get();
    if (!licenseDoc.exists || licenseDoc['used'] == true) {
      throw Exception('Código inválido o usado.');
    }
    DateTime expiry = DateTime.now().add(const Duration(days: 30));
    await _firestore.collection('users').doc(uid).update({'expiry': expiry});
    await _firestore.collection('licenses').doc(code).update({'used': true, 'userId': uid});
  }

  static Future<bool> isLicenseActive(String uid) async {
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return false;
    Timestamp? expiry = userDoc['expiry'];
    return expiry != null && expiry.toDate().isAfter(DateTime.now());
  }
}