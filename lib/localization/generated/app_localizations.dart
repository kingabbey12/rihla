import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Rihla'**
  String get appTitle;

  /// No description provided for @loadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingMessage;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this content. Please try again.'**
  String get errorMessage;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retryButton;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyTitle;

  /// No description provided for @emptyMessage.
  ///
  /// In en, this message translates to:
  /// **'There is no content to display.'**
  String get emptyMessage;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @featureAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Authentication'**
  String get featureAuthentication;

  /// No description provided for @featureHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get featureHome;

  /// No description provided for @featureMaps.
  ///
  /// In en, this message translates to:
  /// **'Maps'**
  String get featureMaps;

  /// No description provided for @featureNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get featureNavigation;

  /// No description provided for @featureExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get featureExplore;

  /// No description provided for @featureEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get featureEmergency;

  /// No description provided for @featureAi.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get featureAi;

  /// No description provided for @featureProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get featureProfile;

  /// No description provided for @featureVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get featureVehicles;

  /// No description provided for @featureFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get featureFamily;

  /// No description provided for @featureSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get featureSettings;

  /// No description provided for @featureNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get featureNotifications;

  /// No description provided for @featurePlaceholderMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature is coming soon.'**
  String get featurePlaceholderMessage;

  /// No description provided for @brandTagline.
  ///
  /// In en, this message translates to:
  /// **'Your AI Journey Companion'**
  String get brandTagline;

  /// No description provided for @welcomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Rihla'**
  String get welcomeHeadline;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Navigate smarter.\nDrive safer.\nTravel confidently.'**
  String get welcomeSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @startMyJourney.
  ///
  /// In en, this message translates to:
  /// **'Start My Journey'**
  String get startMyJourney;

  /// No description provided for @onboardingAiNavigationTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Navigation'**
  String get onboardingAiNavigationTitle;

  /// No description provided for @onboardingAiNavigationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rihla recommends the safest, fastest, and smartest routes tailored to your journey.'**
  String get onboardingAiNavigationSubtitle;

  /// No description provided for @onboardingOfflineMapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline Maps'**
  String get onboardingOfflineMapsTitle;

  /// No description provided for @onboardingOfflineMapsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Navigation continues seamlessly even when you lose your internet connection.'**
  String get onboardingOfflineMapsSubtitle;

  /// No description provided for @onboardingRoadSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Road Safety'**
  String get onboardingRoadSafetyTitle;

  /// No description provided for @onboardingRoadSafetySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive AI-powered alerts for hazards, speed cameras, weather, and road conditions.'**
  String get onboardingRoadSafetySubtitle;

  /// No description provided for @onboardingEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Assistance'**
  String get onboardingEmergencyTitle;

  /// No description provided for @onboardingEmergencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Access SOS, accident reporting, roadside assistance, and emergency features when you need them most.'**
  String get onboardingEmergencySubtitle;

  /// No description provided for @permissionAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get permissionAllow;

  /// No description provided for @permissionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get permissionNotNow;

  /// No description provided for @permissionLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get permissionLocationTitle;

  /// No description provided for @permissionLocationExplanation.
  ///
  /// In en, this message translates to:
  /// **'Rihla needs your location to provide turn-by-turn navigation and accurate route guidance.'**
  String get permissionLocationExplanation;

  /// No description provided for @permissionNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get permissionNotificationsTitle;

  /// No description provided for @permissionNotificationsExplanation.
  ///
  /// In en, this message translates to:
  /// **'Stay informed with safety alerts, route updates, and important navigation notifications.'**
  String get permissionNotificationsExplanation;

  /// No description provided for @permissionCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Camera'**
  String get permissionCameraTitle;

  /// No description provided for @permissionCameraExplanation.
  ///
  /// In en, this message translates to:
  /// **'Use your camera for accident reporting, SOS documentation, and roadside assistance.'**
  String get permissionCameraExplanation;

  /// No description provided for @permissionMicrophoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Microphone'**
  String get permissionMicrophoneTitle;

  /// No description provided for @permissionMicrophoneExplanation.
  ///
  /// In en, this message translates to:
  /// **'Enable voice commands and hands-free emergency communication while driving.'**
  String get permissionMicrophoneExplanation;

  /// No description provided for @permissionBackgroundLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Background Location'**
  String get permissionBackgroundLocationTitle;

  /// No description provided for @permissionBackgroundLocationExplanation.
  ///
  /// In en, this message translates to:
  /// **'Allow Rihla to continue guiding you when the app is running in the background.'**
  String get permissionBackgroundLocationExplanation;

  /// No description provided for @authEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Rihla'**
  String get authEntryTitle;

  /// No description provided for @authEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account or sign in to sync your journeys across devices.'**
  String get authEntrySubtitle;

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get continueWithEmail;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @authLegalPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our'**
  String get authLegalPrefix;

  /// No description provided for @authLegalAnd.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get authLegalAnd;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTitle;

  /// No description provided for @mapLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading map…'**
  String get mapLoading;

  /// No description provided for @mapErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Map failed to load'**
  String get mapErrorTitle;

  /// No description provided for @mapErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the map. Check your connection and try again.'**
  String get mapErrorMessage;

  /// No description provided for @mapRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get mapRetry;

  /// No description provided for @mapLocationUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get mapLocationUnavailableTitle;

  /// No description provided for @mapLocationUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find your current location. Make sure location services are on.'**
  String get mapLocationUnavailableMessage;

  /// No description provided for @mapDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get mapDismiss;

  /// No description provided for @mapRecenter.
  ///
  /// In en, this message translates to:
  /// **'Reset orientation'**
  String get mapRecenter;

  /// No description provided for @mapZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get mapZoomIn;

  /// No description provided for @mapZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get mapZoomOut;

  /// No description provided for @mapMyLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get mapMyLocation;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a place'**
  String get searchHint;

  /// No description provided for @searchRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get searchRecentTitle;

  /// No description provided for @searchClearRecent.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get searchClearRecent;

  /// No description provided for @searchSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get searchSavedTitle;

  /// No description provided for @searchHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get searchHome;

  /// No description provided for @searchWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get searchWork;

  /// No description provided for @searchFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get searchFavorites;

  /// No description provided for @searchAddHome.
  ///
  /// In en, this message translates to:
  /// **'Add Home'**
  String get searchAddHome;

  /// No description provided for @searchAddWork.
  ///
  /// In en, this message translates to:
  /// **'Add Work'**
  String get searchAddWork;

  /// No description provided for @searchNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get searchNoFavorites;

  /// No description provided for @searchSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get searchSuggestionsTitle;

  /// No description provided for @searchLoading.
  ///
  /// In en, this message translates to:
  /// **'Searching…'**
  String get searchLoading;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different place name or address.'**
  String get searchEmptyMessage;

  /// No description provided for @searchErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Search unavailable'**
  String get searchErrorTitle;

  /// No description provided for @searchErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t complete your search. Please try again.'**
  String get searchErrorMessage;

  /// No description provided for @searchRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get searchRetry;

  /// No description provided for @searchSetAsHome.
  ///
  /// In en, this message translates to:
  /// **'Set as Home'**
  String get searchSetAsHome;

  /// No description provided for @searchSetAsWork.
  ///
  /// In en, this message translates to:
  /// **'Set as Work'**
  String get searchSetAsWork;

  /// No description provided for @searchAddToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get searchAddToFavorites;

  /// No description provided for @searchRemoveFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get searchRemoveFromFavorites;

  /// No description provided for @searchOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open on map'**
  String get searchOpenMap;

  /// No description provided for @searchWhereTo.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get searchWhereTo;

  /// No description provided for @journeyPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning your journey…'**
  String get journeyPlanning;

  /// No description provided for @journeyDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get journeyDestination;

  /// No description provided for @journeyDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get journeyDistance;

  /// No description provided for @journeyDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get journeyDuration;

  /// No description provided for @journeyScore.
  ///
  /// In en, this message translates to:
  /// **'Journey Score'**
  String get journeyScore;

  /// No description provided for @journeySafetyScore.
  ///
  /// In en, this message translates to:
  /// **'Safety Score'**
  String get journeySafetyScore;

  /// No description provided for @journeyWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get journeyWeather;

  /// No description provided for @journeyTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get journeyTraffic;

  /// No description provided for @journeyFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel Estimate'**
  String get journeyFuel;

  /// No description provided for @journeyBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery Estimate'**
  String get journeyBattery;

  /// No description provided for @journeyRoadConditions.
  ///
  /// In en, this message translates to:
  /// **'Road Conditions'**
  String get journeyRoadConditions;

  /// No description provided for @journeyDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure Suggestions'**
  String get journeyDeparture;

  /// No description provided for @journeyAiSummary.
  ///
  /// In en, this message translates to:
  /// **'AI Journey Summary'**
  String get journeyAiSummary;

  /// No description provided for @journeyStart.
  ///
  /// In en, this message translates to:
  /// **'Start Journey'**
  String get journeyStart;

  /// No description provided for @journeyCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get journeyCancel;

  /// No description provided for @journeyErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Journey unavailable'**
  String get journeyErrorTitle;

  /// No description provided for @journeyErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t plan this journey. Please try again.'**
  String get journeyErrorMessage;

  /// No description provided for @journeyRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get journeyRetry;

  /// No description provided for @journeyStartedMessage.
  ///
  /// In en, this message translates to:
  /// **'Journey confirmed — turn-by-turn navigation arrives in the next phase.'**
  String get journeyStartedMessage;

  /// No description provided for @journeyTrafficLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get journeyTrafficLight;

  /// No description provided for @journeyTrafficModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get journeyTrafficModerate;

  /// No description provided for @journeyTrafficHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get journeyTrafficHeavy;

  /// No description provided for @journeyRoadExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get journeyRoadExcellent;

  /// No description provided for @journeyRoadGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get journeyRoadGood;

  /// No description provided for @journeyRoadFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get journeyRoadFair;

  /// No description provided for @journeyRoadPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get journeyRoadPoor;

  /// No description provided for @journeyKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String journeyKm(String distance);

  /// No description provided for @journeyMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String journeyMinutes(int minutes);

  /// No description provided for @journeyLiters.
  ///
  /// In en, this message translates to:
  /// **'{liters} L'**
  String journeyLiters(String liters);

  /// No description provided for @journeyBatteryPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String journeyBatteryPercent(String percent);

  /// No description provided for @journeyTemperature.
  ///
  /// In en, this message translates to:
  /// **'{temp}°C'**
  String journeyTemperature(String temp);

  /// No description provided for @routeCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating routes…'**
  String get routeCalculating;

  /// No description provided for @routeChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your route'**
  String get routeChooseTitle;

  /// No description provided for @routeChooseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the journey style that fits you best'**
  String get routeChooseSubtitle;

  /// No description provided for @routeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Route'**
  String get routeConfirm;

  /// No description provided for @routeCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get routeCancel;

  /// No description provided for @routeErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Routing unavailable'**
  String get routeErrorTitle;

  /// No description provided for @routeErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t calculate routes. Please try again.'**
  String get routeErrorMessage;

  /// No description provided for @routeRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get routeRetry;

  /// No description provided for @routeConfirmedMessage.
  ///
  /// In en, this message translates to:
  /// **'Route confirmed — your live journey dashboard is active.'**
  String get routeConfirmedMessage;

  /// No description provided for @routeProfileSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get routeProfileSafe;

  /// No description provided for @routeProfileFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get routeProfileFast;

  /// No description provided for @routeProfileEco.
  ///
  /// In en, this message translates to:
  /// **'Eco'**
  String get routeProfileEco;

  /// No description provided for @routeProfileScenic.
  ///
  /// In en, this message translates to:
  /// **'Scenic'**
  String get routeProfileScenic;

  /// No description provided for @routeDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get routeDistance;

  /// No description provided for @routeDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get routeDuration;

  /// No description provided for @routeJourneyScore.
  ///
  /// In en, this message translates to:
  /// **'Journey Score'**
  String get routeJourneyScore;

  /// No description provided for @routeFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get routeFuel;

  /// No description provided for @routeTraffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get routeTraffic;

  /// No description provided for @routeSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get routeSafety;

  /// No description provided for @liveJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Journey'**
  String get liveJourneyTitle;

  /// No description provided for @liveJourneyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Journey in progress'**
  String get liveJourneyInProgress;

  /// No description provided for @liveJourneyExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand dashboard'**
  String get liveJourneyExpand;

  /// No description provided for @liveJourneyCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse dashboard'**
  String get liveJourneyCollapse;

  /// No description provided for @liveJourneyFloat.
  ///
  /// In en, this message translates to:
  /// **'Float dashboard'**
  String get liveJourneyFloat;

  /// No description provided for @liveJourneyEta.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get liveJourneyEta;

  /// No description provided for @liveJourneyArrivalTime.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get liveJourneyArrivalTime;

  /// No description provided for @liveJourneyRemainingDistance.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get liveJourneyRemainingDistance;

  /// No description provided for @liveJourneyCurrentSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get liveJourneyCurrentSpeed;

  /// No description provided for @liveJourneyCurrentRoad.
  ///
  /// In en, this message translates to:
  /// **'Current road'**
  String get liveJourneyCurrentRoad;

  /// No description provided for @liveJourneyNextManeuver.
  ///
  /// In en, this message translates to:
  /// **'Next maneuver'**
  String get liveJourneyNextManeuver;

  /// No description provided for @liveJourneyTrafficScore.
  ///
  /// In en, this message translates to:
  /// **'Traffic Score'**
  String get liveJourneyTrafficScore;

  /// No description provided for @liveJourneySpeedKmh.
  ///
  /// In en, this message translates to:
  /// **'{speed} km/h'**
  String liveJourneySpeedKmh(int speed);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
