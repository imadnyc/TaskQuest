import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as GCalendar;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fba;

class CalendarService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      GCalendar.CalendarApi.calendarScope,          // Full access to calendars (view, edit, create, delete)
      GCalendar.CalendarApi.calendarEventsScope,    // Manage (view, edit, create, delete) events on calendars
      // Consider 'email' and 'profile' if you need user info, though not strictly for calendar.
    ],
  );

  GCalendar.CalendarApi? _calendarApi;
  GoogleSignInAccount? _currentUserAccount;

  // Store Firebase user
  fba.User? get firebaseUser => fba.FirebaseAuth.instance.currentUser;

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      _currentUserAccount = await _googleSignIn.signIn();
      if (_currentUserAccount == null) {
        // User cancelled the sign-in
        print('Google Sign-In cancelled by user.');
        return null;
      }

      print('Google User: \${_currentUserAccount!.displayName}');
      // You might want to also sign into Firebase with these Google credentials
      // if you haven't already handled this in the UI layer.
      // Example: await _signInToFirebaseWithGoogle(_currentUserAccount!);

      await _initializeCalendarApi();
      return _currentUserAccount;
    } catch (error, stackTrace) {
      print('Error during Google Sign-In: $error');
      print('Stack trace: $stackTrace');
      _currentUserAccount = null;
      _calendarApi = null;
      return null;
    }
  }

  Future<void> _initializeCalendarApi() async {
    if (_currentUserAccount == null) return;

    final Map<String, String>? authHeaders = await _currentUserAccount!.authHeaders;
    if (authHeaders == null) {
      print('Could not get auth headers.');
      _calendarApi = null;
      // Potentially try to re-authenticate or refresh token
      // _currentUserAccount = await _googleSignIn.signInSilently(reAuthenticate: true);
      // if (_currentUserAccount != null) await _initializeCalendarApi();
      return;
    }

    final httpClient = auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken(
          "Bearer", // Explicitly use "Bearer" as the type
          authHeaders['Authorization']!.split(' ')[1], // Token data
          // Attempt to parse expiry from headers if available, otherwise estimate or handle refresh
          DateTime.now().toUtc().add(const Duration(minutes: 55)), // Placeholder expiry
        ),
        _currentUserAccount!.id, // Refresh token placeholder - see notes in original code
        _googleSignIn.scopes,
      ),
    );
    _calendarApi = GCalendar.CalendarApi(httpClient);
  }
  
  // Helper to get an authenticated client. Ensures API is initialized.
  Future<GCalendar.CalendarApi?> getCalendarApi() async {
    if (_calendarApi == null && _currentUserAccount != null) {
      await _initializeCalendarApi();
    } else if (_currentUserAccount == null) {
      // Attempt to sign in silently if there's a previous sign-in
      _currentUserAccount = await _googleSignIn.signInSilently();
      if (_currentUserAccount != null) {
        await _initializeCalendarApi();
      }
    }
    return _calendarApi;
  }


  Future<bool> isSignedIn() async {
    _currentUserAccount = await _googleSignIn.signInSilently();
    return _currentUserAccount != null;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUserAccount = null;
    _calendarApi = null;
    print('User signed out from Google.');
    // Also sign out from Firebase if you manage session that way
    // await fba.FirebaseAuth.instance.signOut();
  }

  Future<String?> createTaskEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String calendarId = 'primary', // 'primary' refers to the user's main calendar
  }) async {
    final GCalendar.CalendarApi? calendarApi = await getCalendarApi();
    if (calendarApi == null) {
      print('Calendar API not initialized or user not signed in.');
      return null;
    }

    GCalendar.Event event = GCalendar.Event();
    event.summary = title;
    event.description = description;

    GCalendar.EventDateTime start = GCalendar.EventDateTime();
    start.dateTime = startTime.toUtc(); // Ensure UTC for Google Calendar
    start.timeZone = "UTC"; // Or specify user's timezone if known
    event.start = start;

    GCalendar.EventDateTime end = GCalendar.EventDateTime();
    end.dateTime = endTime.toUtc(); // Ensure UTC for Google Calendar
    end.timeZone = "UTC"; // Or specify user's timezone
    event.end = end;

    try {
      final GCalendar.Event createdEvent = await calendarApi.events.insert(event, calendarId);
      print('Event created: \${createdEvent.htmlLink}');
      return createdEvent.id;
    } catch (e) {
      print('Error creating event: \$e');
      return null;
    }
  }

  Future<List<GCalendar.Event>> getCalendarEventsList({
    required DateTime startTime,
    required DateTime endTime,
    String calendarId = 'primary',
  }) async {
    final GCalendar.CalendarApi? calendarApi = await getCalendarApi();
    if (calendarApi == null) {
      print('Calendar API not initialized or user not signed in for fetching events.');
      return [];
    }

    try {
      final GCalendar.Events events = await calendarApi.events.list(
        calendarId,
        timeMin: startTime.toUtc(),
        timeMax: endTime.toUtc(),
        singleEvents: true, // Expands recurring events into single instances
        orderBy: 'startTime',
      );
      return events.items ?? [];
    } catch (e) {
      print('Error fetching calendar events: $e');
      return [];
    }
  }

  Future<void> deleteTaskEvent({
    required String eventId,
    String calendarId = 'primary',
  }) async {
    final GCalendar.CalendarApi? calendarApi = await getCalendarApi();
    if (calendarApi == null) {
      print('Calendar API not initialized or user not signed in for deleting event.');
      return;
    }
    if (eventId.isEmpty) {
      print('Event ID is empty, cannot delete.');
      return;
    }

    try {
      await calendarApi.events.delete(calendarId, eventId);
      print('Event deleted from Google Calendar: $eventId');
    } catch (e) {
      print('Error deleting event from Google Calendar: $e');
      // Decide if you want to throw the error or handle it silently
    }
  }
} 