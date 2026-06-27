import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/features/account/domain/entities/cloud_sync_state.dart';
import 'package:rihla/features/account/domain/entities/conflict_resolution_strategy.dart';
import 'package:rihla/features/account/domain/entities/sync_category.dart';
import 'package:rihla/features/account/domain/models/account_state.dart';
import 'package:rihla/features/account/presentation/providers/account_providers.dart';

/// Cloud account settings — sync status, privacy, sign out, data export.
class CloudSettingsPage extends ConsumerWidget {
  const CloudSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(accountControllerProvider);
    final privacy = ref.watch(accountPrivacySettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud & Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AccountHeader(state: accountState),
          const SizedBox(height: 24),
          if (accountState is AccountSignedIn) ...[
            _SyncStatusCard(state: accountState),
            const SizedBox(height: 16),
            Text(
              'Sync Privacy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...SyncCategory.values
                .where((c) => c.hasPrivacyToggle)
                .map(
                  (category) => SwitchListTile(
                    title: Text(category.displayName),
                    subtitle: Text(
                      privacy.isEnabled(category)
                          ? 'Cloud sync enabled'
                          : 'Local only',
                    ),
                    value: privacy.isEnabled(category),
                    onChanged: (value) => ref
                        .read(accountControllerProvider.notifier)
                        .togglePrivacyCategory(category, value),
                  ),
                ),
            if (accountState.conflicts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Conflicts (${accountState.conflicts.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ...accountState.conflicts.map(
                (c) => ListTile(
                  title: Text(c.category.displayName),
                  subtitle: Text(
                    'Local: ${c.localUpdatedAt}\nRemote: ${c.remoteUpdatedAt}',
                  ),
                  trailing: PopupMenuButton<ConflictResolutionStrategy>(
                    onSelected: (strategy) => ref
                        .read(accountControllerProvider.notifier)
                        .resolveConflict(c.id, strategy),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: ConflictResolutionStrategy.newestWins,
                        child: Text('Newest wins'),
                      ),
                      const PopupMenuItem(
                        value: ConflictResolutionStrategy.serverWins,
                        child: Text('Server wins'),
                      ),
                      const PopupMenuItem(
                        value: ConflictResolutionStrategy.localWins,
                        child: Text('Local wins'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref
                  .read(accountControllerProvider.notifier)
                  .synchronize(force: true),
              icon: const Icon(Icons.sync),
              label: const Text('Sync now'),
            ),
          ],
          if (accountState is AccountGuest) ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'You are using guest mode. Sign in to sync across devices.',
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Send beta feedback'),
            subtitle: const Text('Report bugs, routing issues, or journey feedback'),
            onTap: () => context.push(RoutePaths.betaFeedback),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export data'),
            onTap: () async {
              final data = await ref
                  .read(accountControllerProvider.notifier)
                  .exportData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Exported ${data.length} bytes of account data',
                    ),
                  ),
                );
              }
            },
          ),
          if (accountState is AccountSignedIn ||
              accountState is AccountGuest) ...[
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () =>
                  ref.read(accountControllerProvider.notifier).signOut(),
            ),
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
              title: Text(
                'Delete account',
                style: TextStyle(color: Colors.red.shade700),
              ),
              onTap: () => _confirmDelete(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your cloud data and local account state.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(accountControllerProvider.notifier).deleteAccount();
    }
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.state});

  final AccountState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: switch (state) {
          AccountSignedIn(:final session, :final profile) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name ?? session.displayName ?? 'Signed in',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (session.email != null)
                  Text(
                    session.email!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                Text(
                  'Provider: ${session.provider.name}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          AccountGuest() => const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Guest mode'),
              subtitle: Text('Data stays on this device'),
            ),
          AccountLoading() => const Center(child: CircularProgressIndicator()),
          AccountError(:final message) => Text('Error: $message'),
          AccountInitial() => const ListTile(
              leading: Icon(Icons.account_circle_outlined),
              title: Text('Not signed in'),
            ),
        },
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({required this.state});

  final AccountSignedIn state;

  @override
  Widget build(BuildContext context) {
    final sync = state.syncState;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sync status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _StatusRow(label: 'Status', value: _statusLabel(sync.status)),
            _StatusRow(
              label: 'Last sync',
              value: sync.lastSyncAt?.toLocal().toString() ?? 'Never',
            ),
            _StatusRow(
              label: 'Pending writes',
              value: '${sync.pendingWrites}',
            ),
            _StatusRow(
              label: 'Conflicts',
              value: '${sync.conflictCount}',
            ),
            _StatusRow(
              label: 'Storage used',
              value: '${(sync.storageUsedBytes / 1024).toStringAsFixed(1)} KB',
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(CloudSyncStatus status) => switch (status) {
        CloudSyncStatus.idle => 'Up to date',
        CloudSyncStatus.syncing => 'Syncing…',
        CloudSyncStatus.error => 'Error',
        CloudSyncStatus.conflict => 'Conflicts',
        CloudSyncStatus.offline => 'Offline',
      };
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
