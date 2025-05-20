import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import for GoogleSignInAccount
import 'package:taskquest1/screens/authentication_ui.dart';
import 'components/const/colors.dart';
import 'avatar_design_page.dart';
import 'manage_friends_page.dart';
import '../theme.dart';  // for AppTheme enum
import '../services/calendar_service.dart'; // Import CalendarService
import '../services/authentication_service.dart'; // Import AuthenticationService
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import '../services/notification_service.dart'; // Added NotificationService import
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Added for direct Show() access

class SettingsPage extends StatefulWidget {
  final AppTheme currentTheme;
  final ValueChanged<AppTheme> onThemeChanged;

  const SettingsPage({
    Key? key,
    required this.currentTheme,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final CalendarService _calendarService = CalendarService();
  final AuthenticationService _authService = AuthenticationService(FirebaseAuth.instance); // Add AuthenticationService
  GoogleSignInAccount? _googleUser;
  bool _isProcessingGoogleSignIn = false;

  @override
  void initState() {
    super.initState();
    _checkGoogleSignInStatus();
  }

  Future<void> _checkGoogleSignInStatus() async {
    setState(() {
      _isProcessingGoogleSignIn = true;
    });
    final isSignedIn = await _calendarService.isSignedIn();
    if (isSignedIn) {
      _googleUser = await _calendarService.signInWithGoogle(); // To get current user details
    } else {
      _googleUser = null;
    }
    if (mounted) { // Check if the widget is still in the tree
      setState(() {
        _isProcessingGoogleSignIn = false;
      });
    }
  }

  Future<void> _toggleGoogleCalendarSync() async {
    setState(() {
      _isProcessingGoogleSignIn = true;
    });
    try {
      if (_googleUser == null) {
        final account = await _calendarService.signInWithGoogle();
        if (mounted) {
          setState(() {
            _googleUser = account;
          });
        }
        if (account != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected to Google Calendar as ${account.email}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Google Calendar connection cancelled.')),
          );
        }
      } else {
        await _calendarService.signOut();
        if (mounted) {
          setState(() {
            _googleUser = null;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disconnected from Google Calendar.')),
        );
      }
    } catch (e) {
      print("Error toggling Google Calendar Sync: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
    if (mounted) {
      setState(() {
        _isProcessingGoogleSignIn = false;
      });
    }
  }

  Future<void> _logoutUser() async {
    try {
      // Sign out from Google Calendar Service (if connected)
      if (_googleUser != null) {
        await _calendarService.signOut();
      }
      // Sign out from Firebase
      await _authService.signOut();

      // Navigate back to AuthenticationUI and remove all previous routes
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => AuthenticationUI(
            currentTheme: widget.currentTheme, // Pass theme arguments
            onThemeChanged: widget.onThemeChanged,
          )),
          (Route<dynamic> route) => false, // This predicate removes all routes
        );
      }
    } catch (e) {
      print("Error during logout: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Theme selector
        ListTile(
          title: Text(
            'Select App Theme',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          subtitle: DropdownButton<AppTheme>(
            value: widget.currentTheme,
            isExpanded: true,
            items: AppTheme.values.map((mode) {
              final name = mode.toString().split('.').last;
              return DropdownMenuItem(
                value: mode,
                child: Text(name),
              );
            }).toList(),
            onChanged: (mode) {
              if (mode != null) widget.onThemeChanged(mode);
            },
          ),
        ),
        Divider(),

        // Google Calendar Sync ListTile
        ListTile(
          leading: Icon(Icons.sync, color: primaryGreen),
          title: Text(_googleUser == null
              ? 'Connect Google Calendar'
              : 'Google Calendar Connected'),
          subtitle: _googleUser != null ? Text(_googleUser!.email) : null,
          trailing: _isProcessingGoogleSignIn
              ? CircularProgressIndicator()
              : Icon(Icons.arrow_forward_ios),
          onTap: _isProcessingGoogleSignIn ? null : _toggleGoogleCalendarSync,
        ),
        Divider(),

        // Avatar selection
        ListTile(
          leading: Icon(Icons.person, color: primaryGreen),
          title: Text('Select Avatar'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AvatarDesignPage()),
            );
          },
        ),
        Divider(),

        // Notification settings
        ListTile(
          leading: Icon(Icons.notifications, color: primaryGreen),
          title: Text('Notification Permissions'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Notification Permissions'),
                content: Text('Need to implement / configure for permissions.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK', style: TextStyle(color: primaryGreen)),
                  ),
                ],
              ),
            );
          },
        ),
        Divider(),

        // Logout Button
        ListTile(
          leading: Icon(Icons.exit_to_app, color: Colors.redAccent),
          title: Text('Logout', style: TextStyle(color: Colors.redAccent)),
          onTap: _logoutUser,
        ),
        Divider(),
        // Test Notification Button
        ListTile(
          leading: Icon(Icons.notification_important, color: Colors.amber),
          title: Text('Test Notification'),
          subtitle: Text('Schedules a test notification in 5s'),
          onTap: () async {
            final NotificationService notificationService = NotificationService();
            final int testId = DateTime.now().millisecondsSinceEpoch % 2147483647;
            
            // Simplified scheduling for testing
            await notificationService.flutterLocalNotificationsPlugin.show(
              testId,
              '🧪 Test Notification (Simple)',
              'This is a simple test notification fired from Settings!',
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'task_due_channel', // Ensure this channel ID matches the one created in NotificationService
                  'Task Due Reminders',
                  channelDescription: 'Channel for task due date reminders.',
                  importance: Importance.high,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher',
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
              payload: 'test_payload_from_settings_simple_$testId',
            );

            // Original scheduling call (commented out for now for this test)
            // await notificationService.scheduleNotification(
            //   id: testId,
            //   title: '🧪 Test Notification',
            //   body: 'This is a test notification fired from Settings!',
            //   scheduledDate: DateTime.now().add(const Duration(seconds: 5)),
            //   payload: 'test_payload_from_settings_$testId',
            // );

            if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Test notification scheduled in 5 seconds.')),
                );
            }
          },
        ),
        Divider(),
      ],
    );
  }
}
