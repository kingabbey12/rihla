import 'package:rihla/features/account/domain/entities/auth_session.dart';
import 'package:rihla/features/account/domain/entities/cloud_conflict.dart';
import 'package:rihla/features/account/domain/entities/cloud_sync_state.dart';
import 'package:rihla/features/account/domain/entities/user_profile.dart';

/// Account and authentication UI state.
sealed class AccountState {
  const AccountState();
}

class AccountInitial extends AccountState {
  const AccountInitial();
}

class AccountLoading extends AccountState {
  const AccountLoading();
}

class AccountGuest extends AccountState {
  const AccountGuest({required this.session});

  final AuthSession session;
}

class AccountSignedIn extends AccountState {
  const AccountSignedIn({
    required this.session,
    required this.profile,
    required this.syncState,
    this.conflicts = const [],
  });

  final AuthSession session;
  final UserProfile profile;
  final CloudSyncState syncState;
  final List<CloudConflict> conflicts;
}

class AccountError extends AccountState {
  const AccountError({required this.message, this.previous});

  final String message;
  final AccountState? previous;
}
