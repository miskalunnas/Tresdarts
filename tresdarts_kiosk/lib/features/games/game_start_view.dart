import 'package:flutter/material.dart';

import '../leaderboard/game_result.dart';
import '../leaderboard/leaderboard_repository.dart';
import '../games/game_mode.dart';
import '../players/player_profile.dart';

class GameStartView extends StatefulWidget {
  const GameStartView({
    super.key,
    required this.title,
    required this.players,
    required this.profiles,
    required this.onBack,
    required this.onStart,
  });

  static const routeName = '/game/start';

  final String title;
  final List<String> players;
  final List<PlayerProfile> profiles;
  final VoidCallback onBack;
  final void Function(bool entrySongsEnabled, List<PlayerProfile> profiles) onStart;

  @override
  State<GameStartView> createState() => _GameStartViewState();
}

class _GameStartViewState extends State<GameStartView> {
  bool _entrySongsEnabled = true;
  final _leaderboardRepo = LeaderboardRepository();
  List<GameResult> _h2hResults = [];
  bool _h2hLoading = false;

  bool get _hasAnyEntrySong =>
      widget.profiles.any((p) => p.entrySong != null && p.entrySong!.trim().isNotEmpty);

  bool get _is1v1NamedPair {
    if (widget.players.length != 2) return false;
    final a = widget.players[0].trim().toLowerCase();
    final b = widget.players[1].trim().toLowerCase();
    return !a.startsWith('vieras') && !b.startsWith('vieras');
  }

  @override
  void initState() {
    super.initState();
    if (_is1v1NamedPair) _loadH2h();
  }

  @override
  void didUpdateWidget(covariant GameStartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_is1v1NamedPair && (oldWidget.players.length != 2 ||
        oldWidget.players[0] != widget.players[0] ||
        oldWidget.players[1] != widget.players[1])) {
      _loadH2h();
    }
  }

  Future<void> _loadH2h() async {
    if (widget.players.length != 2) return;
    setState(() => _h2hLoading = true);
    final list = await _leaderboardRepo.getHeadToHead(
      widget.players[0],
      widget.players[1],
    );
    if (mounted) {
      setState(() {
        _h2hResults = list;
        _h2hLoading = false;
      });
    }
  }

  String _modeTitle(GameModeId id) {
    return GameMode.defaults
        .firstWhere((m) => m.id == id, orElse: () => GameMode.x01)
        .title;
  }

  String _formatDate(DateTime d) {
    return '${d.day}.${d.month}.${d.year}';
  }

  Widget _buildH2hSummary(ColorScheme cs) {
    final a = widget.players[0].trim();
    final b = widget.players[1].trim();
    final aKey = a.toLowerCase();
    final bKey = b.toLowerCase();
    var winsA = 0;
    var winsB = 0;
    for (final r in _h2hResults) {
      if (r.winnerName.trim().toLowerCase() == aKey) winsA++;
      if (r.winnerName.trim().toLowerCase() == bKey) winsB++;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          a,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '$winsA – $winsB',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
          ),
        ),
        Text(
          b,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Takaisin'),
                  ),
                  const Spacer(),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pelaajat',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final p in widget.players)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cs.outline),
                            ),
                            child: Text(
                              p,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: cs.onSurface,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_is1v1NamedPair) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keskinäiset ottelut',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                      ),
                      if (_h2hLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_h2hResults.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Ei aiemmin pelattuja keskinäisiä pelejä.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        )
                      else ...[
                        const SizedBox(height: 8),
                        _buildH2hSummary(cs),
                        const SizedBox(height: 12),
                        ..._h2hResults.take(10).map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '${_modeTitle(r.gameModeId)}: ${r.winnerName} voitti · ${_formatDate(r.playedAt)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ],
              if (_hasAnyEntrySong) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _entrySongsEnabled,
                          onChanged: (v) =>
                              setState(() => _entrySongsEnabled = v ?? true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sisääntulobiisit käyttöön (walkout)',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => widget.onStart(
                    _entrySongsEnabled && _hasAnyEntrySong,
                    widget.profiles,
                  ),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Aloita peli'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

