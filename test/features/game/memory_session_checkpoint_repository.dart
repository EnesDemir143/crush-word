import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/repositories/session_checkpoint_repository.dart';

class MemorySessionCheckpointRepository extends SessionCheckpointRepository {
  GameSession? _session;

  @override
  Future<void> save(GameSession session) async {
    _session = session;
  }

  @override
  Future<GameSession?> load() async {
    return _session;
  }

  @override
  Future<void> clear() async {
    _session = null;
  }
}
