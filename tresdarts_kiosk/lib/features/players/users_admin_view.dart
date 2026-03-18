import 'package:flutter/material.dart';

import '../../core/keyboard/kiosk_text_field.dart';
import '../leaderboard/leaderboard_repository.dart';
import 'player_edit_view.dart';
import 'player_profile.dart';
import 'player_repository.dart';

class UsersAdminView extends StatefulWidget {
  const UsersAdminView({super.key});

  static const routeName = '/settings/users';

  @override
  State<UsersAdminView> createState() => _UsersAdminViewState();
}

class _UsersAdminViewState extends State<UsersAdminView> {
  final _playerRepo = PlayerRepository();
  final _leaderboardRepo = LeaderboardRepository();
  final _search = TextEditingController();

  List<PlayerProfile> _players = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final players = await _playerRepo.getPlayers().timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('DB timeout'),
          );
      if (!mounted) return;
      setState(() {
        _players = players;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Käyttäjien lataus epäonnistui.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Käyttäjien lataus epäonnistui: $e')),
      );
    }
  }

  List<PlayerProfile> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _players;
    return _players.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _edit(PlayerProfile p) async {
    final edited = await Navigator.of(context).push<PlayerProfile>(
      MaterialPageRoute(
        builder: (_) => PlayerEditView(
          initialProfile: p,
          onBack: () => Navigator.of(context).pop(),
          onSaved: (pp) => Navigator.of(context).pop(pp),
        ),
      ),
    );
    if (!mounted) return;
    if (edited == null) return;
    setState(() {
      final idx = _players.indexWhere((x) => x.id == edited.id);
      if (idx >= 0) _players[idx] = edited;
    });
  }

  Future<void> _delete(PlayerProfile p) async {
    final cs = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Poista käyttäjä?'),
        content: Text('Poistetaanko käyttäjä "${p.name}"?\n\nTulokset anonymisoidaan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Peruuta'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Poista'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _leaderboardRepo.anonymizePlayer(p.name);
      await _playerRepo.deleteById(p.id);
      if (!mounted) return;
      setState(() {
        _players.removeWhere((x) => x.id == p.id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Poisto epäonnistui: $e')),
      );
    }
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
                    'Käyttäjät',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              KioskTextField(
                controller: _search,
                title: 'Haku',
                hintText: 'Hae käyttäjää...',
                maxLength: 30,
                decoration: InputDecoration(
                  hintText: 'Hae käyttäjää...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: _load,
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Yritä uudelleen'),
                                ),
                              ],
                            ),
                          )
                        : _filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'Ei käyttäjiä.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filtered.length,
                                itemBuilder: (context, i) {
                                  final p = _filtered[i];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: cs.outline),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        p.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                      ),
                                      subtitle: (p.entrySong == null ||
                                              p.entrySong!.trim().isEmpty)
                                          ? null
                                          : Text(
                                              'Sisääntulo: ${p.entrySong}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                            ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Muokkaa',
                                            onPressed: () => _edit(p),
                                            icon: Icon(Icons.edit, color: cs.onSurfaceVariant),
                                          ),
                                          IconButton(
                                            tooltip: 'Poista',
                                            onPressed: () => _delete(p),
                                            icon: Icon(Icons.delete_outline, color: cs.error),
                                          ),
                                        ],
                                      ),
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

