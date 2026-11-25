# 🩸 BloodBridge - Flutter Integration

A cross-platform Flutter application (Android, iOS, Web, Desktop) integrated with the BloodBridge MERN backend **without modifying any backend operations or database schemas**.

---

## 🎯 Features Replicated 1:1

1. **Role-Based Authentication (RBAC)**:
   - Supports **Donor**, **Requester (Hospital/Patient)**, and **Administrator**.
   - Includes one-click demo presets for evaluation:
     - 🛡️ **Admin**: `admin@bloodbridge.org` / `AdminPassword@123`
     - 🩸 **Donor**: `rahul.donor@bloodbridge.org` / `Password@123`
     - 🏥 **Hospital**: `apollo.mumbai@bloodbridge.org` / `Password@123`
   - Validates Indian mobile numbers (`^[6-9][0-9]{9}$`) and strong passwords.

2. **Real-Time WebSockets (Socket.IO)**:
   - Connects to Socket.IO backend at `http://localhost:5000` (or `http://10.0.2.2:5000` on Android emulator).
   - Automatically joins user-specific and blood-group-specific rooms.
   - Real-time listeners:
     - `new_notification`: In-app floating toast alerts and Notification Center sync.
     - `emergency_broadcast`: Urgent red alert broadcast toasts.
     - `blood_request_created`: Prepend new emergency requests to live feed instantly.
     - `request_accepted`: Updates status to 'Accepted' with donor details in real-time.
     - `availability_updated`: Updates donor cooldown status.

3. **Live Blood Requests & Emergency Dispatch**:
   - Filter and view requests with urgency indicators (`🚨 Emergency`, `⚠️ Critical`, `Normal`).
   - Requesters & Admins can post new blood requests.
   - Donors can accept pending requests with 1-tap confirmation.
   - Requesters & Admins can mark requests `Fulfilled` or `Cancelled`.

4. **Find Donors (Donor Search)**:
   - Filter registered donors by **Blood Group** and **City**.
   - Displays donor cards with contact details, age, gender, city, and availability.
   - One-tap direct phone call (`tel:`) and copy to clipboard.

5. **Blood Groups & Clinical Compatibility Matrix**:
   - Covers all 8 blood groups: `A+`, `A-`, `B+`, `B-`, `AB+`, `AB-`, `O+`, `O-`.
   - Comprehensive clinical compatibility rules (Universal Donor `O-`, Universal Recipient `AB+`).
   - Modal sheet showing registered donors per blood group with call/copy actions.

6. **Donor Availability & 90-Day Cooldown Management**:
   - Toggle status between `Available` and `Unavailable`.
   - Record blood donation date to automatically calculate the 90-day recovery cooldown.
   - Visual cooldown countdown and progress bar.
   - Trigger automated reminder check (`/api/donors/availability/reminders/trigger`).

7. **Admin Management Console**:
   - Live platform stats: Registered Donors, Emergency Alerts, Total Blood Requests, Lives Saved (Fulfilled).
   - Users & Roles directory table.
   - Force trigger 90-day eligibility reminders.

8. **Standalone Donor Registration (with GPS Location)**:
   - Full donor registration form calling `/api/donors/register`.
   - Device GPS location capture with coordinates (`latitude`, `longitude`).

9. **Notification Center**:
   - Floating emergency banners and notification bell with unread badge counter.
   - Mark single / all notifications as read.

10. **Network & Server Settings**:
    - Configure custom backend IP address for physical Android/iOS devices on local Wi-Fi.
    - Built-in connection test tool to verify backend health.

---

## 🚀 Running the App

### Option 1: Run Backend + Flutter Together
From the root directory:
```bash
npm run dev:flutter
```

### Option 2: Run Flutter on Chrome (Web)
```bash
npm run flutter:chrome
# or
cd bloodbridge/flutter_client
flutter run -d chrome
```

### Option 3: Run Flutter on Android Emulator / Physical Device
```bash
cd bloodbridge/flutter_client
flutter run
```

*Note for Android Emulator:* The app automatically detects Android and sets the base URL to `http://10.0.2.2:5000` so it can talk to your host machine's Express server without any configuration needed. For physical devices on Wi-Fi, enter your computer's local IP (e.g. `http://192.168.1.100:5000`) in the app's **Server Settings** screen.
