import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rihla/app.dart';
import 'package:rihla/config/api_config.dart';
import 'package:rihla/core/providers/app_providers.dart';
import 'package:rihla/features/account/presentation/providers/account_providers.dart';
import 'package:rihla/features/offline/presentation/widgets/offline_bootstrap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  if (ApiConfig.cloudEnabled) {
    await Supabase.initialize(
      url: ApiConfig.supabaseUrl!,
      anonKey: ApiConfig.supabaseAnonKey!,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const _AccountBootstrap(child: OfflineBootstrap(child: App())),
    ),
  );
}

class _AccountBootstrap extends ConsumerStatefulWidget {
  const _AccountBootstrap({required this.child});

  final Widget child;

  @override
  ConsumerState<_AccountBootstrap> createState() => _AccountBootstrapState();
}

class _AccountBootstrapState extends ConsumerState<_AccountBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountControllerProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
