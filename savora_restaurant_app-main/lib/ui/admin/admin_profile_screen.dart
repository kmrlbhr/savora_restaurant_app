import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../providers/auth_providers.dart';
import '../common/widgets/error_dialog.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing(String currentName) {
    _nameController.text = currentName;
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateUserDocument(user.uid, {'name': newName});
      ref.invalidate(authProvider);
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.navy,
            child: Text(
              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 36,
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Name (editable or display)
          if (_isEditing) ...[
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : _cancelEditing,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveName,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user?.name ?? '',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _startEditing(user?.name ?? ''),
                  icon: const Icon(Icons.edit, size: 20),
                  color: AppColors.grey500,
                  tooltip: 'Edit name',
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.goldMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Admin',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          // Logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  context,
                  title: 'Sign Out',
                  message: 'Are you sure you want to sign out?',
                  confirmLabel: 'Sign Out',
                  isDestructive: true,
                );
                if (confirmed) {
                  await ref.read(authProvider.notifier).signOut();
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
