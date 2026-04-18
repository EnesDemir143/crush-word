import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';

class LetterGrid extends StatefulWidget {
  const LetterGrid({
    super.key,
    required this.session,
    required this.selectedCellIds,
    required this.onSelectionStart,
    required this.onSelectionExtend,
    this.onSelectionEnd,
    this.lastRemovedCellIds = const <String>[],
  });

  final GameSession session;
  final List<String> selectedCellIds;
  final ValueChanged<BoardCell> onSelectionStart;
  final ValueChanged<BoardCell> onSelectionExtend;
  final VoidCallback? onSelectionEnd;

  /// Cell IDs that were just removed — triggers pop animation.
  final List<String> lastRemovedCellIds;

  @override
  State<LetterGrid> createState() => _LetterGridState();
}

class _LetterGridState extends State<LetterGrid> {
  String? _lastDraggedCellId;

  /// Tracks which cell IDs are "new" for entrance animation.
  Set<String> _animatingCellIds = <String>{};

  /// Incremented to give each board update a unique animation key.
  int _boardVersion = 0;

  @override
  void didUpdateWidget(covariant LetterGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When cells were removed, all cells on the new board are
    // candidates for entrance animation.
    if (widget.lastRemovedCellIds.isNotEmpty &&
        oldWidget.lastRemovedCellIds != widget.lastRemovedCellIds) {
      _boardVersion++;
      _animatingCellIds = widget.session.board
          .map((BoardCell c) => c.id)
          .toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Map<String, int> selectionOrder = <String, int>{
      for (int index = 0;
          index < widget.selectedCellIds.length;
          index += 1)
        widget.selectedCellIds[index]: index,
    };

    return Semantics(
      container: true,
      label:
          '${widget.session.gridSize} çarpı '
          '${widget.session.gridSize} oyun tahtası',
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            final _GridLayout gridLayout = _GridLayout.fromSession(
              session: widget.session,
              size: constraints.biggest,
            );

            return ClipRRect(
              borderRadius: BorderRadius.circular(
                gridLayout.outerRadius,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFFF7F1E5),
                      Color(0xFFE7D6BC),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(
                    gridLayout.outerRadius,
                  ),
                  border: Border.all(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.10),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(gridLayout.outerPadding),
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (PointerDownEvent event) {
                      _handleSelectionStart(
                        gridLayout.cellAtOffset(
                          event.localPosition,
                        ),
                      );
                    },
                    onPointerMove: (PointerMoveEvent event) {
                      _handleSelectionUpdate(
                        gridLayout.cellAtOffset(
                          event.localPosition,
                        ),
                      );
                    },
                    onPointerUp: (_) => _finishSelection(),
                    onPointerCancel: (_) => _finishSelection(),
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BoardTexturePainter(
                              gridLayout: gridLayout,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _SelectionPathPainter(
                              selectedCells: widget.session.board
                                  .where(
                                    (BoardCell cell) =>
                                        selectionOrder
                                            .containsKey(cell.id),
                                  )
                                  .toList(growable: false)
                                ..sort(
                                  (BoardCell l, BoardCell r) =>
                                      selectionOrder[l.id]!
                                          .compareTo(
                                            selectionOrder[r.id]!,
                                          ),
                                ),
                              gridLayout: gridLayout,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        for (final BoardCell cell
                            in widget.session.board)
                          Positioned.fromRect(
                            rect: gridLayout.rectFor(cell),
                            child: _AnimatedLetterCell(
                              key: Key(
                                'letter-cell-${cell.id}',
                              ),
                              cell: cell,
                              selectionIndex:
                                  selectionOrder[cell.id],
                              cellExtent: gridLayout.cellExtent,
                              showSelectionIndex:
                                  gridLayout.showSelectionIndex,
                              animate: _animatingCellIds
                                  .contains(cell.id),
                              boardVersion: _boardVersion,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleSelectionStart(BoardCell? cell) {
    if (cell == null) {
      return;
    }

    _lastDraggedCellId = cell.id;
    widget.onSelectionStart(cell);
  }

  void _handleSelectionUpdate(BoardCell? cell) {
    if (cell == null || cell.id == _lastDraggedCellId) {
      return;
    }

    _lastDraggedCellId = cell.id;
    widget.onSelectionExtend(cell);
  }

  void _finishSelection() {
    _lastDraggedCellId = null;
    widget.onSelectionEnd?.call();
  }
}

/// Wraps _LetterCell with a pop-in entrance animation.
class _AnimatedLetterCell extends StatelessWidget {
  const _AnimatedLetterCell({
    super.key,
    required this.cell,
    required this.selectionIndex,
    required this.cellExtent,
    required this.showSelectionIndex,
    required this.animate,
    required this.boardVersion,
  });

  final BoardCell cell;
  final int? selectionIndex;
  final double cellExtent;
  final bool showSelectionIndex;
  final bool animate;
  final int boardVersion;

  @override
  Widget build(BuildContext context) {
    if (!animate) {
      return _LetterCell(
        cell: cell,
        selectionIndex: selectionIndex,
        cellExtent: cellExtent,
        showSelectionIndex: showSelectionIndex,
      );
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('anim-${cell.id}-v$boardVersion'),
      duration: const Duration(milliseconds: 350),
      curve: Curves.elasticOut,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.scale(
            scale: value.clamp(0, 1),
            child: child,
          ),
        );
      },
      child: _LetterCell(
        cell: cell,
        selectionIndex: selectionIndex,
        cellExtent: cellExtent,
        showSelectionIndex: showSelectionIndex,
      ),
    );
  }
}

class _LetterCell extends StatelessWidget {
  const _LetterCell({
    required this.cell,
    required this.selectionIndex,
    required this.cellExtent,
    required this.showSelectionIndex,
  });

  final BoardCell cell;
  final int? selectionIndex;
  final double cellExtent;
  final bool showSelectionIndex;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isSelected = selectionIndex != null;
    final double borderRadius = math.max(10, cellExtent * 0.24);
    final double fontSize = (cellExtent * 0.46).clamp(14, 32);
    final double contentPadding = math.max(3, cellExtent * 0.08);

    return Semantics(
      button: true,
      label:
          'Satır ${cell.row + 1}, sütun ${cell.column + 1}, '
          '${cell.letter} harfi'
          '${isSelected ? ', seçili ${selectionIndex! + 1}. sıra' : ''}',
      child: AnimatedScale(
        scale: isSelected ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(contentPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? const <Color>[
                    Color(0xFF1D6D67),
                    Color(0xFF0F4E4A),
                  ]
                : const <Color>[
                    Color(0xFFFFFCF7),
                    Color(0xFFF2E6D5),
                  ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFE3A4)
                : theme.colorScheme.primary
                    .withValues(alpha: 0.08),
            width: isSelected ? 2.2 : 1.1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(
                alpha: isSelected ? 0.16 : 0.07,
              ),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  cell.letter,
                  maxLines: 1,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF2B2721),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
            if (isSelected && showSelectionIndex)
              Positioned(
                right: math.max(4, cellExtent * 0.08),
                top: math.max(4, cellExtent * 0.08),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          math.max(4, cellExtent * 0.08),
                      vertical:
                          math.max(2, cellExtent * 0.03),
                    ),
                    child: Text(
                      '${selectionIndex! + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize:
                            (cellExtent * 0.18).clamp(9, 13),
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

class _SelectionPathPainter extends CustomPainter {
  const _SelectionPathPainter({
    required this.selectedCells,
    required this.gridLayout,
    required this.color,
  });

  final List<BoardCell> selectedCells;
  final _GridLayout gridLayout;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedCells.length < 2) {
      return;
    }

    final Paint underlay = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth =
          math.max(6, gridLayout.cellExtent * 0.20)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint overlay = Paint()
      ..color = color.withValues(alpha: 0.42)
      ..strokeWidth =
          math.max(4, gridLayout.cellExtent * 0.12)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..moveTo(
        gridLayout.centerFor(selectedCells.first).dx,
        gridLayout.centerFor(selectedCells.first).dy,
      );

    for (final BoardCell cell in selectedCells.skip(1)) {
      final Offset center = gridLayout.centerFor(cell);
      path.lineTo(center.dx, center.dy);
    }

    canvas.drawPath(path, underlay);
    canvas.drawPath(path, overlay);
  }

  @override
  bool shouldRepaint(
    covariant _SelectionPathPainter oldDelegate,
  ) {
    return oldDelegate.selectedCells != selectedCells ||
        oldDelegate.gridLayout != gridLayout ||
        oldDelegate.color != color;
  }
}

class _BoardTexturePainter extends CustomPainter {
  const _BoardTexturePainter({
    required this.gridLayout,
    required this.color,
  });

  final _GridLayout gridLayout;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (int index = 1;
        index < gridLayout.session.gridSize;
        index += 1) {
      final double offset =
          index * (gridLayout.cellExtent + gridLayout.gap) -
              (gridLayout.gap / 2);
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, offset),
        Offset(size.width, offset),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _BoardTexturePainter oldDelegate,
  ) {
    return oldDelegate.gridLayout != gridLayout ||
        oldDelegate.color != color;
  }
}

class _GridLayout {
  _GridLayout({
    required this.session,
    required this.cellExtent,
    required this.gap,
    required this.outerPadding,
    required this.outerRadius,
    required this.showSelectionIndex,
    required Map<String, Rect> rects,
  }) : _rects = rects;

  factory _GridLayout.fromSession({
    required GameSession session,
    required Size size,
  }) {
    final int gridSize = session.gridSize;
    final double side = math.min(size.width, size.height);
    final double outerPadding = switch (gridSize) {
      <= 6 => 12.0,
      <= 8 => 8.0,
      _ => 4.0,
    };
    final double gap = switch (gridSize) {
      <= 6 => 8.0,
      <= 8 => 5.0,
      _ => 2.0,
    };
    final double usableSide = side - (outerPadding * 2);
    final double cellExtent =
        (usableSide - (gap * (gridSize - 1))) / gridSize;
    final Map<String, Rect> rects = <String, Rect>{
      for (final BoardCell cell in session.board)
        cell.id: Rect.fromLTWH(
          cell.column * (cellExtent + gap),
          cell.row * (cellExtent + gap),
          cellExtent,
          cellExtent,
        ),
    };

    return _GridLayout(
      session: session,
      cellExtent: cellExtent,
      gap: gap,
      outerPadding: outerPadding,
      outerRadius: switch (gridSize) {
        <= 6 => 30.0,
        <= 8 => 26.0,
        _ => 22.0,
      },
      showSelectionIndex: gridSize < 10,
      rects: rects,
    );
  }

  final GameSession session;
  final double cellExtent;
  final double gap;
  final double outerPadding;
  final double outerRadius;
  final bool showSelectionIndex;
  final Map<String, Rect> _rects;

  Rect rectFor(BoardCell cell) => _rects[cell.id]!;

  Offset centerFor(BoardCell cell) => rectFor(cell).center;

  BoardCell? cellAtOffset(Offset offset) {
    for (final BoardCell cell in session.board) {
      if (rectFor(cell).contains(offset)) {
        return cell;
      }
    }

    return null;
  }

  @override
  bool operator ==(Object other) {
    return other is _GridLayout &&
        other.session == session &&
        other.cellExtent == cellExtent &&
        other.gap == gap &&
        other.outerPadding == outerPadding &&
        other.outerRadius == outerRadius &&
        other.showSelectionIndex == showSelectionIndex;
  }

  @override
  int get hashCode => Object.hash(
    session,
    cellExtent,
    gap,
    outerPadding,
    outerRadius,
    showSelectionIndex,
  );
}
