import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/gameplay/services/word_validator.dart';
import 'package:crush_word/src/core/models/game_config.dart';
import 'package:crush_word/src/core/models/game_difficulty.dart';
import 'package:crush_word/src/core/repositories/dictionary_repository.dart';
import 'package:crush_word/src/features/game/game_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'memory_session_checkpoint_repository.dart';

void main() {
  group('Selection finalization', () {
    late DictionaryRepository dictionaryRepository;
    late WordValidator wordValidator;

    setUp(() {
      // Small dictionary containing known words.
      dictionaryRepository = DictionaryRepository(
        assetLoader: (_) async => 'bal\nkale\nsoru\nçay\ntest',
      );
      wordValidator = WordValidator(dictionaryRepository: dictionaryRepository);
    });

    test('invalid attempt decrements remaining moves by 1', () async {
      final GameSession session = _buildSession(
        letters: <String>['X', 'Y', 'Z', 'W', 'Q', 'P', 'R', 'S', 'T'],
        movesLeft: 15,
      );

      final GameController controller = GameController.fromSession(
        session,
        wordValidator: wordValidator,
        sessionCheckpointRepository: MemorySessionCheckpointRepository(),
      );

      // Select 'XYZ' — not in dictionary.
      controller.startSelection(session.cellAt(row: 0, column: 0));
      controller.extendSelection(session.cellAt(row: 0, column: 1));
      controller.extendSelection(session.cellAt(row: 0, column: 2));

      expect(controller.selectedCellIds, <String>['0:0', '0:1', '0:2']);
      expect(controller.movesLeft, 15);

      await controller.endSelection();

      expect(controller.movesLeft, 14);
    });

    test('invalid attempt does not mutate underlying board letters', () async {
      final GameSession session = _buildSession(
        letters: <String>['X', 'Y', 'Z', 'W', 'Q', 'P', 'R', 'S', 'T'],
        movesLeft: 10,
      );

      final GameController controller = GameController.fromSession(
        session,
        wordValidator: wordValidator,
        sessionCheckpointRepository: MemorySessionCheckpointRepository(),
      );

      final List<BoardCell> originalBoard = List<BoardCell>.from(session.board);

      // Select 'XYZ' — not in dictionary.
      controller.startSelection(session.cellAt(row: 0, column: 0));
      controller.extendSelection(session.cellAt(row: 0, column: 1));
      controller.extendSelection(session.cellAt(row: 0, column: 2));

      await controller.endSelection();

      // Board letters must remain unchanged.
      expect(
        controller.session!.board.map((BoardCell c) => c.letter).toList(),
        originalBoard.map((BoardCell c) => c.letter).toList(),
      );
    });

    test('invalid attempt clears selection state', () async {
      final GameSession session = _buildSession(
        letters: <String>['X', 'Y', 'Z', 'W', 'Q', 'P', 'R', 'S', 'T'],
        movesLeft: 10,
      );

      final GameController controller = GameController.fromSession(
        session,
        wordValidator: wordValidator,
        sessionCheckpointRepository: MemorySessionCheckpointRepository(),
      );

      controller.startSelection(session.cellAt(row: 0, column: 0));
      controller.extendSelection(session.cellAt(row: 0, column: 1));
      controller.extendSelection(session.cellAt(row: 0, column: 2));

      await controller.endSelection();

      expect(controller.selectedCellIds, isEmpty);
      expect(controller.selectedWord, isEmpty);
    });

    test('invalid attempt populates lastInvalidFeedback', () async {
      final GameSession session = _buildSession(
        letters: <String>['X', 'Y', 'Z', 'W', 'Q', 'P', 'R', 'S', 'T'],
        movesLeft: 10,
      );

      final GameController controller = GameController.fromSession(
        session,
        wordValidator: wordValidator,
        sessionCheckpointRepository: MemorySessionCheckpointRepository(),
      );

      controller.startSelection(session.cellAt(row: 0, column: 0));
      controller.extendSelection(session.cellAt(row: 0, column: 1));
      controller.extendSelection(session.cellAt(row: 0, column: 2));

      await controller.endSelection();

      expect(controller.lastInvalidFeedback, isNotNull);
      expect(
        controller.lastInvalidFeedback!.reason,
        WordValidationReason.notInDictionary,
      );
    });

    test('too-short selection rejects with tooShort reason', () async {
      final GameSession session = _buildSession(
        letters: <String>['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'],
        movesLeft: 10,
      );

      final GameController controller = GameController.fromSession(
        session,
        wordValidator: wordValidator,
        sessionCheckpointRepository: MemorySessionCheckpointRepository(),
      );

      // Select only 2 cells.
      controller.startSelection(session.cellAt(row: 0, column: 0));
      controller.extendSelection(session.cellAt(row: 0, column: 1));

      await controller.endSelection();

      expect(controller.lastInvalidFeedback, isNotNull);
      expect(
        controller.lastInvalidFeedback!.reason,
        WordValidationReason.tooShort,
      );
      expect(controller.movesLeft, 9);
      expect(controller.selectedCellIds, isEmpty);
    });

    test('valid word also decrements remaining moves by 1', () async {
      // Place 'BAL' at positions (0,0), (0,1), (0,2).
      final GameSession session = _buildSession(
        letters: <String>['B', 'A', 'L', 'X', 'Y', 'Z', 'W', 'Q', 'P'],
        movesLeft: 20,
      );

      final GameController controller = GameController.fromSession(
        session,
        wordValidator: wordValidator,
        sessionCheckpointRepository: MemorySessionCheckpointRepository(),
      );

      controller.startSelection(session.cellAt(row: 0, column: 0));
      controller.extendSelection(session.cellAt(row: 0, column: 1));
      controller.extendSelection(session.cellAt(row: 0, column: 2));

      await controller.endSelection();

      expect(controller.movesLeft, 19);
    });

    test('valid word clears selection and has no invalid feedback', () async {
      final GameSession session = _buildSession(
        letters: <String>['B', 'A', 'L', 'X', 'Y', 'Z', 'W', 'Q', 'P'],
        movesLeft: 20,
      );

      final GameController controller = GameController.fromSession(
        session,
        wordValidator: wordValidator,
        sessionCheckpointRepository: MemorySessionCheckpointRepository(),
      );

      controller.startSelection(session.cellAt(row: 0, column: 0));
      controller.extendSelection(session.cellAt(row: 0, column: 1));
      controller.extendSelection(session.cellAt(row: 0, column: 2));

      await controller.endSelection();

      expect(controller.selectedCellIds, isEmpty);
      expect(controller.lastInvalidFeedback, isNull);
    });

    test('starting a new selection clears previous invalid feedback', () async {
      final GameSession session = _buildSession(
        letters: <String>['X', 'Y', 'Z', 'W', 'Q', 'P', 'R', 'S', 'T'],
        movesLeft: 10,
      );

      final GameController controller = GameController.fromSession(
        session,
        wordValidator: wordValidator,
        sessionCheckpointRepository: MemorySessionCheckpointRepository(),
      );

      // First: invalid attempt.
      controller.startSelection(session.cellAt(row: 0, column: 0));
      controller.extendSelection(session.cellAt(row: 0, column: 1));
      controller.extendSelection(session.cellAt(row: 0, column: 2));
      await controller.endSelection();

      expect(controller.lastInvalidFeedback, isNotNull);

      // Second: start a new selection — feedback should clear.
      controller.startSelection(session.cellAt(row: 1, column: 0));

      expect(controller.lastInvalidFeedback, isNull);
    });

    test('endSelection with empty selection does nothing', () async {
      final GameSession session = _buildSession(
        letters: <String>['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'],
        movesLeft: 10,
      );

      final GameController controller = GameController.fromSession(
        session,
        wordValidator: wordValidator,
        sessionCheckpointRepository: MemorySessionCheckpointRepository(),
      );

      // No selection started; endSelection should be a no-op.
      await controller.endSelection();

      expect(controller.movesLeft, 10);
      expect(controller.lastInvalidFeedback, isNull);
    });

    test('multiple invalid attempts accumulate move decrements', () async {
      final GameSession session = _buildSession(
        letters: <String>['X', 'Y', 'Z', 'W', 'Q', 'P', 'R', 'S', 'T'],
        movesLeft: 5,
      );

      final GameController controller = GameController.fromSession(
        session,
        wordValidator: wordValidator,
        sessionCheckpointRepository: MemorySessionCheckpointRepository(),
      );

      // First invalid attempt.
      controller.startSelection(session.cellAt(row: 0, column: 0));
      controller.extendSelection(session.cellAt(row: 0, column: 1));
      controller.extendSelection(session.cellAt(row: 0, column: 2));
      await controller.endSelection();
      expect(controller.movesLeft, 4);

      // Second invalid attempt.
      controller.startSelection(session.cellAt(row: 1, column: 0));
      controller.extendSelection(session.cellAt(row: 1, column: 1));
      controller.extendSelection(session.cellAt(row: 1, column: 2));
      await controller.endSelection();
      expect(controller.movesLeft, 3);
    });
  });
}

GameSession _buildSession({required List<String> letters, int movesLeft = 20}) {
  // Always build a 3x3 grid — 9 cells required.
  assert(letters.length == 9);

  const int gridSize = 3;
  final GameConfig config = GameConfig(
    difficulty: GameDifficulty.medium,
    difficultyLabel: 'Orta',
    gridSize: gridSize,
    moveLimit: movesLeft,
  );

  return GameSession(
    config: config,
    board: List<BoardCell>.generate(
      gridSize * gridSize,
      (int index) => BoardCell(
        row: index ~/ gridSize,
        column: index % gridSize,
        letter: letters[index],
      ),
      growable: false,
    ),
    movesLeft: movesLeft,
  );
}
