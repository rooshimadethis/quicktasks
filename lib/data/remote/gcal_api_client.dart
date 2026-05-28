import 'package:http/http.dart' as http;
import 'package:googleapis/calendar/v3.dart' as cal;

/// An authenticated HTTP Client wrapper that automatically appends the 
/// OAuth authorization headers (e.g. Bearer Token) to all requests.
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Inject the authentication headers (e.g. Authorization: Bearer <token>)
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
    super.close();
  }
}

/// A wrapper client for executing calls to the Google Calendar API.
class GCalApiClient {
  final cal.CalendarApi _calendarApi;

  GCalApiClient(this._calendarApi);

  /// Lists all calendars in the user's Google Calendar list.
  Future<cal.CalendarList> listCalendars() async {
    return await _calendarApi.calendarList.list();
  }

  /// Creates a new calendar with the given title/summary.
  Future<cal.Calendar> createCalendar(String summary) async {
    final calendar = cal.Calendar()..summary = summary;
    return await _calendarApi.calendars.insert(calendar);
  }

  /// Fetches events from a specific calendar.
  /// 
  /// If [syncToken] is provided, GCal will only return events that have changed
  /// since that sync token was generated. Otherwise, it will fetch events
  /// within the [timeMin] and [timeMax] window.
  Future<cal.Events> listEvents(
    String calendarId, {
    String? syncToken,
    DateTime? timeMin,
    DateTime? timeMax,
  }) async {
    return await _calendarApi.events.list(
      calendarId,
      syncToken: syncToken,
      timeMin: timeMin?.toUtc(),
      timeMax: timeMax?.toUtc(),
      eventTypes: ['default'], // Excludes focus time, out-of-office, etc.
    );
  }

  /// Inserts a new event into the specified calendar.
  Future<cal.Event> insertEvent(String calendarId, cal.Event event) async {
    return await _calendarApi.events.insert(event, calendarId);
  }

  /// Updates (fully replaces) an existing event in the specified calendar.
  Future<cal.Event> updateEvent(
    String calendarId,
    String eventId,
    cal.Event event,
  ) async {
    return await _calendarApi.events.update(event, calendarId, eventId);
  }

  /// Patches an existing event in the specified calendar.
  Future<cal.Event> patchEvent(
    String calendarId,
    String eventId,
    cal.Event event,
  ) async {
    return await _calendarApi.events.patch(event, calendarId, eventId);
  }

  /// Deletes an event from the specified calendar.
  Future<void> deleteEvent(String calendarId, String eventId) async {
    await _calendarApi.events.delete(calendarId, eventId);
  }
}
