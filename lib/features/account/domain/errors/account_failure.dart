/// Typed account failures.
sealed class AccountFailure implements Exception {
  const AccountFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

class AccountAuthFailure extends AccountFailure {
  const AccountAuthFailure(super.message);
}

class AccountSyncFailure extends AccountFailure {
  const AccountSyncFailure(super.message);
}

class AccountOfflineFailure extends AccountFailure {
  const AccountOfflineFailure() : super('Account sync unavailable while offline');
}

class AccountConflictFailure extends AccountFailure {
  const AccountConflictFailure(super.message);
}

class AccountNotSignedInFailure extends AccountFailure {
  const AccountNotSignedInFailure()
      : super('Sign in required for this action');
}
