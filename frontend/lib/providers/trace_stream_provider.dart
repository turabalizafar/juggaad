import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_trace.dart';
import 'service_providers.dart';

final traceStreamProvider = StreamProvider.family<List<AgentTrace>, String>((ref, requestId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamAgentTrace(requestId);
});
