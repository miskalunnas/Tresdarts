import 'package:flutter/material.dart';

import '../games/game_mode.dart';
import 'game_result.dart';
import 'leaderboard_repository.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  static const routeName = '/leaderboard';

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  final _repo = LeaderboardRepository();
  List<GameResult> _results = [];
  GameModeId? _filterMode;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await _repo.getResults(mode: _filterMode);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Takaisin'),
                  ),
                  const Spacer(),
                  Text(
                    'Tulokset',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Kaikki'),
                      selected: _filterMode == null,
                      onSelected: (_) {
                        setState(() => _filterMode = null);
                        _load();
                      },
                    ),
                    const SizedBox(width: 8),
                    ...GameMode.defaults.map(
                      (mode) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(mode.title),
                          selected: _filterMode == mode.id,
                          onSelected: (_) {
                            setState(() => _filterMode = mode.id);
                            _load();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              'Ei tuloksia.',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final r = _results[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: cs.outlineVariant.withValues(alpha: 0.6),
                                  ),
                                  color: cs.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: cs.primaryContainer
                                            .withValues(alpha: 0.8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: cs.onPrimaryContainer,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r.winnerName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          Text(
                                            '${_modeTitle(r.gameModeId)} · ${r.players.join(', ')}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            _formatDate(r.playedAt),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(color: cs.outline),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
