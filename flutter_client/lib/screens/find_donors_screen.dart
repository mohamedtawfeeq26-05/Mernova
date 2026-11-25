import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/blood_compatibility.dart';
import '../models/user_model.dart';
import '../providers/donor_provider.dart';

class FindDonorsScreen extends StatefulWidget {
  const FindDonorsScreen({super.key});

  @override
  State<FindDonorsScreen> createState() => _FindDonorsScreenState();
}

class _FindDonorsScreenState extends State<FindDonorsScreen> {
  String _selectedGroup = '';
  final _cityController = TextEditingController();
  String? _copiedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Auto-load all donors initially for rich discovery
      Provider.of<DonorProvider>(context, listen: false).searchDonors();
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final donorProv = Provider.of<DonorProvider>(context, listen: false);
    donorProv.searchDonors(
      bloodGroup: _selectedGroup.isEmpty ? null : _selectedGroup,
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
    );
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
    final donorProv = Provider.of<DonorProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Text(
            '🔍 Find Blood Donors',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Search for registered donors by blood group and city.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Search Form Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedGroup,
                    decoration: const InputDecoration(labelText: 'Blood Group'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('All Blood Groups')),
                      ...BloodCompatibility.allBloodGroups.map(
                        (g) => DropdownMenuItem(value: g, child: Text(g)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedGroup = v ?? ''),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      hintText: 'Enter city name (e.g. Mumbai, Delhi)',
                    ),
                    onFieldSubmitted: (_) => _handleSearch(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: Text(donorProv.isSearching ? 'Searching...' : 'Search Donors'),
                    onPressed: donorProv.isSearching ? null : _handleSearch,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Message banner
          if (donorProv.searchMessage != null)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Text(
                donorProv.searchMessage!,
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),

          // Loading
          if (donorProv.isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (donorProv.searchResults.isNotEmpty) ...[
            Text(
              'Found ${donorProv.searchResults.length} Donor(s)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: donorProv.searchResults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final donor = donorProv.searchResults[i];
                return _buildDonorCard(donor);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonorCard(UserModel donor) {
    final isAvail = donor.isAvailable;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAvail ? AppTheme.greenSuccess.withOpacity(0.4) : AppTheme.borderSubtle,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      donor.bloodGroup ?? '—',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryDark,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donor.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${donor.city ?? 'City N/A'} • ${donor.age != null ? '${donor.age} yrs' : ''}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          if (donor.address != null && donor.address!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '📍 ${donor.address}${donor.pincode != null ? ', ${donor.pincode}' : ''}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '🩸 Total Donations: ${donor.totalDonations} times',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () => _copyPhone(donor.id, donor.phone),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
