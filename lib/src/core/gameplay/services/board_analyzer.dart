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

/// Analyzes a game board for the existence of at least one valid word.
///
/// Uses a trie built from the dictionary for prefix pruning, combined
/// with DFS + backtracking over the board's adjacency graph. The
/// analysis enforces gameplay rules:
/// - Each cell may be used at most once per path.
/// - Adjacent cells share a row/column delta of at most 1
///   (8-directional adjacency).
/// - Words must be at least [minWordLength] characters long.
///
/// The analyzer short-circuits as soon as any valid word is found,
/// making it efficient for the initial-session solvability check.
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

    // Build a 2D index for O(1) cell lookups by (row, column).
    final List<List<BoardCell>> grid = List<List<BoardCell>>.generate(
      gridSize,
      (int row) => board
          .where((BoardCell cell) => cell.row == row)
          .toList(growable: false),
      growable: false,
    );

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

  /// Recursive DFS with backtracking.
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
