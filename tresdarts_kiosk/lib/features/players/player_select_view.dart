import 'package:flutter/material.dart';

import '../../core/keyboard/kiosk_text_field.dart';
import 'player_profile.dart';
import 'player_repository.dart';

class PlayerSelectView extends StatefulWidget {
  const PlayerSelectView({
    super.key,
    required this.title,
    this.minPlayers = 1,
    this.maxPlayers = 8,
    required this.onBack,
    required this.onContinue,
    required this.onCreateNew,
  });

  final String title;
  final int minPlayers;
  final int maxPlayers;
  final VoidCallback onBack;
  final void Function(List<PlayerProfile> players) onContinue;
  /// Creates a new user; returns the created profile so it can be auto-selected.
  final Future<PlayerProfile?> Function() onCreateNew;

  @override
  State<PlayerSelectView> createState() => _PlayerSelectViewState();
}

class _PlayerSelectViewState extends State<PlayerSelectView> {
  final _repo = PlayerRepository();
  List<PlayerProfile> _players = [];
  final List<PlayerProfile> _selected = [];
  bool _loading = true;
  String? _error;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _guestCounter = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final players = await _repo.getPlayers().timeout(
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

  List<PlayerProfile> get _filteredPlayers {
    if (_searchQuery.isEmpty) return _players;
    return _players
        .where((p) => p.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  void _toggle(PlayerProfile p) {
    setState(() {
      final idx = _selected.indexWhere((x) => x.id == p.id);
      if (idx >= 0) {
        _selected.removeAt(idx);
      } else {
        if (_selected.length >= widget.maxPlayers) return;
        _selected.add(p);
      }
    });
  }

  Future<void> _handleCreateNew() async {
    if (_selected.length >= widget.maxPlayers) return;
    final profile = await widget.onCreateNew();
    if (profile != null && mounted && _selected.length < widget.maxPlayers) {
      setState(() => _selected.add(profile));
    }
  }

  void _addGuest() {
    if (_selected.length >= widget.maxPlayers) return;
    // Guests are not persisted; they still show up in result players list.
    final now = DateTime.now();
    final next = ++_guestCounter;
    final name = next == 1 ? 'Vieras' : 'Vieras $next';
    final guest = PlayerProfile(
      id: 'guest-${now.microsecondsSinceEpoch}-$next',
      name: name,
      entrySong: null,
      photoPath: null,
      createdAt: now,
    );
    setState(() => _selected.add(guest));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filteredPlayers;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
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
                  KioskTextField(
                    controller: _searchController,
                    title: 'Haku',
                    hintText: 'Hae pelaajaa...',
                    maxLength: 30,
                    decoration: InputDecoration(
                      hintText: 'Hae pelaajaa...',
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outline),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Valitse ${widget.minPlayers}–${widget.maxPlayers} pelaaja(a) '
                            '(${_selected.length}/${widget.maxPlayers})',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _load,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Päivitä'),
                        ),
                      ],
                    ),
                  ),
                  if (_selected.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
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
                            'Valitut',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final p in _selected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: cs.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: cs.outline),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        p.name,
                                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                              color: cs.onSurface,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _toggle(p),
                                        child: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ]),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
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
                ),
              )
            else if (_players.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Ei pelaajia vielä.\nLuo uusi käyttäjä tai pelaa vieraana.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'Ei pelaajia.'
                        : 'Ei tuloksia haulla „$_searchQuery".',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = filtered[index];
                      final selected = _selected.any((x) => x.id == p.id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? cs.primary : cs.outline,
                          ),
                        ),
                        child: ListTile(
                          onTap: () => _toggle(p),
                          title: Text(
                            p.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                          ),
                          subtitle: p.entrySong == null || p.entrySong!.trim().isEmpty
                              ? null
                              : Text(
                                  'Sisääntulo: ${p.entrySong}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                ),
                          trailing: selected ? Icon(Icons.check, color: cs.primary) : null,
                        ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _selected.length >= widget.maxPlayers ? null : _handleCreateNew,
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text('Uusi käyttäjä'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _addGuest,
                            child: const Text('Lisää vieras'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _selected.length >= widget.minPlayers
                          ? () => widget.onContinue([..._selected])
                          : null,
                      child: const Text('Jatka'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

