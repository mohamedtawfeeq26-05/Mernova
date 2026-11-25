import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/admin_stats_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _activeTab = 'stats'; // 'stats' or 'users'
  AdminStatsModel? _stats;
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _actionMsg;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAdmin || auth.token == null) return;

    setState(() => _isLoading = true);
    try {
      final statsRes = await ApiService.getAdminStats(auth.token!);
      final usersRes = await ApiService.getAdminUsers(auth.token!);
      if (mounted) {
        setState(() {
          _stats = statsRes;
          _users = usersRes;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _actionMsg = 'Failed to load admin data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerReminders() async {
    setState(() => _actionMsg = 'Running eligibility reminder check...');
    try {
      final res = await ApiService.triggerAvailabilityReminders();
      final count = res['result']?['processedCount'] ?? 0;
      if (mounted) {
        setState(() => _actionMsg = 'Reminders triggered! $count donors notified.');
        _fetchAdminData();
      }
    } catch (_) {
      if (mounted) setState(() => _actionMsg = 'Failed to trigger reminders.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isAdmin) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Admin access restricted. Please log in with an Administrator account.',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🛡️ Admin Console',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Real-time system health, RBAC & dispatch metrics',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchAdminData,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabs
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _activeTab == 'stats' ? AppTheme.primary : Colors.grey.shade200,
                    foregroundColor: _activeTab == 'stats' ? Colors.white : AppTheme.textPrimary,
                  ),
                  onPressed: () => setState(() => _activeTab = 'stats'),
                  child: const Text('Overview & Stats'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _activeTab == 'users' ? AppTheme.primary : Colors.grey.shade200,
                    foregroundColor: _activeTab == 'users' ? Colors.white : AppTheme.textPrimary,
                  ),
                  onPressed: () => setState(() => _activeTab = 'users'),
                  child: Text('Users & Roles (${_users.length})'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Message Banner
          if (_actionMsg != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.greenSuccess),
              ),
              child: Text(
                _actionMsg!,
                style: const TextStyle(color: AppTheme.greenSuccess, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_activeTab == 'stats' && _stats != null) ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  '${_stats!.totalDonors}',
                  'Registered Donors',
                  '${_stats!.availableDonors} Available',
                  AppTheme.primary,
                ),
                _buildStatCard(
                  '${_stats!.emergencyRequests}',
                  '🚨 Emergency Alerts',
                  'Pending matching',
                  AppTheme.emergencyRed,
                ),
                _buildStatCard(
                  '${_stats!.totalRequests}',
                  'Total Requests',
                  '${_stats!.pendingRequests} Pending',
                  const Color(0xFF0284C7),
                ),
                _buildStatCard(
                  '${_stats!.fulfilledRequests}',
                  'Lives Saved (Fulfilled)',
                  '${_stats!.acceptedRequests} In-Progress',
                  AppTheme.greenSuccess,
                ),
              ],
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Automated Tasks & Background Operations',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.alarm),
                      label: const Text('Force Run 90-Day Eligibility Reminders'),
                      onPressed: _triggerReminders,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Live Metrics'),
                      onPressed: _fetchAdminData,
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_activeTab == 'users') ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final u = _users[i];
                Color roleColor = AppTheme.primary;
                if (u.role == 'admin') roleColor = const Color(0xFF6B21A8);
                if (u.role == 'requester') roleColor = const Color(0xFF0284C7);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            u.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              u.role.toUpperCase(),
                              style: TextStyle(
                                color: roleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${u.email} • 📞 ${u.phone}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (u.bloodGroup != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                u.bloodGroup!,
                                style: const TextStyle(
                                  color: AppTheme.primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            u.city ?? 'City N/A',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            u.isDonor ? u.availability : 'Active',
                            style: TextStyle(
                              color: u.isAvailable ? AppTheme.greenSuccess : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String title, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
