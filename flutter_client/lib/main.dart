import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/api_config.dart';
import 'config/theme.dart';
import 'services/socket_service.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/request_provider.dart';
import 'providers/donor_provider.dart';
import 'widgets/app_drawer.dart';
import 'widgets/auth_dialog.dart';
import 'widgets/notifications_sheet.dart';
import 'widgets/toast_overlay.dart';
import 'screens/home_screen.dart';
import 'screens/live_requests_screen.dart';
import 'screens/find_donors_screen.dart';
import 'screens/blood_groups_screen.dart';
import 'screens/donor_availability_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/register_donor_screen.dart';
import 'screens/about_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();
  SocketService.init();

  runApp(const BloodBridgeApp());
}

class BloodBridgeApp extends StatelessWidget {
  const BloodBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => DonorProvider()),
      ],
      child: MaterialApp(
        title: 'BloodBridge - Real-Time Blood Donation Network',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const MainShell(),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  String _currentRoute = 'home';

  void _navigateTo(String route) {
    setState(() => _currentRoute = route);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final notifProv = Provider.of<NotificationProvider>(context);

    // Auto-fetch notifications when authenticated
    if (auth.isAuthenticated && auth.token != null && notifProv.notifications.isEmpty && !notifProv.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifProv.fetchNotifications(auth.token!);
      });
    }

    String screenTitle = '🩸 BloodBridge';
    if (_currentRoute == 'requests') screenTitle = 'Live Blood Requests';
    if (_currentRoute == 'find-donors') screenTitle = 'Find Blood Donors';
    if (_currentRoute == 'blood-groups') screenTitle = 'Blood Groups & Compatibility';
    if (_currentRoute == 'availability') screenTitle = 'My Availability';
    if (_currentRoute == 'admin') screenTitle = 'Admin Console';
    if (_currentRoute == 'register-donor') screenTitle = 'Become a Donor';
    if (_currentRoute == 'about') screenTitle = 'About BloodBridge';
    if (_currentRoute == 'settings') screenTitle = 'Server Settings';

    return ToastOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: Text(screenTitle),
          actions: [
            // Notifications Bell with Unread Badge
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    if (auth.isAuthenticated) {
                      NotificationsSheet.show(context);
                    } else {
                      AuthDialog.show(context);
                    }
                  },
                ),
                if (notifProv.unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.emergencyRed,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      alignment: Alignment.center,
                      child: Text(
                        '${notifProv.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // User Profile / Sign In
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: auth.isAuthenticated
                  ? InkWell(
                      onTap: () {
                        if (auth.isDonor) {
                          _navigateTo('availability');
                        } else if (auth.isAdmin) {
                          _navigateTo('admin');
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              auth.user?.name.split(' ').first ?? 'User',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            if (auth.user?.bloodGroup != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${auth.user!.bloodGroup})',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.emergencyRed,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: () => AuthDialog.show(context),
                      child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
            ),
          ],
        ),
        drawer: AppDrawer(
          activeRoute: _currentRoute,
          onNavigate: _navigateTo,
        ),
        body: _buildCurrentScreen(),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentRoute) {
      case 'home':
        return HomeScreen(onNavigate: _navigateTo);
      case 'requests':
        return const LiveRequestsScreen();
      case 'find-donors':
        return const FindDonorsScreen();
      case 'blood-groups':
        return BloodGroupsScreen(onNavigate: _navigateTo);
      case 'availability':
        return const DonorAvailabilityScreen();
      case 'admin':
        return const AdminDashboardScreen();
      case 'register-donor':
        return const RegisterDonorScreen();
      case 'about':
        return const AboutScreen();
      case 'settings':
        return const SettingsScreen();
      default:
        return HomeScreen(onNavigate: _navigateTo);
    }
  }
}
