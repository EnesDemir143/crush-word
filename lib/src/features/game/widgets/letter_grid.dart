import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:crush_word/src/core/gameplay/models/board_cell.dart';
import 'package:crush_word/src/core/gameplay/models/game_session.dart';
import 'package:crush_word/src/core/models/power_tile.dart';

class LetterGrid extends StatefulWidget {
  const LetterGrid({
    super.key,
    required this.session,
    required this.selectedCellIds,
    required this.onSelectionStart,
    required this.onSelectionExtend,
    this.onSelectionEnd,
    this.lastRemovedCellIds = const <String>[],
    this.effectToken = 0,
    this.comboCount = 0,
    this.createdPower,
    this.activatedPowers = const <PowerTileType>[],
  });

  final GameSession session;
  final List<String> selectedCellIds;
  final ValueChanged<BoardCell> onSelectionStart;
  final ValueChanged<BoardCell> onSelectionExtend;
  final VoidCallback? onSelectionEnd;

  /// Cell IDs that were just removed — triggers pop animation.
  final List<String> lastRemovedCellIds;

  /// Monotonic token incremented after each resolved board effect.
  final int effectToken;

  /// Combo intensity for the last resolved word.
  final int comboCount;

  /// The power tile created by the last resolved word, if any.
  final PowerTile? createdPower;

  /// Power effects activated by the last resolved word, if any.
  final List<PowerTileType> activatedPowers;

  @override
  State<LetterGrid> createState() => _LetterGridState();
}

class _LetterGridState extends State<LetterGrid> {
  String? _lastDraggedCellId;

  /// Tracks freshly spawned refill tiles so they can drop in from above.
  Set<String> _spawningCellAnimationIds = <String>{};

  Timer? _overlayResetTimer;
  _GridEffectOverlayData? _effectOverlay;

  @override
  void didUpdateWidget(covariant LetterGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.effectToken != oldWidget.effectToken) {
      final Set<String> previousAnimationIds = oldWidget.session.board
          .map((BoardCell cell) => cell.animationId)
          .toSet();
      _spawningCellAnimationIds = widget.session.board
          .map((BoardCell cell) => cell.animationId)
          .where((String id) => !previousAnimationIds.contains(id))
          .toSet();
    }

    if (widget.effectToken != oldWidget.effectToken &&
        widget.lastRemovedCellIds.isNotEmpty) {
      _showEffectOverlay(oldWidget);
    }
  }

  @override
  void dispose() {
    _overlayResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Map<String, int> selectionOrder = <String, int>{
      for (int index = 0; index < widget.selectedCellIds.length; index += 1)
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
          builder: (BuildContext context, BoxConstraints constraints) {
            final _GridLayout gridLayout = _GridLayout.fromSession(
              session: widget.session,
              size: constraints.biggest,
            );
            final Map<String, int> spawnDepthByAnimationId =
                _buildSpawnDepthByAnimationId();

            return ClipRRect(
              borderRadius: BorderRadius.circular(gridLayout.outerRadius),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFFF7F1E5), Color(0xFFE7D6BC)],
                  ),
                  borderRadius: BorderRadius.circular(gridLayout.outerRadius),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(gridLayout.outerPadding),
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (PointerDownEvent event) {
                      _handleSelectionStart(
                        gridLayout.cellAtOffset(event.localPosition),
                      );
                    },
                    onPointerMove: (PointerMoveEvent event) {
                      _handleSelectionUpdate(
                        gridLayout.cellAtOffset(event.localPosition),
                      );
                    },
                    onPointerUp: (_) => _finishSelection(),
                    onPointerCancel: (_) => _finishSelection(),
                    child: Stack(
                      clipBehavior: Clip.none,
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
                              selectedCells:
                                  widget.session.board
                                      .where(
                                        (BoardCell cell) =>
                                            selectionOrder.containsKey(cell.id),
                                      )
                                      .toList(growable: false)
                                    ..sort(
                                      (BoardCell left, BoardCell right) =>
                                          selectionOrder[left.id]!.compareTo(
                                            selectionOrder[right.id]!,
                                          ),
                                    ),
                              gridLayout: gridLayout,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        for (final BoardCell cell in widget.session.board)
                          AnimatedPositioned(
                            key: ValueKey<String>(
                              'board-item-${cell.animationId}',
                            ),
                            duration: Duration(
                              milliseconds: 420 + (widget.comboCount * 40),
                            ),
                            curve: Curves.easeInOutCubic,
                            left: gridLayout.rectFor(cell).left,
                            top: gridLayout.rectFor(cell).top,
                            width: gridLayout.rectFor(cell).width,
                            height: gridLayout.rectFor(cell).height,
                            child: _AnimatedLetterCell(
                              key: Key('letter-cell-${cell.id}'),
                              cell: cell,
                              selectionIndex: selectionOrder[cell.id],
                              cellExtent: gridLayout.cellExtent,
                              cellGap: gridLayout.gap,
                              showSelectionIndex: gridLayout.showSelectionIndex,
                              animateSpawn: _spawningCellAnimationIds.contains(
                                cell.animationId,
                              ),
                              spawnDepth:
                                  spawnDepthByAnimationId[cell.animationId] ??
                                  0,
                              comboCount: widget.comboCount,
                            ),
                          ),
                        if (_effectOverlay != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: _GridEffectOverlay(
                                data: _effectOverlay!,
                                gridLayout: gridLayout,
                              ),
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

  void _showEffectOverlay(LetterGrid oldWidget) {
    final Map<String, BoardCell> oldBoardById = <String, BoardCell>{
      for (final BoardCell cell in oldWidget.session.board) cell.id: cell,
    };
    final List<BoardCell> removedCells = widget.lastRemovedCellIds
        .map((String id) => oldBoardById[id])
        .whereType<BoardCell>()
        .toList(growable: false);
    final List<BoardCell> selectedCells = oldWidget.selectedCellIds
        .map((String id) => oldBoardById[id])
        .whereType<BoardCell>()
        .toList(growable: false);
    final List<_ActivatedPowerOverlay> activatedEffects = selectedCells
        .where((BoardCell cell) => cell.power != null)
        .where(
          (BoardCell cell) =>
              widget.activatedPowers.isEmpty ||
              widget.activatedPowers.contains(cell.power!.type),
        )
        .map(
          (BoardCell cell) =>
              _ActivatedPowerOverlay(anchor: cell, powerType: cell.power!.type),
        )
        .toList(growable: false);

    BoardCell? creationAnchor;
    if (widget.createdPower != null && oldWidget.selectedCellIds.isNotEmpty) {
      creationAnchor = oldBoardById[oldWidget.selectedCellIds.last];
    }

    _overlayResetTimer?.cancel();
    setState(() {
      _effectOverlay = _GridEffectOverlayData(
        token: widget.effectToken,
        removedCells: removedCells,
        comboCount: widget.comboCount,
        createdPower: widget.createdPower,
        creationAnchor: creationAnchor,
        activatedPowers: activatedEffects,
      );
    });
    _overlayResetTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted || _effectOverlay?.token != widget.effectToken) {
        return;
      }
      setState(() {
        _effectOverlay = null;
      });
    });
  }

  Map<String, int> _buildSpawnDepthByAnimationId() {
    final List<BoardCell> newCells =
        widget.session.board
            .where(
              (BoardCell cell) =>
                  _spawningCellAnimationIds.contains(cell.animationId),
            )
            .toList(growable: false)
          ..sort((BoardCell left, BoardCell right) {
            final int columnCompare = left.column.compareTo(right.column);
            if (columnCompare != 0) {
              return columnCompare;
            }
            return left.row.compareTo(right.row);
          });

    final Map<int, int> seenByColumn = <int, int>{};
    final Map<String, int> spawnDepthByAnimationId = <String, int>{};

    for (final BoardCell cell in newCells) {
      final int nextDepth = (seenByColumn[cell.column] ?? 0) + 1;
      seenByColumn[cell.column] = nextDepth;
      spawnDepthByAnimationId[cell.animationId] = nextDepth;
    }

    return spawnDepthByAnimationId;
  }
}

/// Wraps [_LetterCell] with a more tactile spawn animation.
class _AnimatedLetterCell extends StatelessWidget {
  const _AnimatedLetterCell({
    super.key,
    required this.cell,
    required this.selectionIndex,
    required this.cellExtent,
    required this.cellGap,
    required this.showSelectionIndex,
    required this.animateSpawn,
    required this.spawnDepth,
    required this.comboCount,
  });

  final BoardCell cell;
  final int? selectionIndex;
  final double cellExtent;
  final double cellGap;
  final bool showSelectionIndex;
  final bool animateSpawn;
  final int spawnDepth;
  final int comboCount;

  @override
  Widget build(BuildContext context) {
    final Widget child = _LetterCell(
      cell: cell,
      selectionIndex: selectionIndex,
      cellExtent: cellExtent,
      showSelectionIndex: showSelectionIndex,
    );

    if (!animateSpawn || spawnDepth <= 0) {
      return child;
    }

    final double dropDistance = (cellExtent + cellGap) * (spawnDepth + 0.4);

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('spawn-${cell.animationId}'),
      duration: Duration(milliseconds: 520 + (comboCount * 60)),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (BuildContext context, double value, Widget? child) {
        final double delayedProgress = Curves.easeOutCubic.transform(
          Interval(0.12, 1).transform(value.clamp(0, 1)),
        );
        final double opacity = (0.55 + (delayedProgress * 0.45)).clamp(0, 1);
        final double translateY = (1 - delayedProgress) * -dropDistance;
        final double scale = 0.92 + (delayedProgress * 0.08);
        final double glowOpacity = (1 - delayedProgress).clamp(0, 1) * 0.20;
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Opacity(
              opacity: glowOpacity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    math.max(10, cellExtent * 0.24),
                  ),
                  gradient: const RadialGradient(
                    colors: <Color>[
                      Color(0xFFF9E0A6),
                      Color(0x33F9E0A6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, translateY),
                child: Transform.scale(scale: scale, child: child),
              ),
            ),
          ],
        );
      },
      child: child,
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
    final bool hasPower = cell.power != null;
    final double borderRadius = math.max(10, cellExtent * 0.24);
    final double fontSize = (cellExtent * 0.46).clamp(14, 32);
    final double contentPadding = math.max(3, cellExtent * 0.08);
    final Color? powerColor = hasPower ? _powerColorFor(cell.power!) : null;

    return Semantics(
      button: true,
      label:
          'Satır ${cell.row + 1}, sütun ${cell.column + 1}, '
          '${cell.letter} harfi'
          '${isSelected ? ', seçili ${selectionIndex! + 1}. sıra' : ''}'
          '${hasPower ? ', ${_powerLabelFor(cell.power!)} gücü var' : ''}',
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
                  ? const <Color>[Color(0xFF1D6D67), Color(0xFF0F4E4A)]
                  : hasPower
                  ? <Color>[
                      Color.lerp(const Color(0xFFFFFCF7), powerColor!, 0.12)!,
                      Color.lerp(const Color(0xFFF2E6D5), powerColor, 0.08)!,
                    ]
                  : const <Color>[Color(0xFFFFFCF7), Color(0xFFF2E6D5)],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFE3A4)
                  : hasPower
                  ? powerColor!.withValues(alpha: 0.5)
                  : theme.colorScheme.primary.withValues(alpha: 0.08),
              width: isSelected
                  ? 2.2
                  : hasPower
                  ? 2.0
                  : 1.1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color:
                    (hasPower && !isSelected
                            ? powerColor!
                            : const Color(0xFF0F172A))
                        .withValues(alpha: isSelected ? 0.16 : 0.07),
                blurRadius: isSelected
                    ? 14
                    : hasPower
                    ? 12
                    : 8,
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
                        horizontal: math.max(4, cellExtent * 0.08),
                        vertical: math.max(2, cellExtent * 0.03),
                      ),
                      child: Text(
                        '${selectionIndex! + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: (cellExtent * 0.18).clamp(9, 13),
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              if (hasPower && !isSelected)
                Positioned(
                  left: math.max(2, cellExtent * 0.04),
                  bottom: math.max(2, cellExtent * 0.04),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: powerColor!.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: powerColor.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(math.max(2, cellExtent * 0.06)),
                      child: Icon(
                        _powerIconFor(cell.power!),
                        size: (cellExtent * 0.22).clamp(8, 16),
                        color: Colors.white,
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

class _GridEffectOverlayData {
  const _GridEffectOverlayData({
    required this.token,
    required this.removedCells,
    required this.comboCount,
    required this.createdPower,
    required this.creationAnchor,
    required this.activatedPowers,
  });

  final int token;
  final List<BoardCell> removedCells;
  final int comboCount;
  final PowerTile? createdPower;
  final BoardCell? creationAnchor;
  final List<_ActivatedPowerOverlay> activatedPowers;

  PowerTileType? get primaryPowerType {
    if (activatedPowers.isNotEmpty) {
      return activatedPowers.last.powerType;
    }
    return createdPower?.type;
  }
}

class _ActivatedPowerOverlay {
  const _ActivatedPowerOverlay({required this.anchor, required this.powerType});

  final BoardCell anchor;
  final PowerTileType powerType;
}

class _GridEffectOverlay extends StatelessWidget {
  const _GridEffectOverlay({required this.data, required this.gridLayout});

  final _GridEffectOverlayData data;
  final _GridLayout gridLayout;

  @override
  Widget build(BuildContext context) {
    final Color accent = _accentFor(
      data.primaryPowerType,
      comboCount: data.comboCount,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        for (final _ActivatedPowerOverlay effect in data.activatedPowers)
          _PowerSweepOverlay(
            key: ValueKey<String>(
              'power-sweep-${data.token}-${effect.anchor.id}-${effect.powerType.name}',
            ),
            effect: effect,
            gridLayout: gridLayout,
            comboCount: data.comboCount,
          ),
        for (final BoardCell cell in data.removedCells)
          Positioned.fromRect(
            rect: gridLayout.rectFor(cell),
            child: _CellBurstOverlay(
              key: ValueKey<String>('cell-burst-${data.token}-${cell.id}'),
              cellExtent: gridLayout.cellExtent,
              color: accent,
              comboCount: data.comboCount,
            ),
          ),
        if (data.creationAnchor != null && data.createdPower != null)
          Positioned.fromRect(
            rect: gridLayout.rectFor(data.creationAnchor!),
            child: _CreatedPowerPulseOverlay(
              key: ValueKey<String>(
                'created-power-${data.token}-${data.creationAnchor!.id}',
              ),
              cellExtent: gridLayout.cellExtent,
              powerType: data.createdPower!.type,
              comboCount: data.comboCount,
            ),
          ),
        if (data.comboCount > 1)
          Align(
            alignment: Alignment.topCenter,
            child: _ComboBanner(
              key: ValueKey<String>('combo-banner-${data.token}'),
              comboCount: data.comboCount,
              accent: accent,
            ),
          ),
      ],
    );
  }
}

class _CellBurstOverlay extends StatelessWidget {
  const _CellBurstOverlay({
    super.key,
    required this.cellExtent,
    required this.color,
    required this.comboCount,
  });

  final double cellExtent;
  final Color color;
  final int comboCount;

  @override
  Widget build(BuildContext context) {
    final int streakCount = 6 + comboCount.clamp(0, 5);
    final double maxScale = 1.15 + (comboCount * 0.08);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 440 + (comboCount * 70)),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        final double fadeOut = (1 - value).clamp(0, 1);
        final double ringScale = 0.25 + (value * maxScale);

        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.scale(
              scale: ringScale,
              child: Opacity(
                opacity: fadeOut * 0.9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        color.withValues(alpha: 0.88),
                        color.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SizedBox.square(dimension: cellExtent),
                ),
              ),
            ),
            for (int index = 0; index < streakCount; index += 1)
              Transform.rotate(
                angle: (math.pi * 2 / streakCount) * index,
                child: Transform.translate(
                  offset: Offset(0, -cellExtent * 0.18 * value),
                  child: Opacity(
                    opacity: fadeOut,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: math.max(2, cellExtent * 0.06),
                        height: cellExtent * (0.17 + (comboCount * 0.01)),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Colors.white,
                              color.withValues(alpha: 0.18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CreatedPowerPulseOverlay extends StatelessWidget {
  const _CreatedPowerPulseOverlay({
    super.key,
    required this.cellExtent,
    required this.powerType,
    required this.comboCount,
  });

  final double cellExtent;
  final PowerTileType powerType;
  final int comboCount;

  @override
  Widget build(BuildContext context) {
    final Color color = _accentFor(powerType, comboCount: comboCount);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 780),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double value, Widget? child) {
        final double fadeOut = (1 - value).clamp(0, 1);
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Transform.scale(
              scale: 0.4 + (value * 1.6),
              child: Opacity(
                opacity: fadeOut * 0.48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.8),
                      width: 3,
                    ),
                  ),
                  child: SizedBox.square(dimension: cellExtent),
                ),
              ),
            ),
            Opacity(
              opacity: 0.95 - (value * 0.45),
              child: Icon(
                _powerIconFor(PowerTile(type: powerType)),
                color: color,
                size: cellExtent * 0.34,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PowerSweepOverlay extends StatelessWidget {
  const _PowerSweepOverlay({
    super.key,
    required this.effect,
    required this.gridLayout,
    required this.comboCount,
  });

  final _ActivatedPowerOverlay effect;
  final _GridLayout gridLayout;
  final int comboCount;

  @override
  Widget build(BuildContext context) {
    final Rect cellRect = gridLayout.rectFor(effect.anchor);
    final Color color = _accentFor(effect.powerType, comboCount: comboCount);

    return switch (effect.powerType) {
      PowerTileType.rowClear => _DirectionalSweep(
        horizontal: true,
        top: cellRect.top - (gridLayout.gap / 2),
        left: 0,
        extent: gridLayout.cellExtent + gridLayout.gap,
        crossExtent: _boardExtent(gridLayout),
        color: color,
      ),
      PowerTileType.columnClear => _DirectionalSweep(
        horizontal: false,
        top: 0,
        left: cellRect.left - (gridLayout.gap / 2),
        extent: _boardExtent(gridLayout),
        crossExtent: gridLayout.cellExtent + gridLayout.gap,
        color: color,
      ),
      PowerTileType.areaBlast => _CircularBlastOverlay(
        center: cellRect.center,
        radius: gridLayout.cellExtent * 1.8,
        color: color,
        durationMs: 520,
      ),
      PowerTileType.megaBlast => _CircularBlastOverlay(
        center: cellRect.center,
        radius: gridLayout.cellExtent * 3.2,
        color: color,
        durationMs: 720,
      ),
    };
  }
}

class _DirectionalSweep extends StatelessWidget {
  const _DirectionalSweep({
    required this.horizontal,
    required this.top,
    required this.left,
    required this.extent,
    required this.crossExtent,
    required this.color,
  });

  final bool horizontal;
  final double top;
  final double left;
  final double extent;
  final double crossExtent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      width: horizontal ? crossExtent : extent,
      height: horizontal ? extent : crossExtent,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double value, Widget? child) {
          final Alignment begin = horizontal
              ? Alignment.centerLeft
              : Alignment.topCenter;
          final Alignment end = horizontal
              ? Alignment.centerRight
              : Alignment.bottomCenter;
          final AlignmentGeometry alignment = Alignment.lerp(
            begin,
            end,
            value,
          )!;

          return Stack(
            children: <Widget>[
              Opacity(
                opacity: (1 - value) * 0.65,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: horizontal
                          ? Alignment.centerLeft
                          : Alignment.topCenter,
                      end: horizontal
                          ? Alignment.centerRight
                          : Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        color.withValues(alpha: 0.14),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: alignment,
                child: Opacity(
                  opacity: 1 - (value * 0.4),
                  child: Container(
                    width: horizontal ? crossExtent * 0.18 : crossExtent,
                    height: horizontal ? extent : extent * 0.18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        begin: horizontal
                            ? Alignment.centerLeft
                            : Alignment.topCenter,
                        end: horizontal
                            ? Alignment.centerRight
                            : Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.white.withValues(alpha: 0.9),
                          color.withValues(alpha: 0.95),
                          color.withValues(alpha: 0.1),
                        ],
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CircularBlastOverlay extends StatelessWidget {
  const _CircularBlastOverlay({
    required this.center,
    required this.radius,
    required this.color,
    required this.durationMs,
  });

  final Offset center;
  final double radius;
  final Color color;
  final int durationMs;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - radius,
      top: center.dy - radius,
      width: radius * 2,
      height: radius * 2,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: durationMs),
        curve: Curves.easeOutCubic,
        builder: (BuildContext context, double value, Widget? child) {
          final double fadeOut = (1 - value).clamp(0, 1);
          return Transform.scale(
            scale: 0.2 + (value * 1.1),
            child: Opacity(
              opacity: fadeOut * 0.95,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      color.withValues(alpha: 0.82),
                      color.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: fadeOut * 0.9),
                    width: 2.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ComboBanner extends StatelessWidget {
  const _ComboBanner({
    super.key,
    required this.comboCount,
    required this.accent,
  });

  final int comboCount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: (1 - ((value - 0.72).clamp(0, 0.28) / 0.28)).clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, -18 + (value * 18)),
            child: Transform.scale(scale: 0.78 + (value * 0.22), child: child),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: <Color>[Colors.white, accent.withValues(alpha: 0.18)],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accent.withValues(alpha: 0.22),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              'COMBO x$comboCount',
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _powerColorFor(PowerTile power) {
  return _accentFor(power.type, comboCount: 1);
}

IconData _powerIconFor(PowerTile power) {
  return switch (power.type) {
    PowerTileType.rowClear => Icons.swap_horiz_rounded,
    PowerTileType.areaBlast => Icons.blur_on_rounded,
    PowerTileType.columnClear => Icons.swap_vert_rounded,
    PowerTileType.megaBlast => Icons.all_out_rounded,
  };
}

String _powerLabelFor(PowerTile power) {
  return switch (power.type) {
    PowerTileType.rowClear => 'satır temizleme',
    PowerTileType.areaBlast => 'alan patlatma',
    PowerTileType.columnClear => 'sütun temizleme',
    PowerTileType.megaBlast => 'mega patlatma',
  };
}

Color _accentFor(PowerTileType? type, {required int comboCount}) {
  final Color base = switch (type) {
    PowerTileType.rowClear => const Color(0xFFF39C12),
    PowerTileType.areaBlast => const Color(0xFFE74C3C),
    PowerTileType.columnClear => const Color(0xFF3498DB),
    PowerTileType.megaBlast => const Color(0xFF9B59B6),
    null => comboCount > 1 ? const Color(0xFFF5B041) : const Color(0xFFE8A13D),
  };

  if (comboCount <= 1) {
    return base;
  }

  return Color.lerp(base, Colors.white, comboCount.clamp(0, 5) * 0.08)!;
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
      ..strokeWidth = math.max(6, gridLayout.cellExtent * 0.20)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint overlay = Paint()
      ..color = color.withValues(alpha: 0.42)
      ..strokeWidth = math.max(4, gridLayout.cellExtent * 0.12)
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
  bool shouldRepaint(covariant _SelectionPathPainter oldDelegate) {
    return oldDelegate.selectedCells != selectedCells ||
        oldDelegate.gridLayout != gridLayout ||
        oldDelegate.color != color;
  }
}

class _BoardTexturePainter extends CustomPainter {
  const _BoardTexturePainter({required this.gridLayout, required this.color});

  final _GridLayout gridLayout;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (int index = 1; index < gridLayout.session.gridSize; index += 1) {
      final double offset =
          index * (gridLayout.cellExtent + gridLayout.gap) -
          (gridLayout.gap / 2);
      canvas.drawLine(Offset(offset, 0), Offset(offset, size.height), paint);
      canvas.drawLine(Offset(0, offset), Offset(size.width, offset), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardTexturePainter oldDelegate) {
    return oldDelegate.gridLayout != gridLayout || oldDelegate.color != color;
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
    final double cellExtent = (usableSide - (gap * (gridSize - 1))) / gridSize;
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

double _boardExtent(_GridLayout layout) {
  return (layout.cellExtent * layout.session.gridSize) +
      (layout.gap * (layout.session.gridSize - 1));
}
