import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../config/theme.dart';
import '../models/notification_model.dart';

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final notifProv = Provider.of<NotificationProvider>(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (notifProv.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.emergencyRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${notifProv.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (notifProv.unreadCount > 0 && auth.token != null)
                    TextButton(
                      onPressed: () => notifProv.markAllAsRead(auth.token!),
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
              const Divider(height: 20),

              // Notification List
              Expanded(
                child: notifProv.notifications.isEmpty
                    ? const Center(
                        child: Text(
                          'No notifications yet.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: notifProv.notifications.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final item = notifProv.notifications[i];
                          return _buildNotificationItem(context, item, auth.token);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationModel n, String? token) {
    final notifProv = Provider.of<NotificationProvider>(context, listen: false);

    Color tagColor = AppTheme.primary;
    String tagLabel = '🩸 Request Alert';
    if (n.type == 'EMERGENCY_ALERT') {
      tagColor = AppTheme.emergencyRed;
      tagLabel = '🚨 Emergency Alert';
    } else if (n.type == 'REQUEST_ACCEPTED') {
      tagColor = AppTheme.greenSuccess;
      tagLabel = '✅ Request Accepted';
    } else if (n.type == 'AVAILABILITY_REMINDER') {
      tagColor = AppTheme.amberWarning;
      tagLabel = '⏰ Reminder';
    }

    String timeStr = '';
    if (n.createdAt != null) {
      timeStr = DateFormat.jm().format(n.createdAt!);
    }

    return InkWell(
      onTap: () {
        if (!n.read && token != null) {
          notifProv.markAsRead(token, n.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        color: n.read ? Colors.transparent : AppTheme.primaryLight.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tagLabel,
                    style: TextStyle(color: tagColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              n.title,
              style: TextStyle(
                fontWeight: n.read ? FontWeight.normal : FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              n.message,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
