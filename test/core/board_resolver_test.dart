import 'package:flutter_test/flutter_test.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/services/board_generator.dart';
import 'package:crush_word/src/core/gameplay/services/board_resolver.dart';

// ──────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────

/// Deterministic random source that cycles through [values].
class _FixedRandom implements RandomSource {
  _FixedRandom(this.values);

  final List<int> values;
  int _index = 0;

  @override
  int nextInt(int max) {
    final int value = values[_index % values.length] % max;
    _index++;
    return value;
  }
}

/// Minimal frequency rules for refill: single group with one
/// letter so newly filled cells are deterministic.
GameBoardGenerationRules _singleLetterRules(String letter) {
  return GameBoardGenerationRules(
    letterFrequencyGroups: <LetterFrequencyGroup>[
      LetterFrequencyGroup(
        tier: LetterFrequencyTier.high,
        weight: 1,
        letters: <String>[letter],
      ),
    ],
  );
}

/// Build a flat 3×3 board from a 2D letter matrix.
List<BoardCell> _board3x3(List<List<String>> rows) {
  final List<BoardCell> cells = <BoardCell>[];
  for (int row = 0; row < 3; row++) {
    for (int col = 0; col < 3; col++) {
      cells.add(BoardCell(row: row, column: col, letter: rows[row][col]));
    }
  }
  return cells;
}

/// Convenience to pick a cell's letter by row/col from a flat
/// board list.
String _letterAt(List<BoardCell> board, int row, int col) {
  return board
      .firstWhere((BoardCell c) => c.row == row && c.column == col)
      .letter;
}

// ──────────────────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────────────────

void main() {
  group('BoardResolver', () {
    test('removes selected cells from the board', () {
      //  A B C
      //  D E F
      //  G H I
      final List<BoardCell> board = _board3x3(<List<String>>[
        <String>['A', 'B', 'C'],
        <String>['D', 'E', 'F'],
        <String>['G', 'H', 'I'],
      ]);

      // Remove center cell E (1:1).
      final BoardResolver resolver = BoardResolver(
        boardGenerator: BoardGenerator(randomSource: _FixedRandom(<int>[0])),
      );
      final GameBoardGenerationRules rules = _singleLetterRules('X');

      final BoardResolveResult result = resolver.resolve(
        board: board,
        selectedCellIds: <String>['1:1'],
        gridSize: 3,
        rules: rules,
      );

      expect(result.removedCells.length, 1);
      expect(result.removedCells.first.letter, 'E');
      // The board should still have 9 cells.
      expect(result.board.length, 9);
    });

    test('gravity collapses column downward', () {
      //  A B C         X B C     ← X is refill
      //  D E F   →     A E F     ← D dropped from row 1
      //  G H I         G H I
      //
      // Remove D (1:0). Column 0 had [A, D, G]. After removing D
      // the surviving [A, G] should collapse: G stays at row 2,
      // A moves to row 1, and a new letter fills row 0.
      final List<BoardCell> board = _board3x3(<List<String>>[
        <String>['A', 'B', 'C'],
        <String>['D', 'E', 'F'],
        <String>['G', 'H', 'I'],
      ]);

      final BoardResolver resolver = BoardResolver(
        boardGenerator: BoardGenerator(randomSource: _FixedRandom(<int>[0])),
      );
      final GameBoardGenerationRules rules = _singleLetterRules('X');

      final BoardResolveResult result = resolver.resolve(
        board: board,
        selectedCellIds: <String>['1:0'],
        gridSize: 3,
        rules: rules,
      );

      // Column 0 after gravity:
      //   row 0: X (refill)
      //   row 1: A (was row 0)
      //   row 2: G (was row 2, unchanged)
      expect(_letterAt(result.board, 0, 0), 'X');
      expect(_letterAt(result.board, 1, 0), 'A');
      expect(_letterAt(result.board, 2, 0), 'G');

      // Other columns unchanged.
      expect(_letterAt(result.board, 0, 1), 'B');
      expect(_letterAt(result.board, 1, 1), 'E');
      expect(_letterAt(result.board, 2, 1), 'H');
    });

    test('refills empty cells from top with new letters', () {
      //  A B C
      //  D E F
      //  G H I
      //
      // Remove top-left A (0:0). Column 0: [_, D, G].
      // After gravity: [_, D, G] → row0=refill, row1=D, row2=G.
      final List<BoardCell> board = _board3x3(<List<String>>[
        <String>['A', 'B', 'C'],
        <String>['D', 'E', 'F'],
        <String>['G', 'H', 'I'],
      ]);

      final BoardResolver resolver = BoardResolver(
        boardGenerator: BoardGenerator(randomSource: _FixedRandom(<int>[0])),
      );
      final GameBoardGenerationRules rules = _singleLetterRules('Z');

      final BoardResolveResult result = resolver.resolve(
        board: board,
        selectedCellIds: <String>['0:0'],
        gridSize: 3,
        rules: rules,
      );

      expect(_letterAt(result.board, 0, 0), 'Z');
      expect(_letterAt(result.board, 1, 0), 'D');
      expect(_letterAt(result.board, 2, 0), 'G');
    });

    test('multiple cells in same column collapse correctly', () {
      //  A B C
      //  D E F
      //  G H I
      //
      // Remove A (0:0) and D (1:0) — two cells from column 0.
      // Column 0 surviving: [G]. After gravity: [refill, refill, G].
      final List<BoardCell> board = _board3x3(<List<String>>[
        <String>['A', 'B', 'C'],
        <String>['D', 'E', 'F'],
        <String>['G', 'H', 'I'],
      ]);

      final BoardResolver resolver = BoardResolver(
        boardGenerator: BoardGenerator(randomSource: _FixedRandom(<int>[0])),
      );
      final GameBoardGenerationRules rules = _singleLetterRules('N');

      final BoardResolveResult result = resolver.resolve(
        board: board,
        selectedCellIds: <String>['0:0', '1:0'],
        gridSize: 3,
        rules: rules,
      );

      expect(_letterAt(result.board, 0, 0), 'N');
      expect(_letterAt(result.board, 1, 0), 'N');
      expect(_letterAt(result.board, 2, 0), 'G');
    });

    test('cells across multiple columns resolve independently', () {
      //  A B C
      //  D E F
      //  G H I
      //
      // Remove B (0:1) and E (1:1) — column 1.
      // Also remove F (1:2)         — column 2.
      final List<BoardCell> board = _board3x3(<List<String>>[
        <String>['A', 'B', 'C'],
        <String>['D', 'E', 'F'],
        <String>['G', 'H', 'I'],
      ]);

      final BoardResolver resolver = BoardResolver(
        boardGenerator: BoardGenerator(randomSource: _FixedRandom(<int>[0])),
      );
      final GameBoardGenerationRules rules = _singleLetterRules('W');

      final BoardResolveResult result = resolver.resolve(
        board: board,
        selectedCellIds: <String>['0:1', '1:1', '1:2'],
        gridSize: 3,
        rules: rules,
      );

      // Column 0 untouched.
      expect(_letterAt(result.board, 0, 0), 'A');
      expect(_letterAt(result.board, 1, 0), 'D');
      expect(_letterAt(result.board, 2, 0), 'G');

      // Column 1: surviving [H], padded with 2 refills.
      expect(_letterAt(result.board, 0, 1), 'W');
      expect(_letterAt(result.board, 1, 1), 'W');
      expect(_letterAt(result.board, 2, 1), 'H');

      // Column 2: surviving [C, I], padded with 1 refill.
      expect(_letterAt(result.board, 0, 2), 'W');
      expect(_letterAt(result.board, 1, 2), 'C');
      expect(_letterAt(result.board, 2, 2), 'I');
    });

    test('removing bottom cell fills from top', () {
      //  A B C
      //  D E F
      //  G H I
      //
      // Remove bottom-right I (2:2).
      // Column 2: [C, F, _]. After gravity: [_, C, F] → refill at top.
      final List<BoardCell> board = _board3x3(<List<String>>[
        <String>['A', 'B', 'C'],
        <String>['D', 'E', 'F'],
        <String>['G', 'H', 'I'],
      ]);

      final BoardResolver resolver = BoardResolver(
        boardGenerator: BoardGenerator(randomSource: _FixedRandom(<int>[0])),
      );
      final GameBoardGenerationRules rules = _singleLetterRules('Q');

      final BoardResolveResult result = resolver.resolve(
        board: board,
        selectedCellIds: <String>['2:2'],
        gridSize: 3,
        rules: rules,
      );

      expect(_letterAt(result.board, 0, 2), 'Q');
      expect(_letterAt(result.board, 1, 2), 'C');
      expect(_letterAt(result.board, 2, 2), 'F');
    });

    test('board size remains gridSize² after resolution', () {
      final List<BoardCell> board = _board3x3(<List<String>>[
        <String>['A', 'B', 'C'],
        <String>['D', 'E', 'F'],
        <String>['G', 'H', 'I'],
      ]);

      final BoardResolver resolver = BoardResolver(
        boardGenerator: BoardGenerator(randomSource: _FixedRandom(<int>[0])),
      );
      final GameBoardGenerationRules rules = _singleLetterRules('X');

      final BoardResolveResult result = resolver.resolve(
        board: board,
        selectedCellIds: <String>['0:0', '1:1', '2:2'],
        gridSize: 3,
        rules: rules,
      );

      expect(result.board.length, 9);
    });

    test('cell coordinates are valid after resolution', () {
      final List<BoardCell> board = _board3x3(<List<String>>[
        <String>['A', 'B', 'C'],
        <String>['D', 'E', 'F'],
        <String>['G', 'H', 'I'],
      ]);

      final BoardResolver resolver = BoardResolver(
        boardGenerator: BoardGenerator(randomSource: _FixedRandom(<int>[0])),
      );
      final GameBoardGenerationRules rules = _singleLetterRules('X');

      final BoardResolveResult result = resolver.resolve(
        board: board,
        selectedCellIds: <String>['0:1', '1:0'],
        gridSize: 3,
        rules: rules,
      );

      // Every cell should have valid row/column in [0, 2].
      for (final BoardCell cell in result.board) {
        expect(cell.row, inInclusiveRange(0, 2));
        expect(cell.column, inInclusiveRange(0, 2));
      }

      // Each (row, col) pair should appear exactly once.
      final Set<String> ids = result.board.map((BoardCell c) => c.id).toSet();
      expect(ids.length, 9);
    });

    test('removedCells contains exactly the cleared cells', () {
      final List<BoardCell> board = _board3x3(<List<String>>[
        <String>['A', 'B', 'C'],
        <String>['D', 'E', 'F'],
        <String>['G', 'H', 'I'],
      ]);

      final BoardResolver resolver = BoardResolver(
        boardGenerator: BoardGenerator(randomSource: _FixedRandom(<int>[0])),
      );
      final GameBoardGenerationRules rules = _singleLetterRules('X');

      final BoardResolveResult result = resolver.resolve(
        board: board,
        selectedCellIds: <String>['0:0', '2:2'],
        gridSize: 3,
        rules: rules,
      );

      expect(result.removedCells.length, 2);
      final Set<String> removedLetters = result.removedCells
          .map((BoardCell c) => c.letter)
          .toSet();
      expect(removedLetters, containsAll(<String>['A', 'I']));
    });

    test('empty selection returns board unchanged', () {
      final List<BoardCell> board = _board3x3(<List<String>>[
        <String>['A', 'B', 'C'],
        <String>['D', 'E', 'F'],
        <String>['G', 'H', 'I'],
      ]);

      final BoardResolver resolver = BoardResolver(
        boardGenerator: BoardGenerator(randomSource: _FixedRandom(<int>[0])),
      );
      final GameBoardGenerationRules rules = _singleLetterRules('X');

      final BoardResolveResult result = resolver.resolve(
        board: board,
        selectedCellIds: <String>[],
        gridSize: 3,
        rules: rules,
      );

      // No cells removed, board letters unchanged.
      expect(result.removedCells, isEmpty);
      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          expect(_letterAt(result.board, row, col), _letterAt(board, row, col));
        }
      }
    });
  });
}
