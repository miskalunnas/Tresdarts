import 'dart:io';

import 'package:flutter/material.dart';

import 'player_profile.dart';
import 'player_repository.dart';

class PlayerCreateView extends StatefulWidget {
  const PlayerCreateView({
    super.key,
    required this.onBack,
    required this.onCreated,
  });

  static const routeName = '/players/create';

  final VoidCallback onBack;
  final void Function(PlayerProfile profile) onCreated;

  @override
  State<PlayerCreateView> createState() => _PlayerCreateViewState();
}

class _PlayerCreateViewState extends State<PlayerCreateView> {
  final _repo = PlayerRepository();
  final _name = TextEditingController();
  final _song = TextEditingController();
  String? _photoPath;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _song.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    // Placeholder for camera integration (Pi): for now we just show UI and keep it optional.
    // If a file path is already set (e.g. by future integration), we can display it.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kamera integroidaan myöhemmin tähän kohtaan.'),
      ),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final profile = PlayerProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      entrySong: _song.text.trim().isEmpty ? null : _song.text.trim(),
      photoPath: _photoPath,
      createdAt: DateTime.now(),
    );
    await _repo.upsert(profile);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onCreated(profile);
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
                    onPressed: _saving ? null : widget.onBack,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Takaisin'),
                  ),
                  const Spacer(),
                  Text(
                    'Uusi käyttäjä',
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
                    TextField(
                      controller: _name,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Nimi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _song,
                      enabled: !_saving,
                      decoration: const InputDecoration(
                        labelText: 'Sisääntulo biisi (vapaaehtoinen)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cs.outline),
                            image: _photoPath != null && File(_photoPath!).existsSync()
                                ? DecorationImage(
                                    image: FileImage(File(_photoPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _photoPath == null
                              ? Icon(Icons.person, color: cs.onSurfaceVariant)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _takePhoto,
                            icon: const Icon(Icons.photo_camera, size: 18),
                            label: const Text('Ota profiilikuva'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Luo käyttäjä'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

