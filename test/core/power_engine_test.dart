import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:crush_word/src/core/config/game_rules_config.dart';
import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/services/board_generator.dart';
import 'package:crush_word/src/core/gameplay/services/board_resolver.dart';
import 'package:crush_word/src/core/gameplay/services/power_engine.dart';
import 'package:crush_word/src/core/models/power_tile.dart';

class _FixedRandom implements RandomSource {
  _FixedRandom(this.values);

  final List<int> values;
  int _index = 0;

  @override
  int nextInt(int max) {
    final int value = values[_index % values.length] % max;
    _index += 1;
    return value;
  }
}

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

PowerTileConfig _loadPowerConfig() {
  final Map<String, dynamic> rulesJson = Map<String, dynamic>.from(
    jsonDecode(File('assets/config/game_rules.json').readAsStringSync())
        as Map<dynamic, dynamic>,
  );

  return GameRulesConfig.fromJson(rulesJson).powerTiles!;
}

List<BoardCell> _board5x5({PowerTile? centerPower}) {
  const List<String> letters = <String>[
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'R',
    'S',
    'T',
    'U',
    'V',
    'Y',
    'Z',
    'Ç',
    'Ş',
  ];

  return List<BoardCell>.generate(25, (int index) {
    final int row = index ~/ 5;
    final int column = index % 5;
    return BoardCell(
      row: row,
      column: column,
      letter: letters[index],
      power: row == 2 && column == 2 ? centerPower : null,
    );
  }, growable: false);
}

Set<String> _removedIds(BoardResolveResult result) {
  return result.removedCells.map((BoardCell cell) => cell.id).toSet();
}

BoardCell _cellAt(List<BoardCell> board, int row, int column) {
  return board.firstWhere(
    (BoardCell cell) => cell.row == row && cell.column == column,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PowerEngine thresholds', () {
    test('canonical config maps 4/5/6/7+ to row/area/column/mega', () {
      final PowerEngine engine = PowerEngine(config: _loadPowerConfig());

      expect(engine.powerForWord(3), isNull);
      expect(engine.powerForWord(4)?.type, PowerTileType.rowClear);
      expect(engine.powerForWord(5)?.type, PowerTileType.areaBlast);
      expect(engine.powerForWord(6)?.type, PowerTileType.columnClear);
      expect(engine.powerForWord(7)?.type, PowerTileType.megaBlast);
      expect(engine.powerForWord(12)?.type, PowerTileType.megaBlast);
    });
  });

  group('BoardResolver power creation', () {
    test(
      'keeps the last selected letter in place and attaches power metadata',
      () {
        final BoardResolver resolver = BoardResolver(
          boardGenerator: BoardGenerator(randomSource: _FixedRandom(<int>[0])),
          powerEngine: PowerEngine(config: _loadPowerConfig()),
        );

        final List<BoardCell> board = <BoardCell>[
          const BoardCell(row: 0, column: 0, letter: 'A'),
          const BoardCell(row: 0, column: 1, letter: 'B'),
          const BoardCell(row: 0, column: 2, letter: 'C'),
          const BoardCell(row: 1, column: 0, letter: 'D'),
          const BoardCell(row: 1, column: 1, letter: 'E'),
          const BoardCell(row: 1, column: 2, letter: 'F'),
          const BoardCell(row: 2, column: 0, letter: 'G'),
          const BoardCell(row: 2, column: 1, letter: 'H'),
          const BoardCell(row: 2, column: 2, letter: 'I'),
        ];

        final BoardResolveResult result = resolver.resolve(
          board: board,
          selectedCellIds: const <String>['0:1', '2:1', '0:0', '1:1'],
          gridSize: 3,
          rules: _singleLetterRules('X'),
          wordLength: 4,
        );

        final BoardCell poweredCell = _cellAt(result.board, 1, 1);

        expect(result.createdPower?.type, PowerTileType.rowClear);
        expect(_removedIds(result), <String>{'0:1', '2:1', '0:0'});
        expect(poweredCell.letter, 'E');
        expect(poweredCell.power?.type, PowerTileType.rowClear);
        expect(_cellAt(result.board, 0, 1).letter, 'X');
        expect(_cellAt(result.board, 2, 1).letter, 'X');
      },
    );
  });

  group('BoardResolver power activation', () {
    late BoardResolver resolver;

    setUp(() {
      resolver = BoardResolver(
        boardGenerator: BoardGenerator(randomSource: _FixedRandom(<int>[0])),
        powerEngine: PowerEngine(config: _loadPowerConfig()),
      );
    });

    test('row power clears the full row through the resolver pipeline', () {
      final BoardResolveResult result = resolver.resolve(
        board: _board5x5(
          centerPower: const PowerTile(type: PowerTileType.rowClear),
        ),
        selectedCellIds: const <String>['2:2'],
        gridSize: 5,
        rules: _singleLetterRules('X'),
        wordLength: 3,
      );

      expect(_removedIds(result), <String>{'2:0', '2:1', '2:2', '2:3', '2:4'});
      expect(result.powerActivation?.activatedPowers, <PowerTileType>[
        PowerTileType.rowClear,
      ]);
      expect(_cellAt(result.board, 0, 2).letter, 'X');
    });

    test('area power clears adjacent cells around the powered tile', () {
      final BoardResolveResult result = resolver.resolve(
        board: _board5x5(
          centerPower: const PowerTile(type: PowerTileType.areaBlast),
        ),
        selectedCellIds: const <String>['2:2'],
        gridSize: 5,
        rules: _singleLetterRules('X'),
        wordLength: 3,
      );

      expect(_removedIds(result), <String>{
        '1:1',
        '1:2',
        '1:3',
        '2:1',
        '2:2',
        '2:3',
        '3:1',
        '3:2',
        '3:3',
      });
      expect(_cellAt(result.board, 0, 2).letter, 'X');
    });

    test(
      'column power clears the full column through the resolver pipeline',
      () {
        final BoardResolveResult result = resolver.resolve(
          board: _board5x5(
            centerPower: const PowerTile(type: PowerTileType.columnClear),
          ),
          selectedCellIds: const <String>['2:2'],
          gridSize: 5,
          rules: _singleLetterRules('X'),
          wordLength: 3,
        );

        expect(_removedIds(result), <String>{
          '0:2',
          '1:2',
          '2:2',
          '3:2',
          '4:2',
        });
        expect(_cellAt(result.board, 0, 2).letter, 'X');
      },
    );

    test(
      'mega power clears a radius-two area through the resolver pipeline',
      () {
        final BoardResolveResult result = resolver.resolve(
          board: _board5x5(
            centerPower: const PowerTile(type: PowerTileType.megaBlast),
          ),
          selectedCellIds: const <String>['2:2'],
          gridSize: 5,
          rules: _singleLetterRules('X'),
          wordLength: 3,
        );

        expect(_removedIds(result).length, 25);
        expect(_removedIds(result), hasLength(25));
        expect(_cellAt(result.board, 0, 0).letter, 'X');
        expect(_cellAt(result.board, 4, 4).letter, 'X');
      },
    );
  });
}
