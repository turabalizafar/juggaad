import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agent_trace.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<AgentTrace>> streamAgentTrace(String requestId) {
    return _firestore
        .collection('service_requests')
        .doc(requestId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return [];
      final data = snapshot.data();
      if (data == null || !data.containsKey('agent_trace')) return [];
      
      final traceList = data['agent_trace'] as List<dynamic>;
      return traceList
          .map((e) => AgentTrace.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }
}
