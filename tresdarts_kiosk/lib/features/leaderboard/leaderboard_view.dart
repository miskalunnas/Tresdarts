import 'package:flutter/material.dart';

import '../games/game_mode.dart';
import 'game_result.dart';
import 'leaderboard_repository.dart';

enum _LeaderboardTab { ranking, recent, stats }

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  static const routeName = '/leaderboard';

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  final _repo = LeaderboardRepository();
  List<GameResult> _results = [];
  List<LeaderboardEntry> _ranking = [];
  List<GameModeStats> _modeStats = [];
  List<LeaderboardEntry> _allPlayers = [];
  GameModeId? _filterMode;
  _LeaderboardTab _tab = _LeaderboardTab.ranking;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_tab == _LeaderboardTab.ranking) {
        final ranking = await _repo
            .getLeaderboardByWins(mode: _filterMode)
            .timeout(const Duration(seconds: 6), onTimeout: () => throw Exception('DB timeout'));
        if (!mounted) return;
        setState(() => _ranking = ranking);
      } else if (_tab == _LeaderboardTab.stats) {
        final modeStats = await _repo
            .getAllGameModeStats()
            .timeout(const Duration(seconds: 8), onTimeout: () => throw Exception('DB timeout'));
        final players = await _repo
            .getLeaderboardByWins(limit: 200)
            .timeout(const Duration(seconds: 6), onTimeout: () => throw Exception('DB timeout'));
        if (!mounted) return;
        setState(() {
          _modeStats = modeStats;
          _allPlayers = players;
        });
      } else {
        final results = await _repo
            .getResults(mode: _filterMode)
            .timeout(const Duration(seconds: 6), onTimeout: () => throw Exception('DB timeout'));
        if (!mounted) return;
        setState(() => _results = results);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Tulosten lataus epäonnistui.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tulosten lataus epäonnistui: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _modeTitle(GameModeId id) {
    final mode = GameMode.defaults.firstWhere(
      (m) => m.id == id,
      orElse: () => GameMode.x01,
    );
    return mode.title;
  }

  String _formatDate(DateTime d) {
    return '${d.day}.${d.month}.${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildLeaderboardBody(ColorScheme cs) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: cs.primary,
          strokeWidth: 2,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Yritä uudelleen'),
            ),
          ],
        ),
      );
    }
    if (_tab == _LeaderboardTab.stats) return _buildStatsContent(cs);
    if (_tab == _LeaderboardTab.ranking) {
      if (_ranking.isEmpty) {
        return Center(
          child: Text(
            'Ei tuloksia.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        );
      }
      return ListView.builder(
        itemCount: _ranking.length,
        itemBuilder: (context, index) {
          final e = _ranking[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onPrimaryContainer,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.playerName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${e.wins} / ${e.played} voittoa'
                            '${e.played > 0 ? ' (${(e.winRate * 100).toStringAsFixed(0)} %)' : ''}'
                            '${e.lastPlayed != null ? ' · Viim. ${_formatDate(e.lastPlayed!)}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
    // Viimeisimmät pelit
    if (_results.isEmpty) {
      return Center(
        child: Text(
          'Ei tuloksia.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final r = _results[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimaryContainer,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.winnerName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_modeTitle(r.gameModeId)} · ${r.players.join(', ')}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatDate(r.playedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsContent(ColorScheme cs) {
    return ListView(
      children: [
        Text(
          'Pelikohtaiset tilastot',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
        ),
        const SizedBox(height: 12),
        ..._modeStats.map((s) {
          final mode = GameMode.defaults.firstWhere(
            (m) => m.id == s.modeId,
            orElse: () => GameMode.x01,
          );
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${s.gamesPlayed} peliä · ${s.uniquePlayers} pelaajaa',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                if (s.topPlayers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...s.topPlayers.take(5).map((e) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${e.playerName}: ${e.wins} voittoa (${e.played} peliä)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                      )),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
        Text(
          'Käyttäjäkohtaiset tilastot',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Valitse pelaaja nähdäksesi tilastot per pelimuoto',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        ..._allPlayers.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outline),
              ),
              child: ListTile(
                title: Text(
                  e.playerName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                ),
                subtitle: Text(
                  '${e.wins} voittoa / ${e.played} peliä${e.played > 0 ? ' (${(e.winRate * 100).toStringAsFixed(0)} %)' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                onTap: () => _showUserStatsDialog(context, e.playerName, cs),
              ),
            )),
      ],
    );
  }

  Future<void> _showUserStatsDialog(BuildContext context, String playerName, ColorScheme cs) async {
    final stats = await _repo.getUserStats(playerName);
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(stats.playerName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yhteensä: ${stats.totalWins} voittoa / ${stats.totalPlayed} peliä'
                    '${stats.totalPlayed > 0 ? ' (${(stats.winRate * 100).toStringAsFixed(0)} % voittoja)' : ''}',
                style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
              ),
              if (stats.totalDarts > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'AVG (3): ${stats.avg3.toStringAsFixed(1)}',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              if (stats.lastPlayed != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Viimeisin peli: ${_formatDate(stats.lastPlayed!)}',
                  style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
              if (stats.byMode.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Per pelimuoto',
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                ...stats.byMode.entries.map((entry) {
                  final mode = GameMode.defaults.firstWhere(
                    (m) => m.id == entry.key,
                    orElse: () => GameMode.x01,
                  );
                  final m = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${mode.title}: ${m.wins} / ${m.played} (${m.played > 0 ? (m.winRate * 100).toStringAsFixed(0) : "0"} %)'
                      '${m.darts > 0 ? ' · AVG (3): ${m.avg3.toStringAsFixed(1)}' : ''}',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Sulje'),
          ),
        ],
      ),
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
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Takaisin'),
                  ),
                  const Spacer(),
                  Text(
                    'Tulokset',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _FilterChip(
                    label: 'Eniten voittoja',
                    selected: _tab == _LeaderboardTab.ranking,
                    onTap: () {
                      setState(() => _tab = _LeaderboardTab.ranking);
                      _load();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Viimeisimmät pelit',
                    selected: _tab == _LeaderboardTab.recent,
                    onTap: () {
                      setState(() => _tab = _LeaderboardTab.recent);
                      _load();
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Tilastot',
                    selected: _tab == _LeaderboardTab.stats,
                    onTap: () {
                      setState(() => _tab = _LeaderboardTab.stats);
                      _load();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_tab != _LeaderboardTab.stats)
                SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Kaikki',
                      selected: _filterMode == null,
                      onTap: () {
                        setState(() => _filterMode = null);
                        _load();
                      },
                    ),
                    const SizedBox(width: 8),
                    ...GameMode.defaults.map(
                      (mode) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: mode.title,
                          selected: _filterMode == mode.id,
                          onTap: () {
                            setState(() => _filterMode = mode.id);
                            _load();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _buildLeaderboardBody(cs),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? cs.primary : cs.outline,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: selected ? cs.onPrimaryContainer : cs.onSurface,
                ),
          ),
        ),
      ),
    );
  }
}
