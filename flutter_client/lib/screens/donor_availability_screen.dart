import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/donor_provider.dart';

class DonorAvailabilityScreen extends StatefulWidget {
  const DonorAvailabilityScreen({super.key});

  @override
  State<DonorAvailabilityScreen> createState() => _DonorAvailabilityScreenState();
}

class _DonorAvailabilityScreenState extends State<DonorAvailabilityScreen> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.token != null) {
        Provider.of<DonorProvider>(context, listen: false).fetchAvailability(auth.token!);
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveDonationDate() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a donation date.')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final donorProv = Provider.of<DonorProvider>(context, listen: false);

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final ok = await donorProv.recordDonationDate(auth.token!, dateStr);

    if (ok) {
      auth.updateUser(auth.user!.copyWith(
        availability: donorProv.availability,
        lastDonationDate: donorProv.lastDonationDate,
        nextEligibleDate: donorProv.nextEligibleDate,
        totalDonations: donorProv.totalDonations,
      ));
    }
  }

  Future<void> _toggleAvailability(String status) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final donorProv = Provider.of<DonorProvider>(context, listen: false);

    final ok = await donorProv.toggleAvailability(auth.token!, status);
    if (ok) {
      auth.updateUser(auth.user!.copyWith(availability: status));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final donorProv = Provider.of<DonorProvider>(context);

    if (!auth.isDonor) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'This screen is only accessible to registered Donors.',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final isAvail = donorProv.availability == 'Available';
    final daysRemaining = donorProv.daysRemaining;
    final totalDonations = donorProv.totalDonations;
    final nextDate = donorProv.nextEligibleDate;

    double progress = 1.0;
    if (daysRemaining > 0) {
      progress = ((90 - daysRemaining) / 90).clamp(0.05, 1.0);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🩸 Donor Availability',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage eligibility & recovery tracking',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isAvail ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAvail ? AppTheme.greenSuccess : AppTheme.textSecondary,
                    ),
                  ),
                  child: Text(
                    isAvail ? '● Available' : '○ Unavailable',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isAvail ? AppTheme.greenSuccess : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Metrics Grid (4 items)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
            children: [
              _buildMetricCard(
                'Current Status',
                donorProv.availability,
                isAvail ? AppTheme.greenSuccess : AppTheme.emergencyRed,
              ),
              _buildMetricCard(
                'Next Eligible Date',
                nextDate != null ? DateFormat('MMM d, yyyy').format(nextDate) : 'Eligible Now',
                AppTheme.textPrimary,
              ),
              _buildMetricCard(
                'Recovery Period',
                daysRemaining > 0 ? '$daysRemaining days left' : 'Ready to Donate',
                daysRemaining > 0 ? AppTheme.amberWarning : AppTheme.greenSuccess,
              ),
              _buildMetricCard(
                'Total Donations',
                '$totalDonations Times',
                AppTheme.primaryDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cooldown Banner
          if (daysRemaining > 0 && nextDate != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('⏳ ', style: TextStyle(fontSize: 18)),
                      Expanded(
                        child: Text(
                          'Recovery Cooldown Active: Medical safety guidelines require 90 days between donations. Eligible on ${DateFormat.yMMMd().format(nextDate)}.',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFFDE68A),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.amberWarning),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(progress * 100).round()}% Completed ($daysRemaining days remaining)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Actions Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Update Availability Status',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAvail ? AppTheme.greenSuccess : Colors.grey.shade200,
                            foregroundColor: isAvail ? Colors.white : AppTheme.textPrimary,
                          ),
                          onPressed: (!donorProv.isEligibleNow || donorProv.availabilityLoading)
                              ? null
                              : () => _toggleAvailability('Available'),
                          child: const Text('Mark Available'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isAvail ? AppTheme.emergencyRed : Colors.grey.shade200,
                            foregroundColor: !isAvail ? Colors.white : AppTheme.textPrimary,
                          ),
                          onPressed: donorProv.availabilityLoading
                              ? null
                              : () => _toggleAvailability('Unavailable'),
                          child: const Text('Mark Unavailable'),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  const Text(
                    'Record Recent Blood Donation Date',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '* Automatically applies 90-day clinical cooldown and schedules reminders.',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _selectedDate != null
                                ? DateFormat.yMMMd().format(_selectedDate!)
                                : (donorProv.lastDonationDate != null
                                    ? DateFormat.yMMMd().format(donorProv.lastDonationDate!)
                                    : 'Pick Date'),
                          ),
                          onPressed: _pickDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: donorProv.availabilityLoading ? null : _saveDonationDate,
                        child: const Text('Save Date'),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Automated Reminders Trigger
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Automatic Reminders',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Triggers auto-scan for newly eligible donors',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: donorProv.reminderLoading
                            ? null
                            : () => donorProv.triggerReminders(auth.token),
                        child: donorProv.reminderLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('🔔 Run Check'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Message Alert
          if (donorProv.availabilityMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: donorProv.availabilityMessageType == 'success'
                    ? const Color(0xFFDCFCE7)
                    : AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: donorProv.availabilityMessageType == 'success'
                      ? AppTheme.greenSuccess
                      : AppTheme.emergencyRed,
                ),
              ),
              child: Text(
                donorProv.availabilityMessage!,
                style: TextStyle(
                  color: donorProv.availabilityMessageType == 'success'
                      ? AppTheme.greenSuccess
                      : AppTheme.primaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
