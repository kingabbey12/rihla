import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rihla/features/account/domain/entities/user_vehicle.dart';
import 'package:rihla/features/account/domain/models/account_state.dart';
import 'package:rihla/features/account/presentation/providers/account_providers.dart';
import 'package:rihla/features/profile/presentation/widgets/profile_header.dart';
import 'package:rihla/features/profile/presentation/widgets/profile_preference_group.dart';
import 'package:rihla/features/profile/presentation/widgets/profile_saved_place_card.dart';
import 'package:rihla/features/profile/presentation/widgets/profile_section.dart';
import 'package:rihla/features/profile/presentation/widgets/profile_vehicle_card.dart';
import 'package:rihla/features/search/presentation/providers/search_providers.dart';
import 'package:rihla/localization/locale_provider.dart';
import 'package:rihla/routes/route_paths.dart';
import 'package:rihla/shared/widgets/empty_screen.dart';
import 'package:rihla/theme/theme_provider.dart';

/// Premium Profile — the driver's personal dashboard inside Rihla.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _notifications = true;

  static const _emptyVehicle = UserVehicle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final account = ref.watch(accountControllerProvider);
    final profile = switch (account) {
      AccountSignedIn(:final profile) => profile,
      _ => null,
    };
    final name = profile?.name?.isNotEmpty == true ? profile!.name! : 'Guest';
    final email = profile?.email ?? '';

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 280,
            backgroundColor: const Color(0xFF0E2A33),
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () => context.push(RoutePaths.settings),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: _CollapsedTitle(name: name),
              background: ProfileHeader(
                name: name,
                email: email,
                membership: account is AccountSignedIn ? 'Rihla Member' : 'Guest',
                drivingScore: 0,
                journeyLevel: 1,
                photoUrl: profile?.photoUrl,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProfileSection(
                    title: 'Driving statistics',
                    icon: Icons.insights_rounded,
                  ),
                  _StatisticsGrid(),
                  const SizedBox(height: 28),
                  ProfileSection(
                    title: 'Journey history',
                    icon: Icons.history_rounded,
                    actionLabel: 'See all',
                    onAction: () {},
                  ),
                  _JourneyHistory(),
                  const SizedBox(height: 20),
                  ProfileSection(
                    title: 'Saved places',
                    icon: Icons.bookmark_rounded,
                    actionLabel: 'Manage',
                    onAction: () => context.push(RoutePaths.search),
                  ),
                  const _SavedPlaces(),
                  const SizedBox(height: 28),
                  const ProfileSection(
                    title: 'My vehicles',
                    icon: Icons.directions_car_rounded,
                  ),
                  if (_emptyVehicle.isEmpty)
                    const EmptyScreen(
                      title: 'No vehicles yet',
                      message: 'Add your vehicle to unlock roadside and insurance features.',
                      icon: Icons.directions_car_outlined,
                    )
                  else
                    ProfileVehicleCard(
                      vehicle: _emptyVehicle,
                      isPrimary: true,
                      onEdit: () => _snack('Edit vehicle'),
                    ),
                  const SizedBox(height: 28),
                  const ProfileSection(
                    title: 'Achievements',
                    icon: Icons.military_tech_rounded,
                  ),
                  _Achievements(),
                  const SizedBox(height: 28),
                  const ProfileSection(
                    title: 'Preferences',
                    icon: Icons.tune_rounded,
                  ),
                  _Preferences(
                    notifications: _notifications,
                    onNotifications: (v) => setState(() => _notifications = v),
                  ),
                  const SizedBox(height: 24),
                  _SignOutButton(signedIn: account is AccountSignedIn),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _CollapsedTitle extends StatelessWidget {
  const _CollapsedTitle({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    // Only show the name once the bar is mostly collapsed.
    final settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final deltaExtent = settings == null
        ? 0
        : settings.maxExtent - settings.minExtent;
    final t = settings == null || deltaExtent <= 0
        ? 0.0
        : (1 - (settings.currentExtent - settings.minExtent) / deltaExtent)
            .clamp(0.0, 1.0);
    return Opacity(
      opacity: t > 0.6 ? (t - 0.6) / 0.4 : 0,
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const EmptyScreen(
      title: 'No driving statistics yet',
      message: 'Complete your first journey to see trips, distance, and hours driven.',
      icon: Icons.insights_outlined,
    );
  }
}

class _JourneyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const EmptyScreen(
      title: 'No journeys yet',
      message: 'Your completed trips will appear here with scores and reviews.',
      icon: Icons.history_rounded,
    );
  }
}

class _SavedPlaces extends ConsumerWidget {
  const _SavedPlaces();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(searchHomeProvider).value;
    final work = ref.watch(searchWorkProvider).value;
    final favorites = ref.watch(searchFavoritesProvider).value ?? const [];

    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          ProfileSavedPlaceCard(
            icon: Icons.home_rounded,
            title: 'Home',
            subtitle: home?.name ?? 'Tap to set',
            gradient: const [Color(0xFF1FB6A6), Color(0xFF31C5C7)],
            isSet: home != null,
            onTap: () => context.push(RoutePaths.search),
          ),
          const SizedBox(width: 12),
          ProfileSavedPlaceCard(
            icon: Icons.work_rounded,
            title: 'Work',
            subtitle: work?.name ?? 'Tap to set',
            gradient: const [Color(0xFF2563EB), Color(0xFF5B8DEF)],
            isSet: work != null,
            onTap: () => context.push(RoutePaths.search),
          ),
          const SizedBox(width: 12),
          ProfileSavedPlaceCard(
            icon: Icons.favorite_rounded,
            title: 'Favorites',
            subtitle: '${favorites.length} places',
            gradient: const [Color(0xFFE53935), Color(0xFFFF6F60)],
            isSet: favorites.isNotEmpty,
            onTap: () => context.push(RoutePaths.search),
          ),
          const SizedBox(width: 12),
          ProfileSavedPlaceCard(
            icon: Icons.add_rounded,
            title: 'New collection',
            subtitle: 'Group places',
            gradient: const [Color(0xFF7C5CFF), Color(0xFF9D7BFF)],
            isSet: false,
            onTap: () => context.push(RoutePaths.search),
          ),
        ],
      ),
    );
  }
}

class _Achievements extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const EmptyScreen(
      title: 'No achievements yet',
      message: 'Drive safely and explore to unlock badges and milestones.',
      icon: Icons.military_tech_outlined,
    );
  }
}

class _Preferences extends ConsumerWidget {
  const _Preferences({
    required this.notifications,
    required this.onNotifications,
  });

  final bool notifications;
  final ValueChanged<bool> onNotifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final highContrast = ref.watch(highContrastProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Column(
      children: [
        ProfilePreferenceGroup(
          children: [
            ProfilePreferenceTile(
              icon: Icons.dark_mode_rounded,
              title: 'Dark mode',
              color: const Color(0xFF7C5CFF),
              trailing: Switch(
                value: isDark,
                onChanged: (_) =>
                    ref.read(themeModeProvider.notifier).toggleLightDark(),
              ),
            ),
            ProfilePreferenceTile(
              icon: Icons.contrast_rounded,
              title: 'High contrast',
              color: const Color(0xFF455A64),
              trailing: Switch(
                value: highContrast,
                onChanged: (_) =>
                    ref.read(highContrastProvider.notifier).toggle(),
              ),
            ),
            ProfilePreferenceTile(
              icon: Icons.language_rounded,
              title: 'Language',
              color: const Color(0xFF1FB6A6),
              value: locale.languageCode == 'ar' ? 'العربية' : 'English',
              onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
            ),
            ProfilePreferenceTile(
              icon: Icons.straighten_rounded,
              title: 'Units',
              color: const Color(0xFF2563EB),
              value: 'Kilometers',
              onTap: () => _snack(context, 'Units'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ProfilePreferenceGroup(
          children: [
            ProfilePreferenceTile(
              icon: Icons.record_voice_over_rounded,
              title: 'Voice & AI',
              color: const Color(0xFF31C5C7),
              value: 'On',
              onTap: () => context.push(RoutePaths.aiHome),
            ),
            ProfilePreferenceTile(
              icon: Icons.notifications_rounded,
              title: 'Notifications',
              color: const Color(0xFFF57C00),
              trailing: Switch(
                value: notifications,
                onChanged: onNotifications,
              ),
            ),
            ProfilePreferenceTile(
              icon: Icons.download_rounded,
              title: 'Offline maps',
              color: const Color(0xFF2E7D32),
              onTap: () => context.push(RoutePaths.offlineCenter),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ProfilePreferenceGroup(
          children: [
            ProfilePreferenceTile(
              icon: Icons.cloud_done_rounded,
              title: 'Cloud sync',
              color: const Color(0xFF5B8DEF),
              value: 'Settings',
              onTap: () => context.push(RoutePaths.settings),
            ),
            ProfilePreferenceTile(
              icon: Icons.shield_rounded,
              title: 'Privacy',
              color: const Color(0xFF455A64),
              onTap: () => context.push(RoutePaths.settings),
            ),
            ProfilePreferenceTile(
              icon: Icons.public_rounded,
              title: 'UAE preferences',
              color: const Color(0xFF2E7D32),
              onTap: () => context.push(RoutePaths.uaeSettings),
            ),
          ],
        ),
      ],
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton({required this.signedIn});

  final bool signedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          if (signedIn) {
            ref.read(accountControllerProvider.notifier).signOut();
          } else {
            context.push(RoutePaths.authentication);
          }
        },
        icon: Icon(signedIn ? Icons.logout_rounded : Icons.login_rounded),
        label: Text(signedIn ? 'Sign out' : 'Sign in'),
        style: OutlinedButton.styleFrom(
          foregroundColor: signedIn ? theme.colorScheme.error : null,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(
            color: (signedIn ? theme.colorScheme.error : theme.colorScheme.primary)
                .withValues(alpha: 0.4),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
