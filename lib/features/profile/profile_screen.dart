import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Color backgroundColor = Color(0xFFFAF8F4);
  static const Color darkText = Color(0xFF181818);
  static const Color secondaryText = Color(0xFF77736E);
  static const Color redColor = Color(0xFFE52529);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    final String name =
        user['name']?.toString() ?? 'My Profile';

    final String email =
        user['email']?.toString() ?? 'No email available';

    final String userId =
        user['id']?.toString() ?? 'Not available';

    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            // Profile header.
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 48,
                    backgroundColor: Color(0x1FE52529),
                    child: Icon(
                      Icons.person,
                      size: 54,
                      color: redColor,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Account information heading.
            const Text(
              'ACCOUNT INFORMATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: secondaryText,
                letterSpacing: 1.1,
              ),
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.person_outline,
              title: 'Full Name',
              value: name,
            ),

            _buildInfoCard(
              icon: Icons.email_outlined,
              title: 'Email Address',
              value: email,
            ),

            _buildInfoCard(
              icon: Icons.badge_outlined,
              title: 'User ID',
              value: userId,
            ),

            const SizedBox(height: 24),

            // Settings heading.
            const Text(
              'SETTINGS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: secondaryText,
                letterSpacing: 1.1,
              ),
            ),

            const SizedBox(height: 12),

            _buildActionTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Notification preferences',
              onTap: () {
                _showMessage(
                  context,
                  'Notification settings are not available yet.',
                );
              },
            ),

            _buildActionTile(
              icon: Icons.lock_outline,
              title: 'Security',
              subtitle: 'Account security',
              onTap: () {
                _showMessage(
                  context,
                  'Security settings are not available yet.',
                );
              },
            ),

            const SizedBox(height: 28),

            // Logout button.
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: authState.isLoading
                    ? null
                    : () => _confirmLogout(context, ref),
                icon: const Icon(
                  Icons.logout,
                  color: redColor,
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: redColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: redColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Account information card.
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x1FE52529),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: redColor,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: secondaryText,
                  ),
                ),

                const SizedBox(height: 5),

                SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: darkText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Settings list tile.
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: redColor,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: secondaryText,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: secondaryText,
        ),
        onTap: onTap,
      ),
    );
  }

  // Confirm logout.
  Future<void> _confirmLogout(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to log out?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: redColor),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).logout();
    } catch (e) {
      if (context.mounted) {
        _showMessage(
          context,
          'Logout failed: $e',
        );
      }
      return;
    }

    if (!context.mounted) return;

    // This assumes "/" is your login route.
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  // Show a message.
  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}