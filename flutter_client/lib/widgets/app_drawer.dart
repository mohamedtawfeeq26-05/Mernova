import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';
import 'auth_dialog.dart';

class AppDrawer extends StatelessWidget {
  final String activeRoute;
  final Function(String route) onNavigate;

  const AppDrawer({
    super.key,
    required this.activeRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🩸', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 10),
                    const Text(
                      'BloodBridge',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (auth.isAuthenticated && user != null) ...[
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${user.role.toUpperCase()} ${user.bloodGroup != null ? '(${user.bloodGroup})' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Real-Time Blood Donation Network',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      AuthDialog.show(context);
                    },
                    child: const Text('Sign In / Register', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.home_outlined,
                  title: 'Home',
                  route: 'home',
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.emergency_outlined,
                  title: 'Live Requests',
                  route: 'requests',
                  badge: '🚨',
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.search_outlined,
                  title: 'Find Donors',
                  route: 'find-donors',
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.bloodtype_outlined,
                  title: 'Blood Groups',
                  route: 'blood-groups',
                ),
                if (auth.isDonor)
                  _buildNavItem(
                    context: context,
                    icon: Icons.event_available_outlined,
                    title: 'My Availability',
                    route: 'availability',
                  ),
                if (auth.isAdmin)
                  _buildNavItem(
                    context: context,
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Admin Console',
                    route: 'admin',
                  ),
                _buildNavItem(
                  context: context,
                  icon: Icons.person_add_alt_1_outlined,
                  title: 'Become a Donor',
                  route: 'register-donor',
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.info_outline,
                  title: 'About BloodBridge',
                  route: 'about',
                ),
                const Divider(),
                _buildNavItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: 'Server Settings',
                  route: 'settings',
                ),
              ],
            ),
          ),

          // Logout Button
          if (auth.isAuthenticated)
            Container(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.emergencyRed,
                  side: const BorderSide(color: AppTheme.emergencyRed),
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  auth.logout();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    String? badge,
  }) {
    final isSelected = activeRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: badge != null
          ? Text(badge, style: const TextStyle(fontSize: 16))
          : null,
      selected: isSelected,
      selectedTileColor: AppTheme.primaryLight.withOpacity(0.4),
      onTap: () {
        Navigator.of(context).pop();
        onNavigate(route);
      },
    );
  }
}
