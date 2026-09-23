import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/firebase_error_mapper.dart';
import '../../../../shared/models/app_user.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../providers/auth_providers.dart';
import '../providers/session_provider.dart';
import '../widgets/avatar_picker_sheet.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _upiController;
  late TextEditingController _bioController;

  String? _photoUrl;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _upiController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initFromUser(AppUser user) {
    _nameController = TextEditingController(text: user.name);
    _phoneController = TextEditingController(text: user.phone ?? '');
    _upiController = TextEditingController(text: user.upiId ?? '');
    _bioController = TextEditingController(text: user.bio ?? '');
    _photoUrl = user.photoUrl;
    _initialized = true;
  }

  Future<void> _pickAvatar() async {
    final currentName = _nameController.text.trim();
    final selected = await AvatarPickerSheet.show(
      context,
      currentAvatarUrl: _photoUrl,
      name: currentName.isNotEmpty ? currentName : 'User',
    );

    if (selected == null || !mounted) return;

    setState(() {
      _photoUrl = selected.isEmpty ? null : selected;
    });
  }

  Future<void> _save(AppUser user) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authActionsProvider.notifier).updateProfile(
            uid: user.id,
            name: _nameController.text.trim(),
            photoUrl: _photoUrl,
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
            upiId: _upiController.text.trim().isNotEmpty
                ? _upiController.text.trim()
                : null,
            bio: _bioController.text.trim().isNotEmpty
                ? _bioController.text.trim()
                : null,
            householdId: user.householdId,
          );

      ref.invalidate(currentUserProvider);
      ref.invalidate(sessionProvider);

      if (!mounted) return;
      showAppSnack(context, 'Profile updated successfully!');
      if (context.canPop()) {
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, FirebaseErrorMapper.messageFor(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = ref.watch(sessionProvider).value;
    final user = session?.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: Text('User profile not available')),
      );
    }

    if (!_initialized) {
      _initFromUser(user);
    }

    final isSaving = ref.watch(authActionsProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: isSaving ? null : () => _save(user),
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Avatar Section
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.5),
                          width: 2.5,
                        ),
                      ),
                      child: AppAvatar(
                        name: _nameController.text,
                        photoUrl: _photoUrl,
                        size: 96,
                        onTap: _pickAvatar,
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: _pickAvatar,
                  icon: const Icon(Icons.palette_outlined, size: 16),
                  label: const Text('Change Avatar'),
                ),
              ),
              const SizedBox(height: 24),

              // BASIC INFORMATION
              Text(
                'BASIC INFORMATION',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter your name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  if (val.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Email (Read-only)
              TextFormField(
                initialValue: user.email,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),
                  suffixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                  filled: true,
                  fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // CONTACT & ROOMMATE DETAILS
              Text(
                'ROOMMATE & PAYMENT DETAILS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'These help your flatmates contact you and repay your shared expenses directly.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone / WhatsApp Number (Optional)',
                  hintText: 'e.g. +92 300 1234567',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Handle / UPI ID
              TextFormField(
                controller: _upiController,
                decoration: const InputDecoration(
                  labelText: 'UPI ID / Payment Handle (Optional)',
                  hintText: 'e.g. name@okhdfcbank or 03001234567',
                  prefixIcon: Icon(Icons.payment_rounded),
                  border: OutlineInputBorder(),
                  helperText: 'Displayed to flatmates when settling shared expenses',
                ),
              ),
              const SizedBox(height: 16),

              // Bio / Room
              TextFormField(
                controller: _bioController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Room Number / Note (Optional)',
                  hintText: 'e.g. Room 204 • Vegetarian • Early riser',
                  prefixIcon: Icon(Icons.info_outline_rounded),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              FilledButton(
                onPressed: isSaving ? null : () => _save(user),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
