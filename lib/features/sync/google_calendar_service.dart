import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quicktasks/domain/repositories/calendar_item_repository.dart';
import 'package:quicktasks/features/sync/google_auth_provider.dart';

/// A service to coordinate synchronization of local items with Google Calendar.
class GoogleCalendarSyncService {
  final CalendarItemRepository _repository;
  final Ref _ref;

  GoogleCalendarSyncService(this._repository, this._ref);

  /// Triggers a sync session if the user is signed in.
  /// Returns true if the sync completed successfully.
  Future<bool> sync() async {
    final apiClient = _ref.read(gcalApiClientProvider);
    if (apiClient == null) {
      developer.log('Sync skipped: User is not authenticated with Google.');
      return false;
    }

    try {
      await _repository.sync(apiClient);
      return true;
    } catch (e, stack) {
      developer.log('Sync failed', error: e, stackTrace: stack);
      return false;
    }
  }
}

/// Provider for GoogleCalendarSyncService.
final googleCalendarServiceProvider = Provider<GoogleCalendarSyncService>((ref) {
  final repository = ref.watch(calendarItemRepositoryProvider);
  return GoogleCalendarSyncService(repository, ref);
});
