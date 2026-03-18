import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/keyboard/kiosk_text_field.dart';
import 'player_profile.dart';
import 'player_repository.dart';

class PlayerEditView extends StatefulWidget {
  const PlayerEditView({
    super.key,
    required this.initialProfile,
    required this.onBack,
    required this.onSaved,
  });

  static const routeName = '/players/edit';

  final PlayerProfile initialProfile;
  final VoidCallback onBack;
  final void Function(PlayerProfile profile) onSaved;

  @override
  State<PlayerEditView> createState() => _PlayerEditViewState();
}

class _PlayerEditViewState extends State<PlayerEditView> {
  final _repo = PlayerRepository();
  late final TextEditingController _name;
  late final TextEditingController _song;
  String? _photoPath;
  bool _saving = false;
  bool _takingPhoto = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialProfile.name);
    _song = TextEditingController(text: widget.initialProfile.entrySong ?? '');
    _photoPath = widget.initialProfile.photoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _song.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_takingPhoto || _saving) return;
    setState(() => _takingPhoto = true);
    if (!mounted) return;
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamera integroidaan myöhemmin tähän kohtaan.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _takingPhoto = false);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final profile = PlayerProfile(
      id: widget.initialProfile.id,
      name: name,
      entrySong: _song.text.trim().isEmpty ? null : _song.text.trim(),
      photoPath: _photoPath,
      createdAt: widget.initialProfile.createdAt,
    );
    try {
      await _repo
          .upsert(profile)
          .timeout(const Duration(seconds: 6), onTimeout: () => throw Exception('DB timeout'));
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onSaved(profile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tallennus epäonnistui: $e')),
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
                    onPressed: _saving ? null : widget.onBack,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Takaisin'),
                  ),
                  const Spacer(),
                  Text(
                    'Muokkaa käyttäjää',
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
                    KioskTextField(
                      controller: _name,
                      enabled: !_saving,
                      title: 'Nimi',
                      maxLength: 30,
                    ),
                    const SizedBox(height: 12),
                    KioskTextField(
                      controller: _song,
                      enabled: !_saving,
                      title: 'Sisääntulo biisi (vapaaehtoinen)',
                      maxLength: 40,
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
                            image: _photoPath != null &&
                                    _photoPath!.trim().isNotEmpty &&
                                    File(_photoPath!).existsSync()
                                ? DecorationImage(
                                    image: FileImage(File(_photoPath!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _photoPath == null || _photoPath!.trim().isEmpty
                              ? Icon(Icons.person, color: cs.onSurfaceVariant)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: (_saving || _takingPhoto) ? null : _takePhoto,
                            icon: const Icon(Icons.photo_camera, size: 18),
                            label: Text(_takingPhoto ? 'Avaa kamera...' : 'Vaihda kuva'),
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
                      : const Text('Tallenna'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

