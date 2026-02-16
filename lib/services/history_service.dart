import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_config.dart';

class HistoryService {
  static final FirebaseFirestore _firestore = FirebaseConfig.firestore;

  static Future<void> saveCalculation(String uid, Map<String, dynamic> calculation) async {
    await _firestore.collection('users').doc(uid).collection('history').add({
      ...calculation,
      'timestamp': DateTime.now(),
    });
  }

  static Future<List<Map<String, dynamic>>> loadHistory(String uid) async {
    QuerySnapshot snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  static Future<void> editProject(String uid, String docId, Map<String, dynamic> updates) async {
    await _firestore.collection('users').doc(uid).collection('history').doc(docId).update(updates);
  }
}