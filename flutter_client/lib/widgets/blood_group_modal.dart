import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/blood_compatibility.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class BloodGroupModal extends StatefulWidget {
  final String bloodGroup;
  final VoidCallback? onRegisterClick;

  const BloodGroupModal({
    super.key,
    required this.bloodGroup,
    this.onRegisterClick,
  });

  static Future<void> show(
    BuildContext context, {
    required String bloodGroup,
    VoidCallback? onRegisterClick,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BloodGroupModal(
        bloodGroup: bloodGroup,
        onRegisterClick: onRegisterClick,
      ),
    );
  }

  @override
  State<BloodGroupModal> createState() => _BloodGroupModalState();
}

class _BloodGroupModalState extends State<BloodGroupModal> {
  List<UserModel> _donors = [];
  bool _isLoading = true;
  String? _copiedId;

  @override
  void initState() {
    super.initState();
    _fetchDonors();
  }

  Future<void> _fetchDonors() async {
    setState(() => _isLoading = true);
    try {
      final list = await ApiService.searchDonors(bloodGroup: widget.bloodGroup);
      if (mounted) setState(() => _donors = list);
    } catch (_) {
      // Ignored
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot initiate phone call to $phone')),
        );
      }
    }
  }

  void _copyPhone(String id, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    setState(() => _copiedId = id);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = BloodCompatibility.getFor(widget.bloodGroup);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.bloodGroup,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blood Group ${widget.bloodGroup} Donors',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (info != null)
                          Text(
                            info.tag,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Compatibility Matrix Box
              if (info != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Can Donate Blood To:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: info.canDonateTo
                            .map((g) => _buildBadge(g, AppTheme.greenSuccess, const Color(0xFFDCFCE7)))
                            .toList(),
                      ),
                      const Divider(height: 20),
                      const Text(
                        'Can Receive Blood From:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: info.canReceiveFrom
                            .map((g) => _buildBadge(g, const Color(0xFF0284C7), const Color(0xFFE0F2FE)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Registered Donors Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registered ${widget.bloodGroup} Donors (${_donors.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _fetchDonors,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Donors list
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_donors.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.scaffoldBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'No donors registered yet for this blood group.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      if (widget.onRegisterClick != null)
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onRegisterClick!();
                          },
                          child: Text('Be the First ${widget.bloodGroup} Donor!'),
                        ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _donors.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final donor = _donors[i];
                    final isAvail = donor.isAvailable;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAvail ? AppTheme.greenSuccess.withOpacity(0.4) : AppTheme.borderSubtle,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                donor.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isAvail ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isAvail ? '● Available' : '○ Unavailable',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAvail ? AppTheme.greenSuccess : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${donor.gender ?? 'Donor'} • ${donor.age != null ? '${donor.age} yrs • ' : ''}${donor.city ?? 'City N/A'}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          if (donor.address != null && donor.address!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '📍 ${donor.address}${donor.pincode != null ? ', ${donor.pincode}' : ''}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '🩸 Donated: ${donor.totalDonations} times',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          if (!isAvail && donor.nextEligibleDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '⏳ In cooldown until ${donor.nextEligibleDate!.day}/${donor.nextEligibleDate!.month}/${donor.nextEligibleDate!.year}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.amberWarning, fontWeight: FontWeight.bold),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.call, size: 16),
                                  label: Text('Call ${donor.phone}'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onPressed: () => _callPhone(donor.phone),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: Icon(
                                  _copiedId == donor.id ? Icons.check : Icons.copy,
                                  size: 16,
                                ),
                                label: Text(_copiedId == donor.id ? 'Copied' : 'Copy'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                onPressed: () => _copyPhone(donor.id, donor.phone),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
