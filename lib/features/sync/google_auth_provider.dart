import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:quicktasks/data/remote/gcal_api_client.dart';

/// Provider for the GoogleSignIn configurations.
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    clientId: Platform.isAndroid
        ? null
        : '317034685883-dvmomrhfl9j6pjgfm71a0o1q6jjcmqdl.apps.googleusercontent.com',
    scopes: [cal.CalendarApi.calendarScope],
  );
});

/// A StateNotifier to manage Google Authentication state and methods.
class GoogleAuthNotifier extends StateNotifier<GoogleSignInAccount?> {
  final GoogleSignIn _googleSignIn;

  GoogleAuthNotifier(this._googleSignIn) : super(null) {
    signInSilently();
  }

  /// Attempts to sign in silently using cached credentials.
  Future<void> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      state = account;
    } catch (e, stack) {
      developer.log(
        'Google silent sign-in failed',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// Initiates interactive Google OAuth sign in flow.
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        state = account;
        return true;
      }
    } catch (e, stack) {
      developer.log(
        'Google interactive sign-in error',
        error: e,
        stackTrace: stack,
      );
    }
    return false;
  }

  /// Signs the user out from Google.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      state = null;
    } catch (e, stack) {
      developer.log('Google sign-out error', error: e, stackTrace: stack);
    }
  }
}

/// Provider that exposes the current signed-in Google account (if any).
final googleAuthNotifierProvider =
    StateNotifierProvider<GoogleAuthNotifier, GoogleSignInAccount?>((ref) {
      final signIn = ref.watch(googleSignInProvider);
      return GoogleAuthNotifier(signIn);
    });

/// Provider for the async OAuth headers (e.g. auth tokens).
final authHeadersProvider = FutureProvider<Map<String, String>?>((ref) async {
  final user = ref.watch(googleAuthNotifierProvider);
  if (user == null) return null;
  return await user.authHeaders;
});

/// Provider for the GCalApiClient, dynamically updated when authentication headers change.
final gcalApiClientProvider = Provider<GCalApiClient?>((ref) {
  final headersAsync = ref.watch(authHeadersProvider);
  return headersAsync.when(
    data: (headers) {
      if (headers == null) return null;
      final authClient = GoogleAuthClient(headers);
      final calendarApi = cal.CalendarApi(authClient);
      return GCalApiClient(calendarApi);
    },
    loading: () => null,
    error: (err, stack) {
      developer.log(
        'Error loading auth headers for API client',
        error: err,
        stackTrace: stack,
      );
      return null;
    },
  );
});
final googleCalendarSignInStateProvider = Provider<bool>((ref) {
  return ref.watch(googleAuthNotifierProvider) != null;
});
