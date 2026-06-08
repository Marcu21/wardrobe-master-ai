import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/user_settings_service.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'package:mobile_app/widgets/custom_snackbar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = UserSettingsService();

  bool _prioritizeNeglected = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await _service.getPrioritizeNeglected();
    if (mounted) setState(() { _prioritizeNeglected = value; _loading = false; });
  }

  Future<void> _setPrioritizeNeglected(bool value) async {
    setState(() => _prioritizeNeglected = value);
    await _service.setPrioritizeNeglected(value);
  }

  bool get _isGoogleUser {
    final user = FirebaseAuth.instance.currentUser;
    return user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: kBgColor)),
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kGlowPrimary,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.back, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Settings',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _SectionHeader(label: 'Account'),
                        _AccountTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Display name',
                          subtitle: FirebaseAuth.instance.currentUser?.displayName ??
                              'Not set',
                          onTap: () => _showEditNameDialog(context),
                        ),
                        const SizedBox(height: 8),
                        _AccountTile(
                          icon: Icons.email_outlined,
                          title: 'Email',
                          subtitle: FirebaseAuth.instance.currentUser?.email ?? 'Not set',
                        ),
                        const SizedBox(height: 8),
                        _AccountTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Password',
                          subtitle: _isGoogleUser
                              ? 'Managed by Google'
                              : 'Change your password',
                          onTap: _isGoogleUser
                              ? null
                              : () => _showChangePasswordDialog(context),
                          trailing: _isGoogleUser
                              ? Image.asset(
                                  'assets/icons/google_logo.png',
                                  width: 20,
                                  height: 20,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.g_mobiledata_rounded,
                                    color: Colors.grey,
                                    size: 22,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 24),
                        _SectionHeader(label: 'AI Stylist'),
                        _SettingsTile(
                          icon: Icons.recycling_rounded,
                          title: 'Prioritize neglected items',
                          subtitle:
                              'Ask the AI to favour clothes you haven\'t worn in a while',
                          value: _prioritizeNeglected,
                          onChanged: _setPrioritizeNeglected,
                        ),
                        const SizedBox(height: 24),
                        _SectionHeader(label: 'Danger Zone'),
                        _DangerTile(
                          icon: Icons.delete_forever_rounded,
                          title: 'Delete account',
                          subtitle: 'Permanently delete your account and all data',
                          onTap: () => _showDeleteAccountDialog(context),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditNameDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final currentName = user?.displayName ?? '';
    await showDialog(
      context: context,
      builder: (_) => _EditNameDialog(currentName: currentName),
    );
    // Rebuild to reflect updated displayName
    if (mounted) setState(() {});
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
  }

}

// ---------------------------------------------------------------------------
// Edit name dialog
// ---------------------------------------------------------------------------

class _EditNameDialog extends StatefulWidget {
  final String currentName;
  const _EditNameDialog({required this.currentName});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.updateDisplayName(name);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'name': name}, SetOptions(merge: true));
      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showSuccess(context, 'Name updated');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        CustomSnackBar.showError(context, 'Failed to update name');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Display name',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: 'Your name',
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: kPrimary),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Change password dialog
// ---------------------------------------------------------------------------

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = _currentCtrl.text.trim();
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      CustomSnackBar.showError(context, 'Please fill in all fields');
      return;
    }
    if (newPass != confirm) {
      CustomSnackBar.showError(context, 'New passwords do not match');
      return;
    }
    if (newPass.length < 6) {
      CustomSnackBar.showError(context, 'Password must be at least 6 characters');
      return;
    }

    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: current,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPass);
      if (mounted) {
        Navigator.pop(context);
        CustomSnackBar.showSuccess(context, 'Password updated');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        final msg = e.code == 'wrong-password' || e.code == 'invalid-credential'
            ? 'Current password is incorrect'
            : 'Failed to update password';
        CustomSnackBar.showError(context, msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        CustomSnackBar.showError(context, 'An error occurred');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Change password',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PasswordField(
            controller: _currentCtrl,
            hint: 'Current password',
            obscure: _obscureCurrent,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: _newCtrl,
            hint: 'New password',
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: _confirmCtrl,
            hint: 'Confirm new password',
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: kPrimary),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: Colors.grey[500],
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Delete account dialog
// ---------------------------------------------------------------------------

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordCtrl = TextEditingController();
  bool _deleting = false;
  bool _obscure = true;

  final _authService = AuthService();

  bool get _isGoogleUser => _authService.isGoogleUser;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await _authService.deleteAccount(
        password: _isGoogleUser ? null : _passwordCtrl.text.trim(),
      );
      // Auth state change will automatically redirect to login
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        final msg = e.code == 'wrong-password' || e.code == 'invalid-credential'
            ? 'Incorrect password'
            : 'Failed to delete account';
        CustomSnackBar.showError(context, msg);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        final msg = e.toString().contains('cancelled')
            ? 'Cancelled'
            : 'Failed to delete account';
        CustomSnackBar.showError(context, msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Delete account',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.redAccent),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This will permanently delete your account, wardrobe, outfits, and all other data. This cannot be undone.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          if (!_isGoogleUser) ...[
            const SizedBox(height: 16),
            const Text(
              'Enter your password to confirm:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'Password',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: Colors.grey[500],
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'You\'ll be asked to sign in with Google to confirm.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _deleting ? null : _delete,
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          child: _deleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared tile widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kPrimary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4),
        ),
        trailing: trailing ??
            (onTap != null
                ? const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey)
                : null),
        onTap: onTap,
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DangerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.redAccent, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.redAccent,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4),
        ),
        trailing: const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kPrimary, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.4),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
