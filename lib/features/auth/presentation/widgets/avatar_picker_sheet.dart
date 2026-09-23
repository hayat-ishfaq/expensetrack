import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_avatar.dart';

class AvatarPickerSheet extends StatefulWidget {
  const AvatarPickerSheet({
    super.key,
    required this.currentAvatarUrl,
    required this.name,
  });

  final String? currentAvatarUrl;
  final String name;

  static Future<String?> show(
    BuildContext context, {
    required String? currentAvatarUrl,
    required String name,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AvatarPickerSheet(
        currentAvatarUrl: currentAvatarUrl,
        name: name,
      ),
    );
  }

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet> {
  late String? _selected;
  late TextEditingController _urlController;
  bool _showCustomUrl = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentAvatarUrl;
    final isCustomUrl = _selected != null &&
        _selected!.startsWith('http') &&
        AppAvatars.findPreset(_selected) == null;
    _urlController = TextEditingController(text: isCustomUrl ? _selected : '');
    _showCustomUrl = isCustomUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choose Avatar',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Current Preview
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.primary,
                      width: 2.5,
                    ),
                  ),
                  child: AppAvatar(
                    name: widget.name,
                    photoUrl: _selected,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reset to Initials chip
              Center(
                child: ActionChip(
                  avatar: const Icon(Icons.text_fields_rounded, size: 16),
                  label: const Text('Use My Initials'),
                  backgroundColor: _selected == null || _selected!.isEmpty
                      ? scheme.primaryContainer
                      : scheme.surfaceContainerHigh,
                  side: BorderSide(
                    color: _selected == null || _selected!.isEmpty
                        ? scheme.primary
                        : Colors.transparent,
                  ),
                  onPressed: () {
                    setState(() {
                      _selected = null;
                      _urlController.clear();
                      _showCustomUrl = false;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'PRESET AVATARS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),

              // Avatar Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: AppAvatars.presets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final preset = AppAvatars.presets[index];
                  final isSelected = _selected == preset.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selected = preset.id;
                        _showCustomUrl = false;
                        _urlController.clear();
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? scheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: preset.gradientColors,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              preset.emoji,
                              style: const TextStyle(fontSize: 28, height: 1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preset.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Custom Photo URL Toggle
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.link_rounded),
                title: const Text('Use Custom Image URL'),
                subtitle: const Text('Paste a link from Google, Discord, etc.'),
                trailing: Switch(
                  value: _showCustomUrl,
                  onChanged: (val) {
                    setState(() {
                      _showCustomUrl = val;
                      if (!val && _selected?.startsWith('http') == true) {
                        _selected = null;
                      }
                    });
                  },
                ),
              ),

              if (_showCustomUrl) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'Image URL (https://...)',
                    hintText: 'https://example.com/avatar.png',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      onPressed: () {
                        final text = _urlController.text.trim();
                        if (text.startsWith('http')) {
                          setState(() {
                            _selected = text;
                          });
                        }
                      },
                    ),
                  ),
                  onChanged: (val) {
                    if (val.trim().startsWith('http')) {
                      setState(() {
                        _selected = val.trim();
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Select Avatar',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
