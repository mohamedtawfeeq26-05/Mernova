import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/blood_request_model.dart';
import '../providers/auth_provider.dart';
import '../providers/request_provider.dart';
import '../widgets/create_request_dialog.dart';

class LiveRequestsScreen extends StatefulWidget {
  const LiveRequestsScreen({super.key});

  @override
  State<LiveRequestsScreen> createState() => _LiveRequestsScreenState();
}

class _LiveRequestsScreenState extends State<LiveRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RequestProvider>(context, listen: false).fetchRequests();
    });
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _confirmAccept(String requestId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated || !auth.isDonor) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in as a Donor to accept requests.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Acceptance'),
        content: const Text(
          'Are you sure you want to accept this request? The requester and hospital will be immediately notified with your contact details.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Accept')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final reqProv = Provider.of<RequestProvider>(context, listen: false);
      final ok = await reqProv.acceptRequest(auth.token!, requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ok ? AppTheme.greenSuccess : AppTheme.emergencyRed,
            content: Text(reqProv.statusMessage ?? reqProv.errorMessage ?? 'Completed.'),
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(String requestId, String newStatus) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) return;

    final reqProv = Provider.of<RequestProvider>(context, listen: false);
    final ok = await reqProv.updateStatus(auth.token!, requestId, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ok ? AppTheme.greenSuccess : AppTheme.emergencyRed,
          content: Text(reqProv.statusMessage ?? reqProv.errorMessage ?? 'Status updated.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final reqProv = Provider.of<RequestProvider>(context);

    return Scaffold(
      floatingActionButton: (auth.isRequester || auth.isAdmin)
          ? FloatingActionButton.extended(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Post Request'),
              onPressed: () => CreateRequestDialog.show(context),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => reqProv.fetchRequests(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          '🚨 Live Blood Requests',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Real-time emergency matching & dispatch alerts',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (auth.isRequester || auth.isAdmin)
                    ElevatedButton(
                      onPressed: () => CreateRequestDialog.show(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: const Text('+ Post Request'),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (reqProv.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (reqProv.requests.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: const Column(
                    children: [
                      Text('🩸', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 12),
                      Text(
                        'No active blood requests at the moment.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'When patients or hospitals post requests, they will appear here in real-time.',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reqProv.requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (ctx, i) {
                    final req = reqProv.requests[i];
                    return _buildRequestCard(context, req, auth);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, BloodRequestModel req, AuthProvider auth) {
    final isEmergency = req.isEmergency;
    final isAccepted = req.isAccepted;

    Color urgencyColor = const Color(0xFF64748B);
    Color urgencyBg = const Color(0xFFF1F5F9);
    if (req.urgency == 'Emergency') {
      urgencyColor = AppTheme.emergencyRed;
      urgencyBg = const Color(0xFFFEE2E2);
    } else if (req.urgency == 'Critical') {
      urgencyColor = const Color(0xFF991B1B);
      urgencyBg = const Color(0xFFFFE4E6);
    }

    Color statusColor = const Color(0xFFD97706);
    Color statusBg = const Color(0xFFFEF3C7);
    if (req.status == 'Accepted') {
      statusColor = const Color(0xFF0284C7);
      statusBg = const Color(0xFFE0F2FE);
    } else if (req.status == 'Fulfilled') {
      statusColor = AppTheme.greenSuccess;
      statusBg = const Color(0xFFDCFCE7);
    } else if (req.status == 'Cancelled') {
      statusColor = const Color(0xFF64748B);
      statusBg = const Color(0xFFF1F5F9);
    }

    final isOwner = req.requesterId == auth.user?.id;
    final canManageStatus = auth.isAdmin || (auth.isRequester && isOwner);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEmergency ? AppTheme.emergencyRed.withOpacity(0.8) : AppTheme.borderSubtle,
          width: isEmergency ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isEmergency ? AppTheme.emergencyRed.withOpacity(0.08) : Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Group badge & Urgency / Status tags
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isEmergency ? AppTheme.emergencyRed : AppTheme.primaryDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  req.bloodGroup,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: urgencyBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: urgencyColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      '${isEmergency ? '🚨 ' : ''}${req.urgency}',
                      style: TextStyle(
                        color: urgencyColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      req.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Patient Name & Hospital
          Text(
            req.patientName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('🏥 ', style: TextStyle(fontSize: 13)),
              Expanded(
                child: Text(
                  '${req.hospitalName}, ${req.city}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '🩸 Units Needed: ${req.unitsRequired} Unit(s)',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _callPhone(req.contactPhone),
            child: Row(
              children: [
                const Text('📞 Contact: ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                Text(
                  req.contactPhone,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          if (req.address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '📍 ${req.address}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
          if (req.notes != null && req.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '📝 "${req.notes}"',
                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ),
          ],

          // Accepted Banner
          if (isAccepted && req.acceptedByName != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.greenSuccess.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Text('✓ ', style: TextStyle(color: AppTheme.greenSuccess, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      'Accepted by Donor: ${req.acceptedByName} (${req.acceptedByBloodGroup ?? req.bloodGroup})',
                      style: const TextStyle(color: Color(0xFF14532D), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (req.acceptedByPhone != null)
                    InkWell(
                      onTap: () => _callPhone(req.acceptedByPhone!),
                      child: const Text(
                        '📞 Call',
                        style: TextStyle(color: AppTheme.greenSuccess, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (auth.isDonor && req.isPending)
                ElevatedButton.icon(
                  icon: const Icon(Icons.favorite, size: 16),
                  label: const Text('Accept to Donate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emergencyRed,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () => _confirmAccept(req.id),
                ),
              if (canManageStatus) ...[
                if (req.isAccepted)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.greenSuccess,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => _updateStatus(req.id, 'Fulfilled'),
                    child: const Text('Mark Fulfilled'),
                  ),
                if (req.isPending) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.emergencyRed,
                      side: const BorderSide(color: AppTheme.emergencyRed),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    onPressed: () => _updateStatus(req.id, 'Cancelled'),
                    child: const Text('Cancel Request'),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }
}
