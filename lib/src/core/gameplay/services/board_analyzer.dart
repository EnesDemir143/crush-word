import 'dart:collection';

import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/repositories/dictionary_repository.dart';

/// A compact trie node used for prefix-based dictionary lookups.
///
/// Each node stores its children in a [HashMap] keyed by character.
/// [isTerminal] marks whether the path from root to this node
/// represents a complete dictionary word.
class _TrieNode {
  final HashMap<String, _TrieNode> children = HashMap<String, _TrieNode>();
  bool isTerminal = false;
}

/// A word found on the board along with the cell IDs it occupies.
///
/// Used by [BoardAnalyzer.findAllPlayableWords] to collect every
/// valid word path, and later by [countNonOverlappingWords] to
/// compute the maximum number of independent words.
class PlayableWord {
  const PlayableWord({required this.word, required this.cellIds});

  /// The normalised word string.
  final String word;

  /// Ordered cell IDs that form this word on the board.
  final List<String> cellIds;

  /// Cell IDs as a set for fast overlap checks.
  Set<String> get cellIdSet => <String>{...cellIds};
}

/// Analyzes a game board for the existence of valid words.
///
/// Uses a trie built from the dictionary for prefix pruning, combined
/// with DFS + backtracking over the board's adjacency graph. The
/// analysis enforces gameplay rules:
/// - Each cell may be used at most once per path.
/// - Adjacent cells share a row/column delta of at most 1
///   (8-directional adjacency).
/// - Words must be at least [minWordLength] characters long.
///
/// The analyzer supports both short-circuit checks
/// ([hasPlayableWord]) and exhaustive enumeration
/// ([findAllPlayableWords]).
class BoardAnalyzer {
  BoardAnalyzer({this.minWordLength = 3});

  /// Minimum character count for a word to be accepted.
  final int minWordLength;

  /// Builds a trie from the given [words] set and checks whether
  /// the [board] contains at least one valid word.
  ///
  /// Returns `true` as soon as the first valid word is discovered.
  /// Returns `false` only after exhaustively confirming no word
  /// exists on the board.
  bool hasPlayableWord({
    required List<BoardCell> board,
    required int gridSize,
    required Set<String> words,
  }) {
    if (board.isEmpty || words.isEmpty) {
      return false;
    }

    final _TrieNode root = _buildTrie(words);
    final List<List<BoardCell>> grid = _buildGrid(board, gridSize);

    // Start a DFS from every cell on the board.
    final Set<String> visited = <String>{};

    for (final BoardCell startCell in board) {
      if (_dfs(
        grid: grid,
        gridSize: gridSize,
        cell: startCell,
        node: root,
        visited: visited,
        depth: 0,
      )) {
        return true;
      }
    }

    return false;
  }

  /// Finds all unique valid words on the [board].
  ///
  /// Returns a list of [PlayableWord] entries, each containing
  /// the word string and the cell IDs forming that word.
  /// The same word string may appear multiple times if it can
  /// be formed via different paths, but only one path per unique
  /// word string is kept (shortest path preferred).
  List<PlayableWord> findAllPlayableWords({
    required List<BoardCell> board,
    required int gridSize,
    required Set<String> words,
  }) {
    if (board.isEmpty || words.isEmpty) {
      return const <PlayableWord>[];
    }

    final _TrieNode root = _buildTrie(words);
    final List<List<BoardCell>> grid = _buildGrid(board, gridSize);

    // Collect all found words. Key by word string so the same
    // word is only stored once (keep the path with fewer cells).
    final Map<String, PlayableWord> found = <String, PlayableWord>{};
    final Set<String> visited = <String>{};
    final List<String> currentPath = <String>[];

    for (final BoardCell startCell in board) {
      _dfsCollect(
        grid: grid,
        gridSize: gridSize,
        cell: startCell,
        node: root,
        visited: visited,
        depth: 0,
        currentPath: currentPath,
        found: found,
      );
    }

    return found.values.toList(growable: false);
  }

  /// Counts the maximum number of non-overlapping words on the
  /// board — words that do not share any cells.
  ///
  /// Uses a greedy algorithm: sort found words by cell count
  /// (ascending) and greedily pick words whose cells don't
  /// overlap with already selected words.
  int countNonOverlappingWords({
    required List<BoardCell> board,
    required int gridSize,
    required Set<String> words,
  }) {
    final List<PlayableWord> allWords = findAllPlayableWords(
      board: board,
      gridSize: gridSize,
      words: words,
    );

    if (allWords.isEmpty) {
      return 0;
    }

    // Sort by cell count ascending — shorter words first
    // to maximise the number of independent words.
    final List<PlayableWord> sorted = List<PlayableWord>.of(allWords)
      ..sort(
        (PlayableWord a, PlayableWord b) =>
            a.cellIds.length.compareTo(b.cellIds.length),
      );

    final Set<String> usedCells = <String>{};
    int count = 0;

    for (final PlayableWord pw in sorted) {
      final Set<String> wordCells = pw.cellIdSet;

      if (wordCells.intersection(usedCells).isEmpty) {
        usedCells.addAll(wordCells);
        count++;
      }
    }

    return count;
  }

  // ── Private helpers ──────────────────────────────────────────

  /// Builds a 2D index for O(1) cell lookups by (row, column).
  List<List<BoardCell>> _buildGrid(List<BoardCell> board, int gridSize) {
    return List<List<BoardCell>>.generate(
      gridSize,
      (int row) => board
          .where((BoardCell cell) => cell.row == row)
          .toList(growable: false),
      growable: false,
    );
  }

  /// Recursive DFS with backtracking — short-circuit variant.
  ///
  /// Traverses the board using 8-directional adjacency while
  /// simultaneously walking the trie. If the current prefix
  /// does not exist in the trie, the branch is pruned immediately.
  bool _dfs({
    required List<List<BoardCell>> grid,
    required int gridSize,
    required BoardCell cell,
    required _TrieNode node,
    required Set<String> visited,
    required int depth,
  }) {
    final String letter = DictionaryRepository.normalizeWord(cell.letter);

    // Prefix pruning: if the letter has no child in the trie,
    // this entire branch is a dead end.
    final _TrieNode? childNode = node.children[letter];

    if (childNode == null) {
      return false;
    }

    final int currentDepth = depth + 1;

    // If we've reached a terminal node with sufficient length,
    // we found a valid word — short-circuit immediately.
    if (childNode.isTerminal && currentDepth >= minWordLength) {
      return true;
    }

    // Mark the cell as visited to prevent revisiting.
    visited.add(cell.id);

    // Explore all 8-directional neighbors.
    for (int dRow = -1; dRow <= 1; dRow++) {
      for (int dCol = -1; dCol <= 1; dCol++) {
        if (dRow == 0 && dCol == 0) {
          continue;
        }

        final int neighborRow = cell.row + dRow;
        final int neighborCol = cell.column + dCol;

        if (neighborRow < 0 ||
            neighborRow >= gridSize ||
            neighborCol < 0 ||
            neighborCol >= gridSize) {
          continue;
        }

        final BoardCell neighbor = grid[neighborRow][neighborCol];

        if (visited.contains(neighbor.id)) {
          continue;
        }

        if (_dfs(
          grid: grid,
          gridSize: gridSize,
          cell: neighbor,
          node: childNode,
          visited: visited,
          depth: currentDepth,
        )) {
          // Propagate the short-circuit without cleaning up —
          // we're done.
          return true;
        }
      }
    }

    // Backtrack: unmark the cell so other paths may use it.
    visited.remove(cell.id);

    return false;
  }

  /// Recursive DFS with backtracking — exhaustive variant.
  ///
  /// Collects every valid word path into [found]. Keeps only one
  /// path per unique word string (the one with fewest cells).
  void _dfsCollect({
    required List<List<BoardCell>> grid,
    required int gridSize,
    required BoardCell cell,
    required _TrieNode node,
    required Set<String> visited,
    required int depth,
    required List<String> currentPath,
    required Map<String, PlayableWord> found,
  }) {
    final String letter = DictionaryRepository.normalizeWord(cell.letter);

    final _TrieNode? childNode = node.children[letter];

    if (childNode == null) {
      return;
    }

    final int currentDepth = depth + 1;

    // Mark the cell as visited and add to current path.
    visited.add(cell.id);
    currentPath.add(cell.id);

    // Record a valid word if terminal and long enough.
    if (childNode.isTerminal && currentDepth >= minWordLength) {
      final String word = currentPath
          .map((String cellId) => _cellByIdFromGrid(grid, gridSize, cellId))
          .map((BoardCell c) => DictionaryRepository.normalizeWord(c.letter))
          .join();

      final PlayableWord? existing = found[word];
      if (existing == null ||
          currentPath.length < existing.cellIds.length) {
        found[word] = PlayableWord(
          word: word,
          cellIds: List<String>.of(currentPath),
        );
      }
    }

    // Continue exploring — don't short-circuit so we find all words.
    for (int dRow = -1; dRow <= 1; dRow++) {
      for (int dCol = -1; dCol <= 1; dCol++) {
        if (dRow == 0 && dCol == 0) {
          continue;
        }

        final int neighborRow = cell.row + dRow;
        final int neighborCol = cell.column + dCol;

        if (neighborRow < 0 ||
            neighborRow >= gridSize ||
            neighborCol < 0 ||
            neighborCol >= gridSize) {
          continue;
        }

        final BoardCell neighbor = grid[neighborRow][neighborCol];

        if (visited.contains(neighbor.id)) {
          continue;
        }

        _dfsCollect(
          grid: grid,
          gridSize: gridSize,
          cell: neighbor,
          node: childNode,
          visited: visited,
          depth: currentDepth,
          currentPath: currentPath,
          found: found,
        );
      }
    }

    // Backtrack: unmark the cell and remove from path.
    visited.remove(cell.id);
    currentPath.removeLast();
  }

  /// Looks up a cell by its ID from the 2D grid.
  BoardCell _cellByIdFromGrid(
    List<List<BoardCell>> grid,
    int gridSize,
    String cellId,
  ) {
    final List<String> parts = cellId.split(':');
    final int row = int.parse(parts[0]);
    final int col = int.parse(parts[1]);
    return grid[row][col];
  }

  /// Constructs a trie from the given word set.
  ///
  /// Only words with length >= [minWordLength] are inserted,
  /// matching the gameplay minimum word rule.
  _TrieNode _buildTrie(Set<String> words) {
    final _TrieNode root = _TrieNode();

    for (final String word in words) {
      if (word.length < minWordLength) {
        continue;
      }

      _TrieNode current = root;

      for (int i = 0; i < word.length; i++) {
        final String char = word[i];
        current = current.children.putIfAbsent(char, _TrieNode.new);
      }

      current.isTerminal = true;
    }

    return root;
  }
}
