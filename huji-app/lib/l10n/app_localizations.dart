import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of HujiLocalizations
/// returned by `HujiLocalizations.of(context)`.
///
/// Applications need to include `HujiLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: HujiLocalizations.localizationsDelegates,
///   supportedLocales: HujiLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the HujiLocalizations.supportedLocales
/// property.
abstract class HujiLocalizations {
  HujiLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static HujiLocalizations of(BuildContext context) {
    return Localizations.of<HujiLocalizations>(context, HujiLocalizations)!;
  }

  static const LocalizationsDelegate<HujiLocalizations> delegate =
      _HujiLocalizationsDelegate();

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
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @aboutChangelogDescription.
  ///
  /// In en, this message translates to:
  /// **'We are committed to delivering the best video editing experience. Each update brings new features and improvements. Thank you for your support!'**
  String get aboutChangelogDescription;

  /// No description provided for @aboutChangelogTitle.
  ///
  /// In en, this message translates to:
  /// **'About changelog'**
  String get aboutChangelogTitle;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account & security'**
  String get accountAndSecurity;

  /// No description provided for @accountLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get accountLoggedIn;

  /// No description provided for @accountLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountLogout;

  /// No description provided for @accountMismatch.
  ///
  /// In en, this message translates to:
  /// **'The entered account does not match the current account'**
  String get accountMismatch;

  /// No description provided for @accountNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get accountNotLoggedIn;

  /// No description provided for @accountPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign-in status and profile'**
  String get accountPageSubtitle;

  /// No description provided for @accountTapToLogin.
  ///
  /// In en, this message translates to:
  /// **'Tap to sign in'**
  String get accountTapToLogin;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionConfirmWithCount.
  ///
  /// In en, this message translates to:
  /// **'Confirm ({count})'**
  String actionConfirmWithCount(int count);

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionCountdownSeconds.
  ///
  /// In en, this message translates to:
  /// **'{countdown}s'**
  String actionCountdownSeconds(int countdown);

  /// No description provided for @actionCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get actionExport;

  /// No description provided for @actionGetVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Get code'**
  String get actionGetVerificationCode;

  /// No description provided for @actionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get actionPause;

  /// No description provided for @actionPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get actionPlay;

  /// No description provided for @actionProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get actionProcessing;

  /// No description provided for @actionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get actionRefresh;

  /// No description provided for @actionReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get actionReload;

  /// No description provided for @actionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// No description provided for @actionResendCodeCountdown.
  ///
  /// In en, this message translates to:
  /// **'Resend in {countdown}s'**
  String actionResendCodeCountdown(int countdown);

  /// No description provided for @actionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// No description provided for @actionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get actionResume;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// No description provided for @actionSendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get actionSendVerificationCode;

  /// No description provided for @actionShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get actionShare;

  /// No description provided for @actionTypeFireBall.
  ///
  /// In en, this message translates to:
  /// **'Serve'**
  String get actionTypeFireBall;

  /// No description provided for @actionTypePickBall.
  ///
  /// In en, this message translates to:
  /// **'Ball pickup'**
  String get actionTypePickBall;

  /// No description provided for @actionTypePlayBall.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get actionTypePlayBall;

  /// No description provided for @actionTypePlayback.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get actionTypePlayback;

  /// No description provided for @actionTypeTransition.
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get actionTypeTransition;

  /// No description provided for @actionView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get actionView;

  /// No description provided for @activeCpuCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Active CPUs'**
  String get activeCpuCountLabel;

  /// No description provided for @addClipSegmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Add segment'**
  String get addClipSegmentLabel;

  /// No description provided for @addMoreFiles.
  ///
  /// In en, this message translates to:
  /// **'+ Add more'**
  String get addMoreFiles;

  /// No description provided for @addSelectedFiles.
  ///
  /// In en, this message translates to:
  /// **'Add {count} file(s)'**
  String addSelectedFiles(int count);

  /// No description provided for @albumAllMediaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All {mediaType} files'**
  String albumAllMediaSubtitle(String mediaType);

  /// No description provided for @albumCount.
  ///
  /// In en, this message translates to:
  /// **'{count} album(s)'**
  String albumCount(int count);

  /// No description provided for @allRounds.
  ///
  /// In en, this message translates to:
  /// **'All rounds'**
  String get allRounds;

  /// No description provided for @analyzingVideoContent.
  ///
  /// In en, this message translates to:
  /// **'Analyzing video content...'**
  String get analyzingVideoContent;

  /// No description provided for @androidVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Android version'**
  String get androidVersionLabel;

  /// No description provided for @appFoldersTab.
  ///
  /// In en, this message translates to:
  /// **'App folders'**
  String get appFoldersTab;

  /// No description provided for @appNameLabel.
  ///
  /// In en, this message translates to:
  /// **'App name'**
  String get appNameLabel;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Huji'**
  String get appTitle;

  /// No description provided for @appVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersionLabel;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearancePageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, text size, and language'**
  String get appearancePageSubtitle;

  /// No description provided for @applyFilter.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get applyFilter;

  /// No description provided for @architectureLabel.
  ///
  /// In en, this message translates to:
  /// **'Architecture'**
  String get architectureLabel;

  /// No description provided for @authorize.
  ///
  /// In en, this message translates to:
  /// **'Authorize'**
  String get authorize;

  /// No description provided for @avatarUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload avatar: {error}'**
  String avatarUploadFailed(String error);

  /// No description provided for @avatarUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Avatar uploaded successfully'**
  String get avatarUploadSuccess;

  /// No description provided for @backToPreview.
  ///
  /// In en, this message translates to:
  /// **'↩ Back to preview'**
  String get backToPreview;

  /// No description provided for @backendClip.
  ///
  /// In en, this message translates to:
  /// **'Background clip'**
  String get backendClip;

  /// No description provided for @backgroundDownload.
  ///
  /// In en, this message translates to:
  /// **'Download in background'**
  String get backgroundDownload;

  /// No description provided for @backgroundMediaProcessingDescription.
  ///
  /// In en, this message translates to:
  /// **'Allows the app to process video compression in the background, even when you switch apps or lock the screen.'**
  String get backgroundMediaProcessingDescription;

  /// No description provided for @backgroundMediaProcessingPermission.
  ///
  /// In en, this message translates to:
  /// **'Background media processing permission'**
  String get backgroundMediaProcessingPermission;

  /// No description provided for @backgroundServicePermissionDeniedHint.
  ///
  /// In en, this message translates to:
  /// **'If you deny this permission, video compression will run in the foreground and may affect other apps.'**
  String get backgroundServicePermissionDeniedHint;

  /// No description provided for @backgroundServicePermissionIntro.
  ///
  /// In en, this message translates to:
  /// **'To keep video compression running in the background, please grant the following permission:'**
  String get backgroundServicePermissionIntro;

  /// No description provided for @backgroundServicePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Background service permission required'**
  String get backgroundServicePermissionTitle;

  /// No description provided for @badmintonAutoClipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic badminton match video clipping'**
  String get badmintonAutoClipSubtitle;

  /// No description provided for @badmintonDefaultPreset.
  ///
  /// In en, this message translates to:
  /// **'Badminton default'**
  String get badmintonDefaultPreset;

  /// No description provided for @badmintonMatchVideoClip.
  ///
  /// In en, this message translates to:
  /// **'Badminton match video clipping'**
  String get badmintonMatchVideoClip;

  /// No description provided for @badmintonVideoAutoClip.
  ///
  /// In en, this message translates to:
  /// **'Badminton auto clip'**
  String get badmintonVideoAutoClip;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic info'**
  String get basicInfo;

  /// No description provided for @batchSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get batchSelect;

  /// No description provided for @batchSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Selected {count}'**
  String batchSelectedCount(int count);

  /// No description provided for @batchTasksDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {count} task(s)'**
  String batchTasksDeleted(int count);

  /// No description provided for @booleanNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get booleanNo;

  /// No description provided for @booleanYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get booleanYes;

  /// No description provided for @browserDownload.
  ///
  /// In en, this message translates to:
  /// **'Download in browser'**
  String get browserDownload;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build number'**
  String get buildNumber;

  /// No description provided for @buildVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Build version'**
  String get buildVersionLabel;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cacheCleared;

  /// No description provided for @cachedBadge.
  ///
  /// In en, this message translates to:
  /// **'Cached'**
  String get cachedBadge;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @calculatingFileSize.
  ///
  /// In en, this message translates to:
  /// **'Calculating size...'**
  String get calculatingFileSize;

  /// No description provided for @cancelTask.
  ///
  /// In en, this message translates to:
  /// **'Cancel task'**
  String get cancelTask;

  /// No description provided for @cannotAccessDirectory.
  ///
  /// In en, this message translates to:
  /// **'Cannot access this directory: {error}'**
  String cannotAccessDirectory(String error);

  /// No description provided for @cannotGenerateThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Unable to generate thumbnail'**
  String get cannotGenerateThumbnail;

  /// No description provided for @cannotLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Unable to load video'**
  String get cannotLoadVideo;

  /// No description provided for @cannotOpenDownloadLink.
  ///
  /// In en, this message translates to:
  /// **'Unable to open download link'**
  String get cannotOpenDownloadLink;

  /// No description provided for @cannotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Unable to open link'**
  String get cannotOpenLink;

  /// No description provided for @cannotOpenLogViewer.
  ///
  /// In en, this message translates to:
  /// **'Cannot open log viewer: {error}'**
  String cannotOpenLogViewer(String error);

  /// No description provided for @cannotOpenLogViewerNavigatorNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'Cannot open log viewer: Navigator not initialized'**
  String get cannotOpenLogViewerNavigatorNotInitialized;

  /// No description provided for @changeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change avatar'**
  String get changeAvatar;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @changelog.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get changelog;

  /// No description provided for @checkAlbumPermissionOrEmpty.
  ///
  /// In en, this message translates to:
  /// **'Check album permissions or whether albums are empty'**
  String get checkAlbumPermissionOrEmpty;

  /// No description provided for @classNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Class name:'**
  String get classNameLabel;

  /// No description provided for @clearAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get clearAllFilters;

  /// No description provided for @clearAppCacheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear app cache'**
  String get clearAppCacheSubtitle;

  /// No description provided for @clearCacheFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear cache: {error}'**
  String clearCacheFailed(String error);

  /// No description provided for @clearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCacheTitle;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @clearLogsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clear logs: {error}'**
  String clearLogsFailed(String error);

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelection;

  /// No description provided for @clearTypeFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear type filter'**
  String get clearTypeFilter;

  /// No description provided for @clearedLogsOlderThan7Days.
  ///
  /// In en, this message translates to:
  /// **'Cleared logs older than 7 days'**
  String get clearedLogsOlderThan7Days;

  /// No description provided for @clipCompleted.
  ///
  /// In en, this message translates to:
  /// **'Clip completed!'**
  String get clipCompleted;

  /// No description provided for @clipConfig.
  ///
  /// In en, this message translates to:
  /// **'Clip settings'**
  String get clipConfig;

  /// No description provided for @clipMode.
  ///
  /// In en, this message translates to:
  /// **'Clip mode'**
  String get clipMode;

  /// No description provided for @clipOptions.
  ///
  /// In en, this message translates to:
  /// **'Clip options'**
  String get clipOptions;

  /// No description provided for @clipOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get clipOptionsTitle;

  /// No description provided for @clipRecords.
  ///
  /// In en, this message translates to:
  /// **'Clip records'**
  String get clipRecords;

  /// No description provided for @clipTaskCreatedRedirecting.
  ///
  /// In en, this message translates to:
  /// **'Clip task created. Redirecting to tasks...'**
  String get clipTaskCreatedRedirecting;

  /// No description provided for @clippingVideo.
  ///
  /// In en, this message translates to:
  /// **'Clipping video...'**
  String get clippingVideo;

  /// No description provided for @cloudClip.
  ///
  /// In en, this message translates to:
  /// **'Cloud clip'**
  String get cloudClip;

  /// No description provided for @cloudClipUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cloud clipping is unavailable'**
  String get cloudClipUnavailable;

  /// No description provided for @cloudDetection.
  ///
  /// In en, this message translates to:
  /// **'Cloud detection'**
  String get cloudDetection;

  /// No description provided for @cloudDetectionHelp.
  ///
  /// In en, this message translates to:
  /// **'Requires internet; higher accuracy'**
  String get cloudDetectionHelp;

  /// No description provided for @cloudDetectionHint.
  ///
  /// In en, this message translates to:
  /// **'Uses cloud services for detection; internet required'**
  String get cloudDetectionHint;

  /// No description provided for @cloudDetectionTaskName.
  ///
  /// In en, this message translates to:
  /// **'Cloud detection: {fileName}'**
  String cloudDetectionTaskName(String fileName);

  /// No description provided for @compressedSize.
  ///
  /// In en, this message translates to:
  /// **'Compressed size'**
  String get compressedSize;

  /// No description provided for @compressionRatio.
  ///
  /// In en, this message translates to:
  /// **'Compression ratio'**
  String get compressionRatio;

  /// No description provided for @compressionResults.
  ///
  /// In en, this message translates to:
  /// **'Compression results ({count} images)'**
  String compressionResults(int count);

  /// No description provided for @computerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Computer name'**
  String get computerNameLabel;

  /// No description provided for @configPresetMismatch.
  ///
  /// In en, this message translates to:
  /// **'{count} settings differ from \"{presetName}\"'**
  String configPresetMismatch(int count, String presetName);

  /// No description provided for @confirmBatchDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} selected task(s)? This cannot be undone.'**
  String confirmBatchDeleteMessage(int count);

  /// No description provided for @confirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Confirm cancel'**
  String get confirmCancel;

  /// No description provided for @confirmCancelTaskMessage.
  ///
  /// In en, this message translates to:
  /// **'Cancel task \"{taskName}\"? This cannot be undone.'**
  String confirmCancelTaskMessage(String taskName);

  /// No description provided for @confirmClearCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'Clear cache for this video?'**
  String get confirmClearCacheMessage;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm delete'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteCurrentPlayingRound.
  ///
  /// In en, this message translates to:
  /// **'Delete the currently playing round? This cannot be undone.'**
  String get confirmDeleteCurrentPlayingRound;

  /// No description provided for @confirmDeleteFileMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete this file? This cannot be undone.'**
  String get confirmDeleteFileMessage;

  /// No description provided for @confirmDeleteLocalVideoMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this local video?'**
  String get confirmDeleteLocalVideoMessage;

  /// No description provided for @confirmDeleteTaskMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete task \"{taskName}\"? This cannot be undone.'**
  String confirmDeleteTaskMessage(String taskName);

  /// No description provided for @confirmExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm export'**
  String get confirmExportTitle;

  /// No description provided for @confirmLogoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get confirmLogoutMessage;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @confirmPurchase.
  ///
  /// In en, this message translates to:
  /// **'Confirm purchase'**
  String get confirmPurchase;

  /// No description provided for @confirmSubscription.
  ///
  /// In en, this message translates to:
  /// **'Confirm subscription'**
  String get confirmSubscription;

  /// No description provided for @contactInfoPrefix.
  ///
  /// In en, this message translates to:
  /// **'Contact info: {contact}'**
  String contactInfoPrefix(String contact);

  /// No description provided for @contactOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Contact info (optional)'**
  String get contactOptionalHint;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @copyPath.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get copyPath;

  /// No description provided for @countdownSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String countdownSeconds(int seconds);

  /// No description provided for @createFolderFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create folder: {error}'**
  String createFolderFailedWithError(String error);

  /// No description provided for @createFolderHere.
  ///
  /// In en, this message translates to:
  /// **'New folder here'**
  String get createFolderHere;

  /// No description provided for @createTaskFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create task'**
  String get createTaskFailed;

  /// No description provided for @createTaskFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create task: {error}'**
  String createTaskFailedWithError(String error);

  /// No description provided for @createTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get createTimeLabel;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created at: {time}'**
  String createdAt(String time);

  /// No description provided for @createdAtWithValue.
  ///
  /// In en, this message translates to:
  /// **'Created: {time}'**
  String createdAtWithValue(String time);

  /// No description provided for @createdTimeRange.
  ///
  /// In en, this message translates to:
  /// **'Created time range'**
  String get createdTimeRange;

  /// No description provided for @creatingTask.
  ///
  /// In en, this message translates to:
  /// **'Creating task...'**
  String get creatingTask;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @currentDirectoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Current directory'**
  String get currentDirectoryLabel;

  /// No description provided for @currentDuration.
  ///
  /// In en, this message translates to:
  /// **'Current duration'**
  String get currentDuration;

  /// No description provided for @currentEditingRound.
  ///
  /// In en, this message translates to:
  /// **'Editing: {label}'**
  String currentEditingRound(String label);

  /// No description provided for @currentFile.
  ///
  /// In en, this message translates to:
  /// **'Current file: {path}'**
  String currentFile(String path);

  /// No description provided for @currentPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get currentPlanLabel;

  /// No description provided for @currentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get currentVersion;

  /// No description provided for @customClip.
  ///
  /// In en, this message translates to:
  /// **'Custom clip'**
  String get customClip;

  /// No description provided for @customerHotline.
  ///
  /// In en, this message translates to:
  /// **'Customer hotline'**
  String get customerHotline;

  /// No description provided for @dartVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Dart version'**
  String get dartVersionLabel;

  /// No description provided for @dataManagementSection.
  ///
  /// In en, this message translates to:
  /// **'Data management'**
  String get dataManagementSection;

  /// No description provided for @databaseDebugSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View database contents'**
  String get databaseDebugSubtitle;

  /// No description provided for @databaseDebugTitle.
  ///
  /// In en, this message translates to:
  /// **'Database debug'**
  String get databaseDebugTitle;

  /// No description provided for @dateRangeTo.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get dateRangeTo;

  /// No description provided for @debugFeaturesSection.
  ///
  /// In en, this message translates to:
  /// **'Debug features'**
  String get debugFeaturesSection;

  /// No description provided for @defaultHighlightName.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get defaultHighlightName;

  /// No description provided for @defaultPreset.
  ///
  /// In en, this message translates to:
  /// **'Default preset'**
  String get defaultPreset;

  /// No description provided for @deleteCurrentRound.
  ///
  /// In en, this message translates to:
  /// **'Delete current round'**
  String get deleteCurrentRound;

  /// No description provided for @deleteFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailedWithError(String error);

  /// No description provided for @deleteFile.
  ///
  /// In en, this message translates to:
  /// **'Delete file'**
  String get deleteFile;

  /// No description provided for @deleteTask.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get deleteTask;

  /// No description provided for @demoBadmintonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'~51s · sample video'**
  String get demoBadmintonSubtitle;

  /// No description provided for @demoBadmintonTitle.
  ///
  /// In en, this message translates to:
  /// **'Badminton demo'**
  String get demoBadmintonTitle;

  /// No description provided for @demoPingPongSubtitle.
  ///
  /// In en, this message translates to:
  /// **'~23s · sample video'**
  String get demoPingPongSubtitle;

  /// No description provided for @demoPingPongTitle.
  ///
  /// In en, this message translates to:
  /// **'Table tennis demo'**
  String get demoPingPongTitle;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @desktopDevice.
  ///
  /// In en, this message translates to:
  /// **'Desktop device'**
  String get desktopDevice;

  /// No description provided for @desktopLibraryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Click \"New clip\" to upload match footage'**
  String get desktopLibraryEmptyHint;

  /// No description provided for @desktopLibraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No videos yet'**
  String get desktopLibraryEmptyTitle;

  /// No description provided for @desktopLibraryItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String desktopLibraryItemCount(int count);

  /// No description provided for @desktopLibraryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String desktopLibraryLoadFailed(String error);

  /// No description provided for @desktopLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Video library'**
  String get desktopLibraryTitle;

  /// No description provided for @desktopNavLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get desktopNavLibrary;

  /// No description provided for @desktopNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get desktopNavSettings;

  /// No description provided for @desktopNavTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get desktopNavTasks;

  /// No description provided for @desktopNewClip.
  ///
  /// In en, this message translates to:
  /// **'New clip'**
  String get desktopNewClip;

  /// No description provided for @desktopWorkspaceSection.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get desktopWorkspaceSection;

  /// No description provided for @detectedSegments.
  ///
  /// In en, this message translates to:
  /// **'Detected segments'**
  String get detectedSegments;

  /// No description provided for @detectionMode.
  ///
  /// In en, this message translates to:
  /// **'Detection mode'**
  String get detectionMode;

  /// No description provided for @devToolsSection.
  ///
  /// In en, this message translates to:
  /// **'Developer tools'**
  String get devToolsSection;

  /// No description provided for @developerModeAlreadyEnabled.
  ///
  /// In en, this message translates to:
  /// **'Developer mode is already enabled'**
  String get developerModeAlreadyEnabled;

  /// No description provided for @developerModeEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Developer mode enabled. You can now access developer features.'**
  String get developerModeEnabledMessage;

  /// No description provided for @developerModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Developer mode'**
  String get developerModeTitle;

  /// No description provided for @developerModeWarning.
  ///
  /// In en, this message translates to:
  /// **'These features are for development and debugging only. Use with caution.'**
  String get developerModeWarning;

  /// No description provided for @developerOptions.
  ///
  /// In en, this message translates to:
  /// **'Developer options'**
  String get developerOptions;

  /// No description provided for @developerOptionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Access developer tools and debugging features'**
  String get developerOptionsDescription;

  /// No description provided for @developerPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect developer password'**
  String get developerPasswordIncorrect;

  /// No description provided for @deviceBrandLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get deviceBrandLabel;

  /// No description provided for @deviceIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceIdLabel;

  /// No description provided for @deviceIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Device identifier'**
  String get deviceIdentifierLabel;

  /// No description provided for @deviceInfoFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch'**
  String get deviceInfoFetchFailed;

  /// No description provided for @deviceInfoFetchFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to get device info: {error}'**
  String deviceInfoFetchFailedWithError(String error);

  /// No description provided for @deviceInfoFetching.
  ///
  /// In en, this message translates to:
  /// **'Fetching...'**
  String get deviceInfoFetching;

  /// No description provided for @deviceInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Device info'**
  String get deviceInfoLabel;

  /// No description provided for @deviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get deviceLabel;

  /// No description provided for @deviceModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get deviceModelLabel;

  /// No description provided for @deviceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get deviceNameLabel;

  /// No description provided for @deviceTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Device type'**
  String get deviceTypeLabel;

  /// No description provided for @distroNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get distroNameLabel;

  /// No description provided for @distroVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Distribution version'**
  String get distroVersionLabel;

  /// No description provided for @downloadCompleted.
  ///
  /// In en, this message translates to:
  /// **'Download completed'**
  String get downloadCompleted;

  /// No description provided for @downloadError.
  ///
  /// In en, this message translates to:
  /// **'Download error'**
  String get downloadError;

  /// No description provided for @downloadErrorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'An error occurred during download: {error}'**
  String downloadErrorWithDetails(String error);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @downloadInBackground.
  ///
  /// In en, this message translates to:
  /// **'Download in background'**
  String get downloadInBackground;

  /// No description provided for @downloadInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Download in browser'**
  String get downloadInBrowser;

  /// No description provided for @downloadInProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloadInProgress;

  /// No description provided for @downloadLinkOpenedInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Download link opened in browser'**
  String get downloadLinkOpenedInBrowser;

  /// No description provided for @downloadLinkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Download link unavailable'**
  String get downloadLinkUnavailable;

  /// No description provided for @downloadNow.
  ///
  /// In en, this message translates to:
  /// **'Download now'**
  String get downloadNow;

  /// No description provided for @downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Download progress'**
  String get downloadProgress;

  /// No description provided for @downloadStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting download...'**
  String get downloadStarting;

  /// No description provided for @downloadWillContinueInBackground.
  ///
  /// In en, this message translates to:
  /// **'Download will continue in the background'**
  String get downloadWillContinueInBackground;

  /// No description provided for @downloadingResult.
  ///
  /// In en, this message translates to:
  /// **'Downloading result...'**
  String get downloadingResult;

  /// No description provided for @dragToReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Long press and drag to reorder'**
  String get dragToReorderHint;

  /// No description provided for @dragVideoHere.
  ///
  /// In en, this message translates to:
  /// **'Drag videos here'**
  String get dragVideoHere;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String durationLabel(String duration);

  /// No description provided for @durationPackages.
  ///
  /// In en, this message translates to:
  /// **'Duration packages'**
  String get durationPackages;

  /// No description provided for @durationPlans.
  ///
  /// In en, this message translates to:
  /// **'Duration plans'**
  String get durationPlans;

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String durationSeconds(int seconds);

  /// No description provided for @durationShortenedLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration reduced'**
  String get durationShortenedLabel;

  /// No description provided for @editBreadcrumb.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editBreadcrumb;

  /// No description provided for @editFeatureUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Editing is unavailable'**
  String get editFeatureUnavailable;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit name'**
  String get editName;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @editRound.
  ///
  /// In en, this message translates to:
  /// **'Edit round'**
  String get editRound;

  /// No description provided for @editToolAiClip.
  ///
  /// In en, this message translates to:
  /// **'AI clip'**
  String get editToolAiClip;

  /// No description provided for @editToolAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get editToolAudio;

  /// No description provided for @editToolClip.
  ///
  /// In en, this message translates to:
  /// **'Clip'**
  String get editToolClip;

  /// No description provided for @editToolPip.
  ///
  /// In en, this message translates to:
  /// **'Picture-in-picture'**
  String get editToolPip;

  /// No description provided for @editToolSticker.
  ///
  /// In en, this message translates to:
  /// **'Stickers'**
  String get editToolSticker;

  /// No description provided for @editToolText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get editToolText;

  /// No description provided for @editVideo.
  ///
  /// In en, this message translates to:
  /// **'Edit video'**
  String get editVideo;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailLoginOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Due to policy requirements, only email login is available for now.'**
  String get emailLoginOnlyNotice;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get emailSupport;

  /// No description provided for @endDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDateLabel;

  /// No description provided for @enterConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get enterConfirmPassword;

  /// No description provided for @enterConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get enterConfirmPasswordRequired;

  /// No description provided for @enterDeveloperPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the developer password to enable developer mode'**
  String get enterDeveloperPasswordHint;

  /// No description provided for @enterDeveloperPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter developer password'**
  String get enterDeveloperPasswordTitle;

  /// No description provided for @enterKeywordToStartSearch.
  ///
  /// In en, this message translates to:
  /// **'Enter a keyword to start searching'**
  String get enterKeywordToStartSearch;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPassword;

  /// No description provided for @enterPhoneOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter phone or email'**
  String get enterPhoneOrEmail;

  /// No description provided for @enterSearchKeyword.
  ///
  /// In en, this message translates to:
  /// **'Enter a search keyword'**
  String get enterSearchKeyword;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get enterVerificationCode;

  /// No description provided for @entityInfoDateAndItemCount.
  ///
  /// In en, this message translates to:
  /// **'{date} {count} items'**
  String entityInfoDateAndItemCount(String date, int count);

  /// No description provided for @errorGalleryReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read the photo library. Retry or check album permissions.'**
  String get errorGalleryReadFailed;

  /// No description provided for @errorImageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image. It may be corrupted or unsupported on this device.'**
  String get errorImageLoadFailed;

  /// No description provided for @errorLoginExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get errorLoginExpired;

  /// No description provided for @errorNetworkRetry.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and try again.'**
  String get errorNetworkRetry;

  /// No description provided for @errorResourceNotFound.
  ///
  /// In en, this message translates to:
  /// **'Resource not found or no longer available.'**
  String get errorResourceNotFound;

  /// No description provided for @errorStorageFull.
  ///
  /// In en, this message translates to:
  /// **'Insufficient storage or app data is not writable. Free up space and try again.'**
  String get errorStorageFull;

  /// No description provided for @errorVideoNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This device cannot play this video. Try transcoding or compressing it first.'**
  String get errorVideoNotSupported;

  /// No description provided for @estimatedRemainingTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated remaining time: {duration}'**
  String estimatedRemainingTime(String duration);

  /// No description provided for @estimatedRemainingTimeSeconds.
  ///
  /// In en, this message translates to:
  /// **'Estimated remaining time: {seconds} s'**
  String estimatedRemainingTimeSeconds(int seconds);

  /// No description provided for @exceptionDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get exceptionDetailsLabel;

  /// No description provided for @existingVideoClip.
  ///
  /// In en, this message translates to:
  /// **'Clip existing video'**
  String get existingVideoClip;

  /// No description provided for @existingVideoClipDescription.
  ///
  /// In en, this message translates to:
  /// **'Select local video files for automatic clipping and segment extraction'**
  String get existingVideoClipDescription;

  /// No description provided for @existingVideoClipMode.
  ///
  /// In en, this message translates to:
  /// **'Existing video clip mode'**
  String get existingVideoClipMode;

  /// No description provided for @existingVideoClipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clip local video files'**
  String get existingVideoClipSubtitle;

  /// No description provided for @exitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit fullscreen'**
  String get exitFullscreen;

  /// No description provided for @experimentalFeatureASubtitle.
  ///
  /// In en, this message translates to:
  /// **'Experimental feature A'**
  String get experimentalFeatureASubtitle;

  /// No description provided for @experimentalFeatureATitle.
  ///
  /// In en, this message translates to:
  /// **'Experimental feature A'**
  String get experimentalFeatureATitle;

  /// No description provided for @experimentalFeatureBSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Experimental feature B'**
  String get experimentalFeatureBSubtitle;

  /// No description provided for @experimentalFeatureBTitle.
  ///
  /// In en, this message translates to:
  /// **'Experimental feature B'**
  String get experimentalFeatureBTitle;

  /// No description provided for @experimentalFeaturesSection.
  ///
  /// In en, this message translates to:
  /// **'Experimental features'**
  String get experimentalFeaturesSection;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @exportComplete.
  ///
  /// In en, this message translates to:
  /// **'Export complete'**
  String get exportComplete;

  /// No description provided for @exportConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'📤 Export settings'**
  String get exportConfigTitle;

  /// No description provided for @exportEncoding.
  ///
  /// In en, this message translates to:
  /// **'Encoding...'**
  String get exportEncoding;

  /// No description provided for @exportFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailedTitle;

  /// No description provided for @exportFileNotGenerated.
  ///
  /// In en, this message translates to:
  /// **'Export file was not generated'**
  String get exportFileNotGenerated;

  /// No description provided for @exportFormatMp4H264.
  ///
  /// In en, this message translates to:
  /// **'MP4 (H.264)'**
  String get exportFormatMp4H264;

  /// No description provided for @exportLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export app logs'**
  String get exportLogsSubtitle;

  /// No description provided for @exportLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Export logs'**
  String get exportLogsTitle;

  /// No description provided for @exportPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing export...'**
  String get exportPreparing;

  /// No description provided for @exportProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'Exporting... {percent}%'**
  String exportProgressPercent(String percent);

  /// No description provided for @exportQualityMobileShare.
  ///
  /// In en, this message translates to:
  /// **'Mobile sharing'**
  String get exportQualityMobileShare;

  /// No description provided for @exportQualityOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get exportQualityOriginal;

  /// No description provided for @exportQualityOriginalMeta.
  ///
  /// In en, this message translates to:
  /// **'Original resolution'**
  String get exportQualityOriginalMeta;

  /// No description provided for @exportQualityRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get exportQualityRecommended;

  /// No description provided for @exportQualitySmallerSize.
  ///
  /// In en, this message translates to:
  /// **'Smaller file'**
  String get exportQualitySmallerSize;

  /// No description provided for @exportVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Export video'**
  String get exportVideoTitle;

  /// No description provided for @exporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get exporting;

  /// No description provided for @extendMoreEditFeaturesHint.
  ///
  /// In en, this message translates to:
  /// **'Extend more editing features here'**
  String get extendMoreEditFeaturesHint;

  /// No description provided for @faqClippingDuration.
  ///
  /// In en, this message translates to:
  /// **'How long does clipping take?'**
  String get faqClippingDuration;

  /// No description provided for @faqClippingDurationAnswer.
  ///
  /// In en, this message translates to:
  /// **'For a one-hour video, clipping usually takes about 10 minutes.'**
  String get faqClippingDurationAnswer;

  /// No description provided for @faqHowToSelectSport.
  ///
  /// In en, this message translates to:
  /// **'How do I choose a sport type?'**
  String get faqHowToSelectSport;

  /// No description provided for @faqHowToSelectSportAnswer.
  ///
  /// In en, this message translates to:
  /// **'On the clipping settings page, choose a sport such as badminton or table tennis. The system will clip intelligently based on the sport.'**
  String get faqHowToSelectSportAnswer;

  /// No description provided for @faqHowToUploadVideo.
  ///
  /// In en, this message translates to:
  /// **'How do I upload a video?'**
  String get faqHowToUploadVideo;

  /// No description provided for @faqHowToUploadVideoAnswer.
  ///
  /// In en, this message translates to:
  /// **'On the home screen, tap \"Start clipping\" and select the video file to upload.'**
  String get faqHowToUploadVideoAnswer;

  /// No description provided for @faqSupportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Which video formats are supported?'**
  String get faqSupportedFormats;

  /// No description provided for @faqSupportedFormatsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Common formats such as MP4, AVI, MOV, and MKV are supported.'**
  String get faqSupportedFormatsAnswer;

  /// No description provided for @faqTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faqTitle;

  /// No description provided for @fasterAndMoreAccurate.
  ///
  /// In en, this message translates to:
  /// **'Faster & more accurate'**
  String get fasterAndMoreAccurate;

  /// No description provided for @favoriteCurrentRound.
  ///
  /// In en, this message translates to:
  /// **'Favorite current round'**
  String get favoriteCurrentRound;

  /// No description provided for @favoriteRounds.
  ///
  /// In en, this message translates to:
  /// **'Favorite rounds'**
  String get favoriteRounds;

  /// No description provided for @favoriteSegment.
  ///
  /// In en, this message translates to:
  /// **'Favorite segment'**
  String get favoriteSegment;

  /// No description provided for @featureBatchProcessing.
  ///
  /// In en, this message translates to:
  /// **'Batch processing'**
  String get featureBatchProcessing;

  /// No description provided for @featureCloudAndLocalClip.
  ///
  /// In en, this message translates to:
  /// **'Cloud and local clipping'**
  String get featureCloudAndLocalClip;

  /// No description provided for @featureInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Feature in development...'**
  String get featureInDevelopment;

  /// No description provided for @featureInstantSegmentMarking.
  ///
  /// In en, this message translates to:
  /// **'Instant segment marking'**
  String get featureInstantSegmentMarking;

  /// No description provided for @featureLiveRecording.
  ///
  /// In en, this message translates to:
  /// **'Live recording'**
  String get featureLiveRecording;

  /// No description provided for @featureMultipleFormats.
  ///
  /// In en, this message translates to:
  /// **'Multiple video formats supported'**
  String get featureMultipleFormats;

  /// No description provided for @featureNotSupportedOnDesktop.
  ///
  /// In en, this message translates to:
  /// **'This feature is not supported on desktop'**
  String get featureNotSupportedOnDesktop;

  /// No description provided for @featureOnSiteRecording.
  ///
  /// In en, this message translates to:
  /// **'Ideal for on-site match recording'**
  String get featureOnSiteRecording;

  /// No description provided for @featureRecordAndClipEfficiency.
  ///
  /// In en, this message translates to:
  /// **'Record and clip for higher efficiency'**
  String get featureRecordAndClipEfficiency;

  /// No description provided for @featureSmartSegmentDetection.
  ///
  /// In en, this message translates to:
  /// **'Smart segment detection'**
  String get featureSmartSegmentDetection;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @feedbackDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Please describe your issue or suggestion in detail...'**
  String get feedbackDescriptionHint;

  /// No description provided for @feedbackSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Feedback submitted. Thank you for your suggestion!'**
  String get feedbackSubmittedSuccessfully;

  /// No description provided for @feedbackTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Title (e.g. bug/suggestion)'**
  String get feedbackTitleHint;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @fetchingDownloadLink.
  ///
  /// In en, this message translates to:
  /// **'Fetching download link...'**
  String get fetchingDownloadLink;

  /// No description provided for @ffmpegConvertFailed.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg conversion failed: {output}'**
  String ffmpegConvertFailed(String output);

  /// No description provided for @ffmpegExecuteException.
  ///
  /// In en, this message translates to:
  /// **'Execution error: {error}'**
  String ffmpegExecuteException(String error);

  /// No description provided for @ffmpegExecuteFailed.
  ///
  /// In en, this message translates to:
  /// **'Execution failed: {logs}'**
  String ffmpegExecuteFailed(String logs);

  /// No description provided for @ffmpegExitCode.
  ///
  /// In en, this message translates to:
  /// **'ffmpeg exited with code {code}'**
  String ffmpegExitCode(String code);

  /// No description provided for @ffmpegNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg is not initialized'**
  String get ffmpegNotInitialized;

  /// No description provided for @ffmpegOperationCancelled.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg operation cancelled'**
  String get ffmpegOperationCancelled;

  /// No description provided for @fileDeleted.
  ///
  /// In en, this message translates to:
  /// **'File deleted'**
  String get fileDeleted;

  /// No description provided for @fileDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get fileDetailsTitle;

  /// No description provided for @fileDoesNotExist.
  ///
  /// In en, this message translates to:
  /// **'File does not exist'**
  String get fileDoesNotExist;

  /// No description provided for @taskResultUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to view task result'**
  String get taskResultUnavailable;

  /// No description provided for @fileInfoAccessedAt.
  ///
  /// In en, this message translates to:
  /// **'Accessed: {time}'**
  String fileInfoAccessedAt(String time);

  /// No description provided for @fileInfoCachePath.
  ///
  /// In en, this message translates to:
  /// **'Cache path: {path}'**
  String fileInfoCachePath(String path);

  /// No description provided for @fileInfoCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created: {time}'**
  String fileInfoCreatedAt(String time);

  /// No description provided for @fileInfoFileName.
  ///
  /// In en, this message translates to:
  /// **'File name: {name}'**
  String fileInfoFileName(String name);

  /// No description provided for @fileInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'File info:'**
  String get fileInfoLabel;

  /// No description provided for @fileInfoModifiedAt.
  ///
  /// In en, this message translates to:
  /// **'Modified: {time}'**
  String fileInfoModifiedAt(String time);

  /// No description provided for @fileInfoSize.
  ///
  /// In en, this message translates to:
  /// **'Size: {size}'**
  String fileInfoSize(String size);

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get fileName;

  /// No description provided for @fileNameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'File name already exists'**
  String get fileNameAlreadyExists;

  /// No description provided for @fileNameWithSegmentCount.
  ///
  /// In en, this message translates to:
  /// **'{fileName} ({count} segments)'**
  String fileNameWithSegmentCount(String fileName, int count);

  /// No description provided for @fileSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size: {size}'**
  String fileSizeLabel(String size);

  /// No description provided for @filesSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} file(s) selected'**
  String filesSelectedCount(int count);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterConditions.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterConditions;

  /// No description provided for @filterLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get filterLocal;

  /// No description provided for @filterOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter options'**
  String get filterOptionsTitle;

  /// No description provided for @filterProcessStatus.
  ///
  /// In en, this message translates to:
  /// **'Process status'**
  String get filterProcessStatus;

  /// No description provided for @filterSportType.
  ///
  /// In en, this message translates to:
  /// **'Sport type'**
  String get filterSportType;

  /// No description provided for @flutterVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Flutter version'**
  String get flutterVersionLabel;

  /// No description provided for @folderAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Folder already exists'**
  String get folderAlreadyExists;

  /// No description provided for @folderCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Folder created'**
  String get folderCreatedSuccess;

  /// No description provided for @folderEmpty.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get folderEmpty;

  /// No description provided for @folderInfo.
  ///
  /// In en, this message translates to:
  /// **'Folder info'**
  String get folderInfo;

  /// No description provided for @folderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter folder name'**
  String get folderNameHint;

  /// No description provided for @formatLabel.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get formatLabel;

  /// No description provided for @foundFileCount.
  ///
  /// In en, this message translates to:
  /// **'Found {count} file(s)'**
  String foundFileCount(int count);

  /// No description provided for @frameExtractionFailed.
  ///
  /// In en, this message translates to:
  /// **'Frame extraction failed: {output}'**
  String frameExtractionFailed(String output);

  /// No description provided for @frameOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Frame index out of range: 0-{maxFrames}'**
  String frameOutOfRange(String maxFrames);

  /// No description provided for @freeBadge.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freeBadge;

  /// No description provided for @fullDiskSearchTab.
  ///
  /// In en, this message translates to:
  /// **'Search all'**
  String get fullDiskSearchTab;

  /// No description provided for @fullscreenPlayback.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen playback'**
  String get fullscreenPlayback;

  /// No description provided for @galleryNotSupportedOnDesktop.
  ///
  /// In en, this message translates to:
  /// **'Gallery access is not supported on desktop'**
  String get galleryNotSupportedOnDesktop;

  /// No description provided for @galleryPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'To select photos and videos, grant photo library access in Settings.'**
  String get galleryPermissionMessage;

  /// No description provided for @galleryPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo library access required'**
  String get galleryPermissionRequired;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @generalPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Startup, storage, and privacy'**
  String get generalPageSubtitle;

  /// No description provided for @generateThumbnailFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate thumbnail: {path}: {error}'**
  String generateThumbnailFailed(String path, String error);

  /// No description provided for @generatingFinalVideo.
  ///
  /// In en, this message translates to:
  /// **'Generating final video...'**
  String get generatingFinalVideo;

  /// No description provided for @generatingThumbnail.
  ///
  /// In en, this message translates to:
  /// **'Generating thumbnail...'**
  String get generatingThumbnail;

  /// No description provided for @getFolderInfoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get folder info: {error}'**
  String getFolderInfoFailed(String error);

  /// No description provided for @getMatchSegments.
  ///
  /// In en, this message translates to:
  /// **'Extract match segments'**
  String get getMatchSegments;

  /// No description provided for @getxVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'GetX version'**
  String get getxVersionLabel;

  /// No description provided for @goToFeature.
  ///
  /// In en, this message translates to:
  /// **'Go to feature'**
  String get goToFeature;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to settings'**
  String get goToSettings;

  /// No description provided for @hardwareLabel.
  ///
  /// In en, this message translates to:
  /// **'Hardware'**
  String get hardwareLabel;

  /// No description provided for @helpAndFeedback.
  ///
  /// In en, this message translates to:
  /// **'Help & feedback'**
  String get helpAndFeedback;

  /// No description provided for @highlightClip.
  ///
  /// In en, this message translates to:
  /// **'Highlight clip'**
  String get highlightClip;

  /// No description provided for @highlightClipHelp.
  ///
  /// In en, this message translates to:
  /// **'Automatically identify and keep highlight rallies'**
  String get highlightClipHelp;

  /// No description provided for @highlightClipTooltip.
  ///
  /// In en, this message translates to:
  /// **'Auto-clip long highlight rallies in a game'**
  String get highlightClipTooltip;

  /// No description provided for @homeBadmintonClip.
  ///
  /// In en, this message translates to:
  /// **'Badminton editing'**
  String get homeBadmintonClip;

  /// No description provided for @homeBadmintonClipDesc.
  ///
  /// In en, this message translates to:
  /// **'Edit badminton match videos'**
  String get homeBadmintonClipDesc;

  /// No description provided for @homeCarouselAiClipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-clip highlights and remove rest/ball-pickup segments'**
  String get homeCarouselAiClipSubtitle;

  /// No description provided for @homeCarouselAiClipTitle.
  ///
  /// In en, this message translates to:
  /// **'AI match auto-editing'**
  String get homeCarouselAiClipTitle;

  /// No description provided for @homeImageCompress.
  ///
  /// In en, this message translates to:
  /// **'Image compression'**
  String get homeImageCompress;

  /// No description provided for @homeImageCompressDesc.
  ///
  /// In en, this message translates to:
  /// **'Compress image files'**
  String get homeImageCompressDesc;

  /// No description provided for @homeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get homeLoading;

  /// No description provided for @homePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homePageTitle;

  /// No description provided for @homePingpongClip.
  ///
  /// In en, this message translates to:
  /// **'Table tennis editing'**
  String get homePingpongClip;

  /// No description provided for @homePingpongClipDesc.
  ///
  /// In en, this message translates to:
  /// **'Edit table tennis match videos'**
  String get homePingpongClipDesc;

  /// No description provided for @homeStartClip.
  ///
  /// In en, this message translates to:
  /// **'Start editing'**
  String get homeStartClip;

  /// No description provided for @homeToolsSection.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get homeToolsSection;

  /// No description provided for @homeVideoCategoryCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get homeVideoCategoryCompleted;

  /// No description provided for @homeVideoCategoryProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get homeVideoCategoryProcessing;

  /// No description provided for @homeVideoCategoryRaw.
  ///
  /// In en, this message translates to:
  /// **'Raw'**
  String get homeVideoCategoryRaw;

  /// No description provided for @homeVideoCategoryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get homeVideoCategoryUnknown;

  /// No description provided for @homeVideoCompress.
  ///
  /// In en, this message translates to:
  /// **'Video compression'**
  String get homeVideoCompress;

  /// No description provided for @homeVideoCompressDesc.
  ///
  /// In en, this message translates to:
  /// **'Compress video files'**
  String get homeVideoCompressDesc;

  /// No description provided for @homeVideoNoMoreRecords.
  ///
  /// In en, this message translates to:
  /// **'No more records'**
  String get homeVideoNoMoreRecords;

  /// No description provided for @homeVideoProcessingProgress.
  ///
  /// In en, this message translates to:
  /// **'Processing {progress}%'**
  String homeVideoProcessingProgress(int progress);

  /// No description provided for @homeVideoSubtitleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get homeVideoSubtitleCompleted;

  /// No description provided for @homeVideoSubtitlePending.
  ///
  /// In en, this message translates to:
  /// **'Pending | Raw file'**
  String get homeVideoSubtitlePending;

  /// No description provided for @homeVideoSubtitleProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing | Task ID: {taskId}'**
  String homeVideoSubtitleProcessing(String taskId);

  /// No description provided for @homeVideoTitleEditing.
  ///
  /// In en, this message translates to:
  /// **'Edit video'**
  String get homeVideoTitleEditing;

  /// No description provided for @homeVideoTitleProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing record #{taskId}'**
  String homeVideoTitleProcessing(String taskId);

  /// No description provided for @homeVideoTitleRaw.
  ///
  /// In en, this message translates to:
  /// **'Raw video'**
  String get homeVideoTitleRaw;

  /// No description provided for @homeVideoTitleUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown video'**
  String get homeVideoTitleUnknown;

  /// No description provided for @hostNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Host name'**
  String get hostNameLabel;

  /// No description provided for @imageCompressResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Compress results ({count})'**
  String imageCompressResultsTitle(int count);

  /// No description provided for @imageDetails.
  ///
  /// In en, this message translates to:
  /// **'Image details'**
  String get imageDetails;

  /// No description provided for @imageFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Image file'**
  String get imageFileLabel;

  /// No description provided for @imageLabel.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get imageLabel;

  /// No description provided for @infoCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get infoCreatedAt;

  /// No description provided for @infoFileCount.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get infoFileCount;

  /// No description provided for @infoFolderCount.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get infoFolderCount;

  /// No description provided for @infoModifiedAt.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get infoModifiedAt;

  /// No description provided for @infoPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get infoPath;

  /// No description provided for @infoTotalItems.
  ///
  /// In en, this message translates to:
  /// **'Total items'**
  String get infoTotalItems;

  /// No description provided for @infoUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String infoUpdateFailed(String error);

  /// No description provided for @infoUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get infoUpdatedSuccessfully;

  /// No description provided for @initFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Initialization failed: {error}'**
  String initFailedWithError(String error);

  /// No description provided for @inputFileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter file name...'**
  String get inputFileNameHint;

  /// No description provided for @inputFileNameKeywordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter file name keyword...'**
  String get inputFileNameKeywordHint;

  /// No description provided for @inputKeywordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter keyword...'**
  String get inputKeywordHint;

  /// No description provided for @inputVideoLabel.
  ///
  /// In en, this message translates to:
  /// **'Input video'**
  String get inputVideoLabel;

  /// No description provided for @installNow.
  ///
  /// In en, this message translates to:
  /// **'Install now'**
  String get installNow;

  /// No description provided for @installTime.
  ///
  /// In en, this message translates to:
  /// **'Install date'**
  String get installTime;

  /// No description provided for @intervalMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Interval must be greater than 0'**
  String get intervalMustBePositive;

  /// No description provided for @invalidIndex.
  ///
  /// In en, this message translates to:
  /// **'Invalid index'**
  String get invalidIndex;

  /// No description provided for @issueTypeBug.
  ///
  /// In en, this message translates to:
  /// **'Bug'**
  String get issueTypeBug;

  /// No description provided for @issueTypeSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get issueTypeSuggestion;

  /// No description provided for @itemCountUnit.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String itemCountUnit(int count);

  /// No description provided for @itemTypeDirectory.
  ///
  /// In en, this message translates to:
  /// **'directory'**
  String get itemTypeDirectory;

  /// No description provided for @itemTypeFile.
  ///
  /// In en, this message translates to:
  /// **'file'**
  String get itemTypeFile;

  /// No description provided for @itemTypeItem.
  ///
  /// In en, this message translates to:
  /// **'item'**
  String get itemTypeItem;

  /// No description provided for @labelDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get labelDuration;

  /// No description provided for @labelError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get labelError;

  /// No description provided for @labelSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get labelSize;

  /// No description provided for @labelType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get labelType;

  /// No description provided for @labelUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get labelUnknown;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Language for menus, buttons, and labels'**
  String get languageDescription;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @latestVersion.
  ///
  /// In en, this message translates to:
  /// **'Latest version'**
  String get latestVersion;

  /// No description provided for @leavePageProcessingNotification.
  ///
  /// In en, this message translates to:
  /// **'You can leave this page. You\'ll be notified via messages when processing completes.'**
  String get leavePageProcessingNotification;

  /// No description provided for @linkRequiresBrowserDownload.
  ///
  /// In en, this message translates to:
  /// **'This link must be downloaded in a browser'**
  String get linkRequiresBrowserDownload;

  /// No description provided for @loadAlbumFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load albums'**
  String get loadAlbumFailed;

  /// No description provided for @loadAlbumFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load albums: {error}'**
  String loadAlbumFailedWithError(String error);

  /// No description provided for @loadChangelogFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load changelog: {error}'**
  String loadChangelogFailed(String error);

  /// No description provided for @loadDemoVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load demo video: {error}'**
  String loadDemoVideoFailed(String error);

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String loadFailed(String error);

  /// No description provided for @loadFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get loadFailedShort;

  /// No description provided for @loadLogFilesFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load log files: {error}'**
  String loadLogFilesFailed(String error);

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more...'**
  String get loadMore;

  /// No description provided for @loadMoreFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load more: {error}'**
  String loadMoreFailedWithError(String error);

  /// No description provided for @loadSubscriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load subscription info: {error}'**
  String loadSubscriptionFailed(String error);

  /// No description provided for @loadUserInfoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load user info: {error}'**
  String loadUserInfoFailed(String error);

  /// No description provided for @loadVideoDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load video data'**
  String get loadVideoDataFailed;

  /// No description provided for @loadVideoDetailFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load video details: {error}'**
  String loadVideoDetailFailed(String error);

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loadingChangelog.
  ///
  /// In en, this message translates to:
  /// **'Loading changelog...'**
  String get loadingChangelog;

  /// No description provided for @localClip.
  ///
  /// In en, this message translates to:
  /// **'Local clip'**
  String get localClip;

  /// No description provided for @localClipFailed.
  ///
  /// In en, this message translates to:
  /// **'Local video clipping failed: {error}'**
  String localClipFailed(String error);

  /// No description provided for @localClipTaskCreatedRedirecting.
  ///
  /// In en, this message translates to:
  /// **'Local clip task created. Redirecting to tasks...'**
  String get localClipTaskCreatedRedirecting;

  /// No description provided for @localDetecting.
  ///
  /// In en, this message translates to:
  /// **'Running local detection…'**
  String get localDetecting;

  /// No description provided for @localDetection.
  ///
  /// In en, this message translates to:
  /// **'Local detection'**
  String get localDetection;

  /// No description provided for @localDetectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Local detection failed: {error}'**
  String localDetectionFailed(String error);

  /// No description provided for @localDetectionHelp.
  ///
  /// In en, this message translates to:
  /// **'Works offline; no internet required'**
  String get localDetectionHelp;

  /// No description provided for @localDetectionTaskName.
  ///
  /// In en, this message translates to:
  /// **'Local detection: {fileName}'**
  String localDetectionTaskName(String fileName);

  /// No description provided for @localDetectionTasksSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted {count} local detection task(s). You can leave this page and check the task list.'**
  String localDetectionTasksSubmitted(int count);

  /// No description provided for @localModelNotFoundFallback.
  ///
  /// In en, this message translates to:
  /// **'Local models not found; falling back to cloud detection'**
  String get localModelNotFoundFallback;

  /// No description provided for @localOnnxDetectionHint.
  ///
  /// In en, this message translates to:
  /// **'Uses local ONNX models for offline detection'**
  String get localOnnxDetectionHint;

  /// No description provided for @localTasks.
  ///
  /// In en, this message translates to:
  /// **'Local tasks'**
  String get localTasks;

  /// No description provided for @localVideoClip.
  ///
  /// In en, this message translates to:
  /// **'Local video clip'**
  String get localVideoClip;

  /// No description provided for @localVideoStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending detection'**
  String get localVideoStatusPending;

  /// No description provided for @localVideoStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Detecting'**
  String get localVideoStatusProcessing;

  /// No description provided for @localizedModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Localized model'**
  String get localizedModelLabel;

  /// No description provided for @logFilesGeneratedAtRuntime.
  ///
  /// In en, this message translates to:
  /// **'Log files are generated while the app is running'**
  String get logFilesGeneratedAtRuntime;

  /// No description provided for @logLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Log level:'**
  String get logLevelLabel;

  /// No description provided for @logViewerTitle.
  ///
  /// In en, this message translates to:
  /// **'Log viewer'**
  String get logViewerTitle;

  /// No description provided for @loginAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get loginAlreadyHaveAccount;

  /// No description provided for @loginAuthCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get loginAuthCodeHint;

  /// No description provided for @loginAuthCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get loginAuthCodeLabel;

  /// No description provided for @loginAuthCodeMode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get loginAuthCodeMode;

  /// No description provided for @loginAuthCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent'**
  String get loginAuthCodeSent;

  /// No description provided for @loginAuthCodeSentCheck.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent. Please check your messages.'**
  String get loginAuthCodeSentCheck;

  /// No description provided for @loginBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get loginBackToLogin;

  /// No description provided for @loginConfirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get loginConfirmNewPassword;

  /// No description provided for @loginConfirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new password'**
  String get loginConfirmNewPasswordHint;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed: {error}'**
  String loginFailed(String error);

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginIdentifierHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number or email'**
  String get loginIdentifierHint;

  /// No description provided for @loginIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone / email'**
  String get loginIdentifierLabel;

  /// No description provided for @loginIdentifierLabelOr.
  ///
  /// In en, this message translates to:
  /// **'Phone or email'**
  String get loginIdentifierLabelOr;

  /// No description provided for @loginLoginNow.
  ///
  /// In en, this message translates to:
  /// **'Sign in now'**
  String get loginLoginNow;

  /// No description provided for @loginNeedLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to your account to continue'**
  String get loginNeedLoginSubtitle;

  /// No description provided for @loginNeedLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get loginNeedLoginTitle;

  /// No description provided for @loginNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get loginNewPassword;

  /// No description provided for @loginNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get loginNewPasswordHint;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get loginNoAccount;

  /// No description provided for @loginPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get loginPasswordHint;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get loginPasswordMismatch;

  /// No description provided for @loginPasswordMode.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordMode;

  /// No description provided for @loginPasswordTab.
  ///
  /// In en, this message translates to:
  /// **'Account & password'**
  String get loginPasswordTab;

  /// No description provided for @loginRegisterAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get loginRegisterAccount;

  /// No description provided for @loginRegisterFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed: {error}'**
  String loginRegisterFailed(String error);

  /// No description provided for @loginRegisterNow.
  ///
  /// In en, this message translates to:
  /// **'Sign up now'**
  String get loginRegisterNow;

  /// No description provided for @loginRegisterSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully'**
  String get loginRegisterSuccess;

  /// No description provided for @loginRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get loginRegisterTitle;

  /// No description provided for @loginRegistering.
  ///
  /// In en, this message translates to:
  /// **'Signing up...'**
  String get loginRegistering;

  /// No description provided for @loginRememberPassword.
  ///
  /// In en, this message translates to:
  /// **'Remember password'**
  String get loginRememberPassword;

  /// No description provided for @loginRememberedPassword.
  ///
  /// In en, this message translates to:
  /// **'Remember your password? '**
  String get loginRememberedPassword;

  /// No description provided for @loginRequiredForClipHistory.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view clip history'**
  String get loginRequiredForClipHistory;

  /// No description provided for @loginResetPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Password reset failed: {error}'**
  String loginResetPasswordFailed(String error);

  /// No description provided for @loginResetPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully'**
  String get loginResetPasswordSuccess;

  /// No description provided for @loginResetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get loginResetPasswordTitle;

  /// No description provided for @loginSendAuthCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send verification code: {error}'**
  String loginSendAuthCodeFailed(String error);

  /// No description provided for @loginSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed: {error}'**
  String loginSendFailed(String error);

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to your account'**
  String get loginSubtitle;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully'**
  String get loginSuccess;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginValidationAuthCodeFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter a 4–6 digit verification code'**
  String get loginValidationAuthCodeFormat;

  /// No description provided for @loginValidationAuthCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter verification code'**
  String get loginValidationAuthCodeRequired;

  /// No description provided for @loginValidationIdentifierInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number or email'**
  String get loginValidationIdentifierInvalid;

  /// No description provided for @loginValidationIdentifierRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter phone number or email'**
  String get loginValidationIdentifierRequired;

  /// No description provided for @loginValidationPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get loginValidationPasswordMinLength;

  /// No description provided for @loginValidationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get loginValidationPasswordRequired;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get loginWelcome;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign out: {error}'**
  String logoutFailed(String error);

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @manufacturerLabel.
  ///
  /// In en, this message translates to:
  /// **'Manufacturer'**
  String get manufacturerLabel;

  /// No description provided for @markAllReadSuccess.
  ///
  /// In en, this message translates to:
  /// **'All messages marked as read'**
  String get markAllReadSuccess;

  /// No description provided for @markReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark as read'**
  String get markReadFailed;

  /// No description provided for @matchType.
  ///
  /// In en, this message translates to:
  /// **'Match type'**
  String get matchType;

  /// No description provided for @matchTypeDoubles.
  ///
  /// In en, this message translates to:
  /// **'Doubles match'**
  String get matchTypeDoubles;

  /// No description provided for @matchTypeSingles.
  ///
  /// In en, this message translates to:
  /// **'Singles match'**
  String get matchTypeSingles;

  /// No description provided for @maxSelectionCountReached.
  ///
  /// In en, this message translates to:
  /// **'You can select at most {count} file(s)'**
  String maxSelectionCountReached(int count);

  /// No description provided for @maxSelectionCountReachedFor.
  ///
  /// In en, this message translates to:
  /// **'You can select at most {count} {itemType}'**
  String maxSelectionCountReachedFor(int count, String itemType);

  /// No description provided for @maxServeDuration.
  ///
  /// In en, this message translates to:
  /// **'Max serve duration'**
  String get maxServeDuration;

  /// No description provided for @maxServeDurationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Limit serve duration (seconds)'**
  String get maxServeDurationTooltip;

  /// No description provided for @mediaItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {mediaType}'**
  String mediaItemCount(int count, String mediaType);

  /// No description provided for @mediaTypeAll.
  ///
  /// In en, this message translates to:
  /// **'media'**
  String get mediaTypeAll;

  /// No description provided for @mediaTypeImage.
  ///
  /// In en, this message translates to:
  /// **'images'**
  String get mediaTypeImage;

  /// No description provided for @mediaTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'videos'**
  String get mediaTypeVideo;

  /// No description provided for @memorySizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Memory size'**
  String get memorySizeLabel;

  /// No description provided for @mergeAdjacentRounds.
  ///
  /// In en, this message translates to:
  /// **'Merge adjacent rounds'**
  String get mergeAdjacentRounds;

  /// No description provided for @mergeAdjacentRoundsHelp.
  ///
  /// In en, this message translates to:
  /// **'Auto-merge rounds less than 3 seconds apart'**
  String get mergeAdjacentRoundsHelp;

  /// No description provided for @mergeServeAndHit.
  ///
  /// In en, this message translates to:
  /// **'Merge serve and hit'**
  String get mergeServeAndHit;

  /// No description provided for @mergeServeAndHitTooltip.
  ///
  /// In en, this message translates to:
  /// **'Include serve-only rallies (faults) and practice segments when enabled'**
  String get mergeServeAndHitTooltip;

  /// No description provided for @messageTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String messageTimeLabel(String time);

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @minDurationHint.
  ///
  /// In en, this message translates to:
  /// **'Rounds shorter than this will not be kept'**
  String get minDurationHint;

  /// No description provided for @minHighlightDuration.
  ///
  /// In en, this message translates to:
  /// **'Minimum highlight duration'**
  String get minHighlightDuration;

  /// No description provided for @minHighlightDurationSeconds.
  ///
  /// In en, this message translates to:
  /// **'Min highlight duration (sec)'**
  String get minHighlightDurationSeconds;

  /// No description provided for @minHighlightDurationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Minimum highlight duration (seconds)'**
  String get minHighlightDurationTooltip;

  /// No description provided for @minRoundDuration.
  ///
  /// In en, this message translates to:
  /// **'Min rally duration (sec)'**
  String get minRoundDuration;

  /// No description provided for @minRoundDurationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Minimum rally duration (seconds)'**
  String get minRoundDurationTooltip;

  /// No description provided for @minutesDecimalValue.
  ///
  /// In en, this message translates to:
  /// **'{value} min'**
  String minutesDecimalValue(String value);

  /// No description provided for @minutesValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesValue(int minutes);

  /// No description provided for @mobileDevice.
  ///
  /// In en, this message translates to:
  /// **'Mobile device'**
  String get mobileDevice;

  /// No description provided for @modelNotFound.
  ///
  /// In en, this message translates to:
  /// **'Model not found: {modelName}'**
  String modelNotFound(String modelName);

  /// No description provided for @monthlyBilledLabel.
  ///
  /// In en, this message translates to:
  /// **'/ month, billed monthly'**
  String get monthlyBilledLabel;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @namedFeatureInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'{featureName} is under development...'**
  String namedFeatureInDevelopment(String featureName);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get navVideos;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @networkDebugSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Debug network requests'**
  String get networkDebugSubtitle;

  /// No description provided for @networkDebugTitle.
  ///
  /// In en, this message translates to:
  /// **'Network debug'**
  String get networkDebugTitle;

  /// No description provided for @networkPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'API environment and downloads'**
  String get networkPageSubtitle;

  /// No description provided for @newClip.
  ///
  /// In en, this message translates to:
  /// **'New clip'**
  String get newClip;

  /// No description provided for @newFileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'New file name'**
  String get newFileNameLabel;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @newVersionFound.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get newVersionFound;

  /// No description provided for @noAlbumsFound.
  ///
  /// In en, this message translates to:
  /// **'No albums found'**
  String get noAlbumsFound;

  /// No description provided for @noChangelogEntries.
  ///
  /// In en, this message translates to:
  /// **'No changelog entries'**
  String get noChangelogEntries;

  /// No description provided for @noCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks'**
  String get noCompletedTasks;

  /// No description provided for @noFavoriteRounds.
  ///
  /// In en, this message translates to:
  /// **'No favorite rounds'**
  String get noFavoriteRounds;

  /// No description provided for @noItemsSelected.
  ///
  /// In en, this message translates to:
  /// **'No items selected'**
  String get noItemsSelected;

  /// No description provided for @noLogFilesFound.
  ///
  /// In en, this message translates to:
  /// **'No log files found'**
  String get noLogFilesFound;

  /// No description provided for @noMatchingFiles.
  ///
  /// In en, this message translates to:
  /// **'No matching files found'**
  String get noMatchingFiles;

  /// No description provided for @noMatchingMediaFiles.
  ///
  /// In en, this message translates to:
  /// **'No matching {mediaType} files found'**
  String noMatchingMediaFiles(String mediaType);

  /// No description provided for @noMediaFiles.
  ///
  /// In en, this message translates to:
  /// **'No {mediaType} files found'**
  String noMediaFiles(String mediaType);

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get noMessages;

  /// No description provided for @noMoreData.
  ///
  /// In en, this message translates to:
  /// **'No more data'**
  String get noMoreData;

  /// No description provided for @noPlayableVideos.
  ///
  /// In en, this message translates to:
  /// **'No playable videos'**
  String get noPlayableVideos;

  /// No description provided for @noPlayingRound.
  ///
  /// In en, this message translates to:
  /// **'No round is currently playing'**
  String get noPlayingRound;

  /// No description provided for @noProcessingRecords.
  ///
  /// In en, this message translates to:
  /// **'No processing records'**
  String get noProcessingRecords;

  /// No description provided for @noRoundSegments.
  ///
  /// In en, this message translates to:
  /// **'No round segments'**
  String get noRoundSegments;

  /// No description provided for @noSegmentsToExport.
  ///
  /// In en, this message translates to:
  /// **'No segments to export'**
  String get noSegmentsToExport;

  /// No description provided for @noSegmentsToSave.
  ///
  /// In en, this message translates to:
  /// **'No segments to save'**
  String get noSegmentsToSave;

  /// No description provided for @noSegmentsYet.
  ///
  /// In en, this message translates to:
  /// **'No segments yet'**
  String get noSegmentsYet;

  /// No description provided for @noTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get noTasks;

  /// No description provided for @noValidSegments.
  ///
  /// In en, this message translates to:
  /// **'No valid segments found'**
  String get noValidSegments;

  /// No description provided for @noVideo.
  ///
  /// In en, this message translates to:
  /// **'No video'**
  String get noVideo;

  /// No description provided for @noVideoData.
  ///
  /// In en, this message translates to:
  /// **'No video data'**
  String get noVideoData;

  /// No description provided for @noVideoDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No video data available'**
  String get noVideoDataAvailable;

  /// No description provided for @noVideos.
  ///
  /// In en, this message translates to:
  /// **'No videos yet'**
  String get noVideos;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @notBound.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get notBound;

  /// No description provided for @officialMatchPreset.
  ///
  /// In en, this message translates to:
  /// **'Official match preset'**
  String get officialMatchPreset;

  /// No description provided for @officialWebsite.
  ///
  /// In en, this message translates to:
  /// **'Official website'**
  String get officialWebsite;

  /// No description provided for @openBrowserFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open browser: {error}'**
  String openBrowserFailed(String error);

  /// No description provided for @openCloudClipFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to enable cloud clipping: {error}'**
  String openCloudClipFailed(String error);

  /// No description provided for @openEditFeatureFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open editing'**
  String get openEditFeatureFailed;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get openFile;

  /// No description provided for @openFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open file: {error}'**
  String openFileFailed(String error);

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get openFolder;

  /// No description provided for @openFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open folder: {error}'**
  String openFolderFailed(String error);

  /// No description provided for @openThisFolder.
  ///
  /// In en, this message translates to:
  /// **'Open this folder'**
  String get openThisFolder;

  /// No description provided for @operationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Operation cancelled'**
  String get operationCancelled;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get operationFailed;

  /// No description provided for @operationFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String operationFailedWithError(String error);

  /// No description provided for @orLabel.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orLabel;

  /// No description provided for @originalSize.
  ///
  /// In en, this message translates to:
  /// **'Original size'**
  String get originalSize;

  /// No description provided for @outputQualityLabel.
  ///
  /// In en, this message translates to:
  /// **'Output quality'**
  String get outputQualityLabel;

  /// No description provided for @outputVideoLabel.
  ///
  /// In en, this message translates to:
  /// **'Output video'**
  String get outputVideoLabel;

  /// No description provided for @packageDurationValidity.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min · valid for {validity}'**
  String packageDurationValidity(int minutes, String validity);

  /// No description provided for @pageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load page'**
  String get pageLoadFailed;

  /// No description provided for @passwordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password: {error}'**
  String passwordChangeFailed(String error);

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @pathCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Path copied to clipboard'**
  String get pathCopiedToClipboard;

  /// No description provided for @pathNotFound.
  ///
  /// In en, this message translates to:
  /// **'Path not found: {path}'**
  String pathNotFound(String path);

  /// No description provided for @pauseTask.
  ///
  /// In en, this message translates to:
  /// **'Pause task'**
  String get pauseTask;

  /// No description provided for @pendingLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending logs'**
  String get pendingLogsTitle;

  /// No description provided for @pendingLogsWithCount.
  ///
  /// In en, this message translates to:
  /// **'Pending logs ({count} entries)'**
  String pendingLogsWithCount(int count);

  /// No description provided for @performanceMonitorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor app performance'**
  String get performanceMonitorSubtitle;

  /// No description provided for @performanceMonitorTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance monitor'**
  String get performanceMonitorTitle;

  /// No description provided for @permanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent'**
  String get permanent;

  /// No description provided for @permissionCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission check'**
  String get permissionCheckTitle;

  /// No description provided for @permissionChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking: {permissionName}'**
  String permissionChecking(String permissionName);

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @permissionDeniedRetry.
  ///
  /// In en, this message translates to:
  /// **'{permissionName} was denied. Please try again.'**
  String permissionDeniedRetry(String permissionName);

  /// No description provided for @permissionDescriptionBody.
  ///
  /// In en, this message translates to:
  /// **'The app needs the following permissions to work properly. If a permission is denied, related features may not work.'**
  String get permissionDescriptionBody;

  /// No description provided for @permissionDescriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'About permissions'**
  String get permissionDescriptionTitle;

  /// No description provided for @permissionDetailAudio.
  ///
  /// In en, this message translates to:
  /// **'Plays video and audio content.'**
  String get permissionDetailAudio;

  /// No description provided for @permissionDetailCamera.
  ///
  /// In en, this message translates to:
  /// **'Records new video content, including photo and video capture.'**
  String get permissionDetailCamera;

  /// No description provided for @permissionDetailDefault.
  ///
  /// In en, this message translates to:
  /// **'Required for app functionality.'**
  String get permissionDetailDefault;

  /// No description provided for @permissionDetailMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Captures audio while recording videos.'**
  String get permissionDetailMicrophone;

  /// No description provided for @permissionDetailNotification.
  ///
  /// In en, this message translates to:
  /// **'Shows progress notifications while processing videos in the background.'**
  String get permissionDetailNotification;

  /// No description provided for @permissionDetailPhotos.
  ///
  /// In en, this message translates to:
  /// **'Accesses photos and videos in your library for editing.'**
  String get permissionDetailPhotos;

  /// No description provided for @permissionDetailStorage.
  ///
  /// In en, this message translates to:
  /// **'Saves edited videos to device storage and reads existing videos.'**
  String get permissionDetailStorage;

  /// No description provided for @permissionDetailVideos.
  ///
  /// In en, this message translates to:
  /// **'Accesses video files on device storage in various formats.'**
  String get permissionDetailVideos;

  /// No description provided for @permissionDiagnosticDenied.
  ///
  /// In en, this message translates to:
  /// **'  Denied: {count}'**
  String permissionDiagnosticDenied(int count);

  /// No description provided for @permissionDiagnosticDetailStatus.
  ///
  /// In en, this message translates to:
  /// **'Detailed status:'**
  String get permissionDiagnosticDetailStatus;

  /// No description provided for @permissionDiagnosticFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load diagnostics: {error}'**
  String permissionDiagnosticFetchFailed(String error);

  /// No description provided for @permissionDiagnosticGranted.
  ///
  /// In en, this message translates to:
  /// **'  Granted: {count}'**
  String permissionDiagnosticGranted(int count);

  /// No description provided for @permissionDiagnosticGrantedRate.
  ///
  /// In en, this message translates to:
  /// **'  Grant rate: {percent}%'**
  String permissionDiagnosticGrantedRate(String percent);

  /// No description provided for @permissionDiagnosticPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'  Permanently denied: {count}'**
  String permissionDiagnosticPermanentlyDenied(int count);

  /// No description provided for @permissionDiagnosticStats.
  ///
  /// In en, this message translates to:
  /// **'Permission summary:'**
  String get permissionDiagnosticStats;

  /// No description provided for @permissionDiagnosticTime.
  ///
  /// In en, this message translates to:
  /// **'Diagnosed at: {timestamp}'**
  String permissionDiagnosticTime(String timestamp);

  /// No description provided for @permissionDiagnosticTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission diagnostics'**
  String get permissionDiagnosticTitle;

  /// No description provided for @permissionDiagnosticTotal.
  ///
  /// In en, this message translates to:
  /// **'  Total: {count}'**
  String permissionDiagnosticTotal(int count);

  /// No description provided for @permissionExplanation.
  ///
  /// In en, this message translates to:
  /// **'This permission is required for the app to work properly. Tap \"Allow\" in the system dialog.'**
  String get permissionExplanation;

  /// No description provided for @permissionGrantedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{permissionName} granted successfully'**
  String permissionGrantedSuccess(String permissionName);

  /// No description provided for @permissionManagement.
  ///
  /// In en, this message translates to:
  /// **'Permission management'**
  String get permissionManagement;

  /// No description provided for @permissionNameAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get permissionNameAudio;

  /// No description provided for @permissionNameCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get permissionNameCamera;

  /// No description provided for @permissionNameMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get permissionNameMicrophone;

  /// No description provided for @permissionNameNotification.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permissionNameNotification;

  /// No description provided for @permissionNamePhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get permissionNamePhotos;

  /// No description provided for @permissionNameStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get permissionNameStorage;

  /// No description provided for @permissionNameUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown permission'**
  String get permissionNameUnknown;

  /// No description provided for @permissionNameVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get permissionNameVideos;

  /// No description provided for @permissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'{permissionName} was permanently denied. Please enable it manually in Settings.'**
  String permissionPermanentlyDenied(String permissionName);

  /// No description provided for @permissionStatusDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get permissionStatusDenied;

  /// No description provided for @permissionStatusGranted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get permissionStatusGranted;

  /// No description provided for @permissionStatusLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get permissionStatusLimited;

  /// No description provided for @permissionStatusMessage.
  ///
  /// In en, this message translates to:
  /// **'{permissionName} status: {status}'**
  String permissionStatusMessage(String permissionName, String status);

  /// No description provided for @permissionStatusPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Permanently denied'**
  String get permissionStatusPermanentlyDenied;

  /// No description provided for @permissionStatusRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get permissionStatusRestricted;

  /// No description provided for @permissionStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get permissionStatusUnknown;

  /// No description provided for @permissionSuggestionDenied.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Request permission\" to try again.'**
  String get permissionSuggestionDenied;

  /// No description provided for @permissionSuggestionLimited.
  ///
  /// In en, this message translates to:
  /// **'Partially granted; some features may be limited.'**
  String get permissionSuggestionLimited;

  /// No description provided for @permissionSuggestionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Enable manually in system settings.'**
  String get permissionSuggestionPermanentlyDenied;

  /// No description provided for @permissionSuggestionRestricted.
  ///
  /// In en, this message translates to:
  /// **'Permission is restricted by the system. Contact your administrator.'**
  String get permissionSuggestionRestricted;

  /// No description provided for @permissionTestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Test app permissions'**
  String get permissionTestSubtitle;

  /// No description provided for @permissionTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission test'**
  String get permissionTestTitle;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @phoneStorageTab.
  ///
  /// In en, this message translates to:
  /// **'Phone storage'**
  String get phoneStorageTab;

  /// No description provided for @pickFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get pickFromGallery;

  /// No description provided for @pickImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String pickImageFailed(String error);

  /// No description provided for @pingPongAutoClipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic table tennis match video clipping'**
  String get pingPongAutoClipSubtitle;

  /// No description provided for @pingPongMatchVideoClip.
  ///
  /// In en, this message translates to:
  /// **'Table tennis match video clipping'**
  String get pingPongMatchVideoClip;

  /// No description provided for @pingPongVideoAutoClip.
  ///
  /// In en, this message translates to:
  /// **'Table tennis auto clip'**
  String get pingPongVideoAutoClip;

  /// No description provided for @platformLabel.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platformLabel;

  /// No description provided for @playSegmentFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to play segment: {error}'**
  String playSegmentFailedWithError(String error);

  /// No description provided for @playSelectedSegmentOnly.
  ///
  /// In en, this message translates to:
  /// **'Play segment only'**
  String get playSelectedSegmentOnly;

  /// No description provided for @playSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get playSpeed;

  /// No description provided for @playVideo.
  ///
  /// In en, this message translates to:
  /// **'Play video'**
  String get playVideo;

  /// No description provided for @playbackItemNotFound.
  ///
  /// In en, this message translates to:
  /// **'Playback item not found'**
  String get playbackItemNotFound;

  /// No description provided for @playingNow.
  ///
  /// In en, this message translates to:
  /// **'▶ Playing'**
  String get playingNow;

  /// No description provided for @pleaseEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter a detailed description'**
  String get pleaseEnterDescription;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @pleaseSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Please select gender'**
  String get pleaseSelectGender;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @precisionEditButton.
  ///
  /// In en, this message translates to:
  /// **'✎ Precision edit'**
  String get precisionEditButton;

  /// No description provided for @precisionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Precision edit'**
  String get precisionEditTitle;

  /// No description provided for @prepareDownload.
  ///
  /// In en, this message translates to:
  /// **'Preparing download'**
  String get prepareDownload;

  /// No description provided for @prepareVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to prepare video: {error}'**
  String prepareVideoFailed(String error);

  /// No description provided for @presetComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Preset feature coming soon'**
  String get presetComingSoon;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewTitle;

  /// No description provided for @processDetectionResultFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to process detection result: {error}'**
  String processDetectionResultFailed(String error);

  /// No description provided for @processFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Processing failed. Please try again.'**
  String get processFailedRetry;

  /// No description provided for @processStatusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get processStatusPreparing;

  /// No description provided for @processVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to process video'**
  String get processVideoFailed;

  /// No description provided for @processedTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Processed time: {seconds} s'**
  String processedTimeLabel(int seconds);

  /// No description provided for @processingEffectLabel.
  ///
  /// In en, this message translates to:
  /// **'Processing result'**
  String get processingEffectLabel;

  /// No description provided for @processingHistory.
  ///
  /// In en, this message translates to:
  /// **'Processing history'**
  String get processingHistory;

  /// No description provided for @processingNow.
  ///
  /// In en, this message translates to:
  /// **'Processing now'**
  String get processingNow;

  /// No description provided for @processingSpeed.
  ///
  /// In en, this message translates to:
  /// **'Processing speed: {speed} sec/min'**
  String processingSpeed(String speed);

  /// No description provided for @processingSpeedPerSecond.
  ///
  /// In en, this message translates to:
  /// **'Processing speed: {speed} s/s'**
  String processingSpeedPerSecond(String speed);

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productNameLabel;

  /// No description provided for @profileDefaultUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get profileDefaultUsername;

  /// No description provided for @progressPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress: {percent}%'**
  String progressPercentLabel(String percent);

  /// No description provided for @progressTaskCancelled.
  ///
  /// In en, this message translates to:
  /// **'Task cancelled'**
  String get progressTaskCancelled;

  /// No description provided for @progressTaskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed'**
  String get progressTaskCompleted;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @purchaseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm purchase'**
  String get purchaseConfirm;

  /// No description provided for @purchaseConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Purchase {packageName}?\nDuration: {minutes} min\nPrice: ¥{price}'**
  String purchaseConfirmMessage(String packageName, int minutes, String price);

  /// No description provided for @purchaseFeatureInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Purchase feature is under development...'**
  String get purchaseFeatureInDevelopment;

  /// No description provided for @qualityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get qualityLabel;

  /// No description provided for @queuePosition.
  ///
  /// In en, this message translates to:
  /// **'Queue position: {position}'**
  String queuePosition(String position);

  /// No description provided for @quickAccessCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get quickAccessCamera;

  /// No description provided for @quickAccessDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get quickAccessDocuments;

  /// No description provided for @quickAccessDownload.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get quickAccessDownload;

  /// No description provided for @quickAccessPictures.
  ///
  /// In en, this message translates to:
  /// **'Pictures'**
  String get quickAccessPictures;

  /// No description provided for @quickAccessVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get quickAccessVideos;

  /// No description provided for @quickTry.
  ///
  /// In en, this message translates to:
  /// **'Quick try'**
  String get quickTry;

  /// No description provided for @quickTryHint.
  ///
  /// In en, this message translates to:
  /// **'No video needed — try the clipping flow with built-in samples'**
  String get quickTryHint;

  /// No description provided for @readLogContentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read log content: {error}'**
  String readLogContentFailed(String error);

  /// No description provided for @realtimeDetecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting in real time'**
  String get realtimeDetecting;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @recordAndClip.
  ///
  /// In en, this message translates to:
  /// **'Record & clip'**
  String get recordAndClip;

  /// No description provided for @recordAndClipCloud.
  ///
  /// In en, this message translates to:
  /// **'Record & clip (cloud)'**
  String get recordAndClipCloud;

  /// No description provided for @recordAndClipDescription.
  ///
  /// In en, this message translates to:
  /// **'Record with the camera while marking and clipping segments in real time'**
  String get recordAndClipDescription;

  /// No description provided for @recordAndClipLocal.
  ///
  /// In en, this message translates to:
  /// **'Record & clip (local)'**
  String get recordAndClipLocal;

  /// No description provided for @recordAndClipMode.
  ///
  /// In en, this message translates to:
  /// **'Record & clip mode'**
  String get recordAndClipMode;

  /// No description provided for @recordAndClipRealtimeDetection.
  ///
  /// In en, this message translates to:
  /// **'Record & clip real-time detection'**
  String get recordAndClipRealtimeDetection;

  /// No description provided for @recordAndClipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record and clip video in real time'**
  String get recordAndClipSubtitle;

  /// No description provided for @recordDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Record details'**
  String get recordDetailTitle;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get refreshStatus;

  /// No description provided for @registryOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Registry owner'**
  String get registryOwnerLabel;

  /// No description provided for @remainingDuration.
  ///
  /// In en, this message translates to:
  /// **'Remaining time'**
  String get remainingDuration;

  /// No description provided for @remark.
  ///
  /// In en, this message translates to:
  /// **'Remark: {info}'**
  String remark(String info);

  /// No description provided for @remarkInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarkInfoSection;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @removeReplay.
  ///
  /// In en, this message translates to:
  /// **'Remove replays'**
  String get removeReplay;

  /// No description provided for @removeReplayHelp.
  ///
  /// In en, this message translates to:
  /// **'Automatically skip replay segments'**
  String get removeReplayHelp;

  /// No description provided for @removeReplayTooltipPro.
  ///
  /// In en, this message translates to:
  /// **'Usually only in pro matches, e.g. WTT replays'**
  String get removeReplayTooltipPro;

  /// No description provided for @removeReplayTooltipShort.
  ///
  /// In en, this message translates to:
  /// **'Usually only in pro matches'**
  String get removeReplayTooltipShort;

  /// No description provided for @renameFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename file'**
  String get renameFileTitle;

  /// No description provided for @renameSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Renamed successfully'**
  String get renameSucceeded;

  /// No description provided for @renew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get renew;

  /// No description provided for @reorderFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to reorder: {error}'**
  String reorderFailedWithError(String error);

  /// No description provided for @reprocessButton.
  ///
  /// In en, this message translates to:
  /// **'Reprocess'**
  String get reprocessButton;

  /// No description provided for @requestAllPermissions.
  ///
  /// In en, this message translates to:
  /// **'Request all permissions'**
  String get requestAllPermissions;

  /// No description provided for @requestPermission.
  ///
  /// In en, this message translates to:
  /// **'Request permission'**
  String get requestPermission;

  /// No description provided for @requestPermissionError.
  ///
  /// In en, this message translates to:
  /// **'Error requesting permission: {error}'**
  String requestPermissionError(String error);

  /// No description provided for @requestPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Request {permissionName}'**
  String requestPermissionTitle(String permissionName);

  /// No description provided for @reserveAfterRound.
  ///
  /// In en, this message translates to:
  /// **'Post-round buffer (sec)'**
  String get reserveAfterRound;

  /// No description provided for @reserveAfterRoundTooltip.
  ///
  /// In en, this message translates to:
  /// **'Seconds to keep after each rally ends'**
  String get reserveAfterRoundTooltip;

  /// No description provided for @reserveBeforeRound.
  ///
  /// In en, this message translates to:
  /// **'Pre-round buffer'**
  String get reserveBeforeRound;

  /// No description provided for @reserveBeforeRoundTooltip.
  ///
  /// In en, this message translates to:
  /// **'Seconds to keep before each rally starts'**
  String get reserveBeforeRoundTooltip;

  /// No description provided for @resetAppConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This will clear all app data, including settings, cache, and user data. This action cannot be undone.'**
  String get resetAppConfirmMessage;

  /// No description provided for @resetAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all app data'**
  String get resetAppSubtitle;

  /// No description provided for @resetAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset app'**
  String get resetAppTitle;

  /// No description provided for @resumeTask.
  ///
  /// In en, this message translates to:
  /// **'Resume task'**
  String get resumeTask;

  /// No description provided for @retryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry failed: {error}'**
  String retryFailed(String error);

  /// No description provided for @returnToHome.
  ///
  /// In en, this message translates to:
  /// **'Return to home'**
  String get returnToHome;

  /// No description provided for @roundClip.
  ///
  /// In en, this message translates to:
  /// **'Round clip'**
  String get roundClip;

  /// No description provided for @roundCountBadge.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String roundCountBadge(int count);

  /// No description provided for @roundCountDurationSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} rounds · {duration} total'**
  String roundCountDurationSummary(int count, String duration);

  /// No description provided for @roundCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get roundCountLabel;

  /// No description provided for @roundCountShort.
  ///
  /// In en, this message translates to:
  /// **'{count} rounds'**
  String roundCountShort(int count);

  /// No description provided for @roundCountUnit.
  ///
  /// In en, this message translates to:
  /// **'rounds'**
  String get roundCountUnit;

  /// No description provided for @roundDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted current round'**
  String get roundDeletedSuccess;

  /// No description provided for @roundFavoritedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Favorited current round'**
  String get roundFavoritedSuccess;

  /// No description provided for @roundList.
  ///
  /// In en, this message translates to:
  /// **'Round list'**
  String get roundList;

  /// No description provided for @roundOrder.
  ///
  /// In en, this message translates to:
  /// **'Round order'**
  String get roundOrder;

  /// No description provided for @roundTransitionLabel.
  ///
  /// In en, this message translates to:
  /// **'Between-round transition'**
  String get roundTransitionLabel;

  /// No description provided for @roundUnfavoritedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Unfavorited current round'**
  String get roundUnfavoritedSuccess;

  /// No description provided for @saveAll.
  ///
  /// In en, this message translates to:
  /// **'Save all'**
  String get saveAll;

  /// No description provided for @saveAsPreset.
  ///
  /// In en, this message translates to:
  /// **'Save current as preset'**
  String get saveAsPreset;

  /// No description provided for @saveCleaningTempFiles.
  ///
  /// In en, this message translates to:
  /// **'Cleaning up temporary files...'**
  String get saveCleaningTempFiles;

  /// No description provided for @saveComplete.
  ///
  /// In en, this message translates to:
  /// **'Save complete!'**
  String get saveComplete;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(String error);

  /// No description provided for @saveFailedShort.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailedShort;

  /// No description provided for @saveLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Save location:'**
  String get saveLocationLabel;

  /// No description provided for @saveMergingSegments.
  ///
  /// In en, this message translates to:
  /// **'Merging video segments...'**
  String get saveMergingSegments;

  /// No description provided for @savePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing to save...'**
  String get savePreparing;

  /// No description provided for @savePreparingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Preparing save...'**
  String get savePreparingInProgress;

  /// No description provided for @saveProcessingSegmentsStart.
  ///
  /// In en, this message translates to:
  /// **'Processing video segments...'**
  String get saveProcessingSegmentsStart;

  /// No description provided for @saveProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Save progress'**
  String get saveProgressTitle;

  /// No description provided for @saveSavingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Saving metadata...'**
  String get saveSavingMetadata;

  /// No description provided for @saveSavingToGallery.
  ///
  /// In en, this message translates to:
  /// **'Saving to gallery...'**
  String get saveSavingToGallery;

  /// No description provided for @saveSegmentFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save segments: {error}'**
  String saveSegmentFailedWithError(String error);

  /// No description provided for @saveToGallery.
  ///
  /// In en, this message translates to:
  /// **'Save to gallery'**
  String get saveToGallery;

  /// No description provided for @saveToLabel.
  ///
  /// In en, this message translates to:
  /// **'Save to'**
  String get saveToLabel;

  /// No description provided for @saveTrimmingSegment.
  ///
  /// In en, this message translates to:
  /// **'Trimming segment...'**
  String get saveTrimmingSegment;

  /// No description provided for @saveTrimmingSegments.
  ///
  /// In en, this message translates to:
  /// **'Trimming video segments...'**
  String get saveTrimmingSegments;

  /// No description provided for @saveTrimmingSegmentsProgress.
  ///
  /// In en, this message translates to:
  /// **'Trimming video segments... {percent}%'**
  String saveTrimmingSegmentsProgress(String percent);

  /// No description provided for @savedImagesCount.
  ///
  /// In en, this message translates to:
  /// **'Saved {count} image(s) to gallery'**
  String savedImagesCount(int count);

  /// No description provided for @savedToGallery.
  ///
  /// In en, this message translates to:
  /// **'Saved to gallery'**
  String get savedToGallery;

  /// No description provided for @screenshotCaptureFailedWithLogs.
  ///
  /// In en, this message translates to:
  /// **'Screenshot failed: {logs}'**
  String screenshotCaptureFailedWithLogs(String logs);

  /// No description provided for @screenshotCapturing.
  ///
  /// In en, this message translates to:
  /// **'Capturing screenshot...'**
  String get screenshotCapturing;

  /// No description provided for @screenshotCompleted.
  ///
  /// In en, this message translates to:
  /// **'Screenshot complete'**
  String get screenshotCompleted;

  /// No description provided for @screenshotFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Screenshot failed'**
  String get screenshotFailedTitle;

  /// No description provided for @screenshotFileNotGenerated.
  ///
  /// In en, this message translates to:
  /// **'Screenshot file was not generated'**
  String get screenshotFileNotGenerated;

  /// No description provided for @screenshotGeneratingImage.
  ///
  /// In en, this message translates to:
  /// **'Generating image...'**
  String get screenshotGeneratingImage;

  /// No description provided for @screenshotPrepare.
  ///
  /// In en, this message translates to:
  /// **'Preparing screenshot...'**
  String get screenshotPrepare;

  /// No description provided for @screenshotProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Screenshot progress'**
  String get screenshotProgressTitle;

  /// No description provided for @screenshotSavingToGallery.
  ///
  /// In en, this message translates to:
  /// **'Saving to gallery...'**
  String get screenshotSavingToGallery;

  /// No description provided for @sdkVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'SDK version'**
  String get sdkVersionLabel;

  /// No description provided for @searchFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Search failed: {error}'**
  String searchFailedWithError(String error);

  /// No description provided for @searchFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Search files'**
  String get searchFilesTitle;

  /// No description provided for @searchLogsHint.
  ///
  /// In en, this message translates to:
  /// **'Search logs...'**
  String get searchLogsHint;

  /// No description provided for @searchMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Search media'**
  String get searchMediaTitle;

  /// No description provided for @searchPathDcim.
  ///
  /// In en, this message translates to:
  /// **'DCIM / Camera'**
  String get searchPathDcim;

  /// No description provided for @searchPathDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents folder'**
  String get searchPathDocuments;

  /// No description provided for @searchPathDownload.
  ///
  /// In en, this message translates to:
  /// **'Downloads folder'**
  String get searchPathDownload;

  /// No description provided for @searchPathEntireStorage.
  ///
  /// In en, this message translates to:
  /// **'Entire storage'**
  String get searchPathEntireStorage;

  /// No description provided for @searchPathMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies folder'**
  String get searchPathMovies;

  /// No description provided for @searchPathMusic.
  ///
  /// In en, this message translates to:
  /// **'Music folder'**
  String get searchPathMusic;

  /// No description provided for @searchPathPictures.
  ///
  /// In en, this message translates to:
  /// **'Pictures folder'**
  String get searchPathPictures;

  /// No description provided for @searchResultsAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {count} search result(s) to selection'**
  String searchResultsAdded(int count);

  /// No description provided for @searchScope.
  ///
  /// In en, this message translates to:
  /// **'Search scope'**
  String get searchScope;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @searchingFiles.
  ///
  /// In en, this message translates to:
  /// **'Searching files...'**
  String get searchingFiles;

  /// No description provided for @seekBackward1s.
  ///
  /// In en, this message translates to:
  /// **'-1s'**
  String get seekBackward1s;

  /// No description provided for @seekBackward5s.
  ///
  /// In en, this message translates to:
  /// **'-5s'**
  String get seekBackward5s;

  /// No description provided for @seekForward1s.
  ///
  /// In en, this message translates to:
  /// **'+1s'**
  String get seekForward1s;

  /// No description provided for @seekForward5s.
  ///
  /// In en, this message translates to:
  /// **'+5s'**
  String get seekForward5s;

  /// No description provided for @segmentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Segment not found'**
  String get segmentNotFound;

  /// No description provided for @segmentsDetectedResult.
  ///
  /// In en, this message translates to:
  /// **'Detected {count} match segment(s) ({seconds}s)'**
  String segmentsDetectedResult(int count, int seconds);

  /// No description provided for @selectAlbum.
  ///
  /// In en, this message translates to:
  /// **'Select album'**
  String get selectAlbum;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @selectClipMode.
  ///
  /// In en, this message translates to:
  /// **'Select clipping method'**
  String get selectClipMode;

  /// No description provided for @selectClipModeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to clip your video'**
  String get selectClipModeHint;

  /// No description provided for @selectDirectoryPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select a directory'**
  String get selectDirectoryPrompt;

  /// No description provided for @selectDirectoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Select directory'**
  String get selectDirectoryTitle;

  /// No description provided for @selectExportQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Select export quality'**
  String get selectExportQualityTitle;

  /// No description provided for @selectFiles.
  ///
  /// In en, this message translates to:
  /// **'Select files'**
  String get selectFiles;

  /// No description provided for @selectFilesAndDirectoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Select files and directories'**
  String get selectFilesAndDirectoriesTitle;

  /// No description provided for @selectFilesOrDirectoriesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select file(s) or directory'**
  String get selectFilesOrDirectoriesPrompt;

  /// No description provided for @selectFilesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please select file(s)'**
  String get selectFilesPrompt;

  /// No description provided for @selectFilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Select files'**
  String get selectFilesTitle;

  /// No description provided for @selectGender.
  ///
  /// In en, this message translates to:
  /// **'Select gender'**
  String get selectGender;

  /// No description provided for @selectImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Select images'**
  String get selectImagesTitle;

  /// No description provided for @selectMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Select media'**
  String get selectMediaTitle;

  /// No description provided for @selectRoundFromLeft.
  ///
  /// In en, this message translates to:
  /// **'Select a round from the left'**
  String get selectRoundFromLeft;

  /// No description provided for @selectSportType.
  ///
  /// In en, this message translates to:
  /// **'Select sport type'**
  String get selectSportType;

  /// No description provided for @selectSportTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select the sport type of the video you want to clip'**
  String get selectSportTypeHint;

  /// No description provided for @selectThisDirectory.
  ///
  /// In en, this message translates to:
  /// **'Select this directory'**
  String get selectThisDirectory;

  /// No description provided for @selectTimeRange.
  ///
  /// In en, this message translates to:
  /// **'Select time range'**
  String get selectTimeRange;

  /// No description provided for @selectVideoFileFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a video file first'**
  String get selectVideoFileFirst;

  /// No description provided for @selectVideoFileFirstError.
  ///
  /// In en, this message translates to:
  /// **'Please select a video file first'**
  String get selectVideoFileFirstError;

  /// No description provided for @selectVideosTitle.
  ///
  /// In en, this message translates to:
  /// **'Select videos'**
  String get selectVideosTitle;

  /// No description provided for @selectedCountShort.
  ///
  /// In en, this message translates to:
  /// **'Selected: {count}'**
  String selectedCountShort(int count);

  /// No description provided for @selectedFirstNItems.
  ///
  /// In en, this message translates to:
  /// **'Selected first {count} item(s)'**
  String selectedFirstNItems(int count);

  /// No description provided for @selectedItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedItemsCount(int count);

  /// No description provided for @selectedRounds.
  ///
  /// In en, this message translates to:
  /// **'Selected rounds'**
  String get selectedRounds;

  /// No description provided for @selectionSummaryDirsOnly.
  ///
  /// In en, this message translates to:
  /// **' ({dirCount} dirs)'**
  String selectionSummaryDirsOnly(String dirCount);

  /// No description provided for @selectionSummaryFilesAndDirs.
  ///
  /// In en, this message translates to:
  /// **' ({fileCount} files, {dirCount} dirs)'**
  String selectionSummaryFilesAndDirs(String fileCount, String dirCount);

  /// No description provided for @selectionSummaryFilesOnly.
  ///
  /// In en, this message translates to:
  /// **' ({fileCount} files)'**
  String selectionSummaryFilesOnly(String fileCount);

  /// No description provided for @selectionSummaryItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String selectionSummaryItems(int count);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsAllDownloadFiles.
  ///
  /// In en, this message translates to:
  /// **'All downloaded files'**
  String get settingsAllDownloadFiles;

  /// No description provided for @settingsAllFilesCleanupDone.
  ///
  /// In en, this message translates to:
  /// **'All files cleaned'**
  String get settingsAllFilesCleanupDone;

  /// No description provided for @settingsAllFilesCleanupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clean all files: {error}'**
  String settingsAllFilesCleanupFailed(String error);

  /// No description provided for @settingsAlreadyLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest version'**
  String get settingsAlreadyLatestVersion;

  /// No description provided for @settingsApiServer.
  ///
  /// In en, this message translates to:
  /// **'API server'**
  String get settingsApiServer;

  /// No description provided for @settingsApiServerDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsApiServerDefault;

  /// No description provided for @settingsApiServerDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the API environment to connect to'**
  String get settingsApiServerDesc;

  /// No description provided for @settingsApiServerSandbox.
  ///
  /// In en, this message translates to:
  /// **'Sandbox'**
  String get settingsApiServerSandbox;

  /// No description provided for @settingsAppData.
  ///
  /// In en, this message translates to:
  /// **'App data'**
  String get settingsAppData;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsCacheCleanupDone.
  ///
  /// In en, this message translates to:
  /// **'Cache cleaned'**
  String get settingsCacheCleanupDone;

  /// No description provided for @settingsCacheCleanupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clean cache: {error}'**
  String settingsCacheCleanupFailed(String error);

  /// No description provided for @settingsCacheFiles.
  ///
  /// In en, this message translates to:
  /// **'Cache files'**
  String get settingsCacheFiles;

  /// No description provided for @settingsCheckUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsCheckUpdate;

  /// No description provided for @settingsCheckUpdateOnStart.
  ///
  /// In en, this message translates to:
  /// **'Check for updates on startup'**
  String get settingsCheckUpdateOnStart;

  /// No description provided for @settingsCheckUpdateOnStartDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically check for new versions when the app launches'**
  String get settingsCheckUpdateOnStartDesc;

  /// No description provided for @settingsChooseCleanupContent.
  ///
  /// In en, this message translates to:
  /// **'Choose what to clean up:'**
  String get settingsChooseCleanupContent;

  /// No description provided for @settingsChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get settingsChooseLanguage;

  /// No description provided for @settingsCleanupAll.
  ///
  /// In en, this message translates to:
  /// **'Clean all'**
  String get settingsCleanupAll;

  /// No description provided for @settingsClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get settingsClearAll;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsClearCache;

  /// No description provided for @settingsConfirmCleanup.
  ///
  /// In en, this message translates to:
  /// **'Confirm cleanup'**
  String get settingsConfirmCleanup;

  /// No description provided for @settingsConfirmCleanupAction.
  ///
  /// In en, this message translates to:
  /// **'Clean up'**
  String get settingsConfirmCleanupAction;

  /// No description provided for @settingsConfirmCleanupMessage.
  ///
  /// In en, this message translates to:
  /// **'Clean up {title}? This cannot be undone.'**
  String settingsConfirmCleanupMessage(String title);

  /// No description provided for @settingsConfirmDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsConfirmDeleteAction;

  /// No description provided for @settingsConfirmDeleteFileMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete file \"{fileName}\"? This cannot be undone.'**
  String settingsConfirmDeleteFileMessage(String fileName);

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsDefaultSavePath.
  ///
  /// In en, this message translates to:
  /// **'Default save path'**
  String get settingsDefaultSavePath;

  /// No description provided for @settingsDefaultSavePathValue.
  ///
  /// In en, this message translates to:
  /// **'~/Videos/Huji'**
  String get settingsDefaultSavePathValue;

  /// No description provided for @settingsDownloadCleanupDone.
  ///
  /// In en, this message translates to:
  /// **'Downloads cleaned'**
  String get settingsDownloadCleanupDone;

  /// No description provided for @settingsDownloadCleanupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to clean downloads: {error}'**
  String settingsDownloadCleanupFailed(String error);

  /// No description provided for @settingsDownloadConcurrency.
  ///
  /// In en, this message translates to:
  /// **'Download concurrency'**
  String get settingsDownloadConcurrency;

  /// No description provided for @settingsDownloadConcurrencyDesc.
  ///
  /// In en, this message translates to:
  /// **'Number of videos to download at once'**
  String get settingsDownloadConcurrencyDesc;

  /// No description provided for @settingsDownloadFileList.
  ///
  /// In en, this message translates to:
  /// **'Downloaded files'**
  String get settingsDownloadFileList;

  /// No description provided for @settingsDownloadFiles.
  ///
  /// In en, this message translates to:
  /// **'Downloaded files'**
  String get settingsDownloadFiles;

  /// No description provided for @settingsDownloadListFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load download list: {error}'**
  String settingsDownloadListFailed(String error);

  /// No description provided for @settingsExternalStorage.
  ///
  /// In en, this message translates to:
  /// **'External storage'**
  String get settingsExternalStorage;

  /// No description provided for @settingsFileDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete file: {error}'**
  String settingsFileDeleteFailed(String error);

  /// No description provided for @settingsFileDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'File deleted'**
  String get settingsFileDeleteSuccess;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get settingsLanguageUpdated;

  /// No description provided for @settingsNoDownloadFiles.
  ///
  /// In en, this message translates to:
  /// **'No downloaded files'**
  String get settingsNoDownloadFiles;

  /// No description provided for @settingsNotificationsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Notification settings updated'**
  String get settingsNotificationsUpdated;

  /// No description provided for @settingsPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize your Huji desktop experience'**
  String get settingsPageSubtitle;

  /// No description provided for @settingsPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get settingsPermissions;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get settingsPushNotifications;

  /// No description provided for @settingsSendUsageStats.
  ///
  /// In en, this message translates to:
  /// **'Send usage statistics'**
  String get settingsSendUsageStats;

  /// No description provided for @settingsSendUsageStatsDesc.
  ///
  /// In en, this message translates to:
  /// **'Send anonymous usage data to help improve the app'**
  String get settingsSendUsageStatsDesc;

  /// No description provided for @settingsStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get settingsStorage;

  /// No description provided for @settingsThemeChanged.
  ///
  /// In en, this message translates to:
  /// **'Theme updated'**
  String get settingsThemeChanged;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTotalUsedSpace.
  ///
  /// In en, this message translates to:
  /// **'Total used: {size}'**
  String settingsTotalUsedSpace(String size);

  /// No description provided for @settingsUserAgreement.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get settingsUserAgreement;

  /// No description provided for @settingsUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get settingsUsername;

  /// No description provided for @settingsVersionInfo.
  ///
  /// In en, this message translates to:
  /// **'Version info'**
  String get settingsVersionInfo;

  /// No description provided for @settingsViewDownloadFiles.
  ///
  /// In en, this message translates to:
  /// **'View downloaded files'**
  String get settingsViewDownloadFiles;

  /// No description provided for @setupLater.
  ///
  /// In en, this message translates to:
  /// **'Set up later'**
  String get setupLater;

  /// No description provided for @shareFeatureInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Share feature is under development...'**
  String get shareFeatureInDevelopment;

  /// No description provided for @shareLogsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to share logs: {error}'**
  String shareLogsFailed(String error);

  /// No description provided for @shortcutsCategoryEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get shortcutsCategoryEditing;

  /// No description provided for @shortcutsCategoryMeta.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get shortcutsCategoryMeta;

  /// No description provided for @shortcutsCategoryNavigation.
  ///
  /// In en, this message translates to:
  /// **'Navigation'**
  String get shortcutsCategoryNavigation;

  /// No description provided for @shortcutsCategoryView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get shortcutsCategoryView;

  /// No description provided for @shortcutsChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get shortcutsChange;

  /// No description provided for @shortcutsCheatsheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Press {chord} anytime to open this list'**
  String shortcutsCheatsheetSubtitle(String chord);

  /// No description provided for @shortcutsCommandCloseOrBack.
  ///
  /// In en, this message translates to:
  /// **'Close / Back'**
  String get shortcutsCommandCloseOrBack;

  /// No description provided for @shortcutsCommandNewClip.
  ///
  /// In en, this message translates to:
  /// **'New Clip'**
  String get shortcutsCommandNewClip;

  /// No description provided for @shortcutsCommandOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get shortcutsCommandOpenSettings;

  /// No description provided for @shortcutsCommandOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'Open Tasks'**
  String get shortcutsCommandOpenTasks;

  /// No description provided for @shortcutsCommandShowCheatsheet.
  ///
  /// In en, this message translates to:
  /// **'Show Keyboard Shortcuts'**
  String get shortcutsCommandShowCheatsheet;

  /// No description provided for @shortcutsCommandToggleSidebar.
  ///
  /// In en, this message translates to:
  /// **'Toggle Sidebar'**
  String get shortcutsCommandToggleSidebar;

  /// No description provided for @shortcutsCommandPrecisionPlayPause.
  ///
  /// In en, this message translates to:
  /// **'Play / Pause'**
  String get shortcutsCommandPrecisionPlayPause;

  /// No description provided for @shortcutsCommandPrecisionSplit.
  ///
  /// In en, this message translates to:
  /// **'Split at playhead'**
  String get shortcutsCommandPrecisionSplit;

  /// No description provided for @shortcutsCommandPrecisionAddSegment.
  ///
  /// In en, this message translates to:
  /// **'Add segment'**
  String get shortcutsCommandPrecisionAddSegment;

  /// No description provided for @shortcutsCommandPrecisionDeleteSegment.
  ///
  /// In en, this message translates to:
  /// **'Delete segment'**
  String get shortcutsCommandPrecisionDeleteSegment;

  /// No description provided for @shortcutsCommandPrecisionPlaySelectedOnly.
  ///
  /// In en, this message translates to:
  /// **'Play selected segment only'**
  String get shortcutsCommandPrecisionPlaySelectedOnly;

  /// No description provided for @shortcutsCommandPrecisionToggleSlowMotion.
  ///
  /// In en, this message translates to:
  /// **'Toggle slow motion'**
  String get shortcutsCommandPrecisionToggleSlowMotion;

  /// No description provided for @shortcutsCommandPrecisionPrevRound.
  ///
  /// In en, this message translates to:
  /// **'Previous round'**
  String get shortcutsCommandPrecisionPrevRound;

  /// No description provided for @shortcutsCommandPrecisionNextRound.
  ///
  /// In en, this message translates to:
  /// **'Next round'**
  String get shortcutsCommandPrecisionNextRound;

  /// No description provided for @shortcutsCommandPrecisionSeekBackward.
  ///
  /// In en, this message translates to:
  /// **'Seek backward 1s'**
  String get shortcutsCommandPrecisionSeekBackward;

  /// No description provided for @shortcutsCommandPrecisionSeekForward.
  ///
  /// In en, this message translates to:
  /// **'Seek forward 1s'**
  String get shortcutsCommandPrecisionSeekForward;

  /// No description provided for @shortcutsConflictTooltip.
  ///
  /// In en, this message translates to:
  /// **'Conflicts with another command'**
  String get shortcutsConflictTooltip;

  /// No description provided for @shortcutsExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get shortcutsExport;

  /// No description provided for @shortcutsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to export shortcuts'**
  String get shortcutsExportFailed;

  /// No description provided for @shortcutsExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts exported'**
  String get shortcutsExportSuccess;

  /// No description provided for @shortcutsImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get shortcutsImport;

  /// No description provided for @shortcutsImportConflictMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} imported bindings conflict with existing commands. Replace them?'**
  String shortcutsImportConflictMessage(int count);

  /// No description provided for @shortcutsImportConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Conflicts detected'**
  String get shortcutsImportConflictTitle;

  /// No description provided for @shortcutsImportInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'Not a valid shortcuts file'**
  String get shortcutsImportInvalidFile;

  /// No description provided for @shortcutsImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts imported'**
  String get shortcutsImportSuccess;

  /// No description provided for @shortcutsNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get shortcutsNotSet;

  /// No description provided for @shortcutsPressNewChord.
  ///
  /// In en, this message translates to:
  /// **'Press a new key combination'**
  String get shortcutsPressNewChord;

  /// No description provided for @shortcutsPressNewChordHint.
  ///
  /// In en, this message translates to:
  /// **'Esc to cancel · Backspace to clear'**
  String get shortcutsPressNewChordHint;

  /// No description provided for @shortcutsRebind.
  ///
  /// In en, this message translates to:
  /// **'Change shortcut'**
  String get shortcutsRebind;

  /// No description provided for @shortcutsReplaceAction.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get shortcutsReplaceAction;

  /// No description provided for @shortcutsReplaceCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep current'**
  String get shortcutsReplaceCancel;

  /// No description provided for @shortcutsReplaceConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{chord} is already used by \"{command}\". Replace it?'**
  String shortcutsReplaceConfirmBody(String chord, String command);

  /// No description provided for @shortcutsReplaceConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace shortcut?'**
  String get shortcutsReplaceConfirmTitle;

  /// No description provided for @shortcutsReplaceProceed.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get shortcutsReplaceProceed;

  /// No description provided for @shortcutsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get shortcutsReset;

  /// No description provided for @shortcutsResetAll.
  ///
  /// In en, this message translates to:
  /// **'Restore all defaults'**
  String get shortcutsResetAll;

  /// No description provided for @shortcutsResetAllConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All customized shortcuts will be restored to their defaults.'**
  String get shortcutsResetAllConfirmBody;

  /// No description provided for @shortcutsResetAllConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore all defaults?'**
  String get shortcutsResetAllConfirmTitle;

  /// No description provided for @shortcutsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search shortcuts'**
  String get shortcutsSearchHint;

  /// No description provided for @shortcutsSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and customize keyboard shortcuts'**
  String get shortcutsSectionSubtitle;

  /// No description provided for @shortcutsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get shortcutsSectionTitle;

  /// No description provided for @shortcutsUnbind.
  ///
  /// In en, this message translates to:
  /// **'Unbind'**
  String get shortcutsUnbind;

  /// No description provided for @shortcutsViewCheatsheet.
  ///
  /// In en, this message translates to:
  /// **'View all shortcuts'**
  String get shortcutsViewCheatsheet;

  /// No description provided for @showSystemLogsLabel.
  ///
  /// In en, this message translates to:
  /// **'Show system logs'**
  String get showSystemLogsLabel;

  /// No description provided for @sizeReducedLabel.
  ///
  /// In en, this message translates to:
  /// **'Size reduced'**
  String get sizeReducedLabel;

  /// No description provided for @slowMotion.
  ///
  /// In en, this message translates to:
  /// **'Slow motion'**
  String get slowMotion;

  /// No description provided for @softwareEncoderDetectFailed.
  ///
  /// In en, this message translates to:
  /// **'Software encoder detection failed: {error}'**
  String softwareEncoderDetectFailed(String error);

  /// No description provided for @softwareEncoderNotFound.
  ///
  /// In en, this message translates to:
  /// **'No suitable software encoder found'**
  String get softwareEncoderNotFound;

  /// No description provided for @sortByFileSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get sortByFileSize;

  /// No description provided for @sortByFileType.
  ///
  /// In en, this message translates to:
  /// **'File type'**
  String get sortByFileType;

  /// No description provided for @sortByModifiedTime.
  ///
  /// In en, this message translates to:
  /// **'Modified time'**
  String get sortByModifiedTime;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortByName;

  /// No description provided for @sortOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortOptionsTitle;

  /// No description provided for @sourceLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get sourceLocal;

  /// No description provided for @sourceNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get sourceNetwork;

  /// No description provided for @splashInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get splashInitializing;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Table tennis & badminton match video editing'**
  String get splashTagline;

  /// No description provided for @sportBadminton.
  ///
  /// In en, this message translates to:
  /// **'Badminton'**
  String get sportBadminton;

  /// No description provided for @sportClipDescription.
  ///
  /// In en, this message translates to:
  /// **'Supports singles and doubles; automatically identifies highlight rallies'**
  String get sportClipDescription;

  /// No description provided for @sportPingPong.
  ///
  /// In en, this message translates to:
  /// **'Table tennis'**
  String get sportPingPong;

  /// No description provided for @sportTypeBadminton.
  ///
  /// In en, this message translates to:
  /// **'Badminton'**
  String get sportTypeBadminton;

  /// No description provided for @sportTypePingpong.
  ///
  /// In en, this message translates to:
  /// **'Table tennis'**
  String get sportTypePingpong;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDateLabel;

  /// No description provided for @startDetectionClip.
  ///
  /// In en, this message translates to:
  /// **'Start detection & clip'**
  String get startDetectionClip;

  /// No description provided for @startDownload.
  ///
  /// In en, this message translates to:
  /// **'Starting download...'**
  String get startDownload;

  /// No description provided for @startExport.
  ///
  /// In en, this message translates to:
  /// **'Start export'**
  String get startExport;

  /// No description provided for @startFrameMustBeLessThanEnd.
  ///
  /// In en, this message translates to:
  /// **'Start frame must be less than end frame'**
  String get startFrameMustBeLessThanEnd;

  /// No description provided for @startTimeCannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Start time cannot be negative'**
  String get startTimeCannotBeNegative;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get statusPreparing;

  /// No description provided for @statusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get statusProcessing;

  /// No description provided for @storageCategoryWithSize.
  ///
  /// In en, this message translates to:
  /// **'{label}: {size}'**
  String storageCategoryWithSize(String label, String size);

  /// No description provided for @storageInfoCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating storage info...'**
  String get storageInfoCalculating;

  /// No description provided for @storageInfoFetchFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to get storage info: {error}'**
  String storageInfoFetchFailedWithError(String error);

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required to access files'**
  String get storagePermissionRequired;

  /// No description provided for @submitFailedRetryLater.
  ///
  /// In en, this message translates to:
  /// **'Submission failed. Please try again later.'**
  String get submitFailedRetryLater;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit feedback'**
  String get submitFeedback;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @subscriptionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm subscription'**
  String get subscriptionConfirm;

  /// No description provided for @subscriptionConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to the {planName} plan?\nMonthly fee: ¥{price}'**
  String subscriptionConfirmMessage(String planName, String price);

  /// No description provided for @subscriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Subscription failed: {error}'**
  String subscriptionFailed(String error);

  /// No description provided for @subscriptionPlans.
  ///
  /// In en, this message translates to:
  /// **'Subscription plans'**
  String get subscriptionPlans;

  /// No description provided for @subscriptionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully subscribed to {planName}!'**
  String subscriptionSuccess(String planName);

  /// No description provided for @supportedVideoFormats.
  ///
  /// In en, this message translates to:
  /// **'Common video formats supported'**
  String get supportedVideoFormats;

  /// No description provided for @switchTabClearSelectionMessage.
  ///
  /// In en, this message translates to:
  /// **'Switching tabs will clear your current selection. Continue?'**
  String get switchTabClearSelectionMessage;

  /// No description provided for @switchTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch tab'**
  String get switchTabTitle;

  /// No description provided for @switchToGridMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to grid view'**
  String get switchToGridMode;

  /// No description provided for @switchToListMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to list view'**
  String get switchToListMode;

  /// No description provided for @systemInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View detailed system information'**
  String get systemInfoSubtitle;

  /// No description provided for @systemInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'System info'**
  String get systemInfoTitle;

  /// No description provided for @systemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'System name'**
  String get systemNameLabel;

  /// No description provided for @systemVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'System version'**
  String get systemVersionLabel;

  /// No description provided for @tabFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get tabFiles;

  /// No description provided for @tabPhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get tabPhotoGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @taskCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled task \"{taskName}\"'**
  String taskCancelled(String taskName);

  /// No description provided for @taskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted task \"{taskName}\"'**
  String taskDeleted(String taskName);

  /// No description provided for @taskPauseNotSupported.
  ///
  /// In en, this message translates to:
  /// **'{taskType} tasks cannot be paused'**
  String taskPauseNotSupported(String taskType);

  /// No description provided for @taskPauseNotSupportedWithCancel.
  ///
  /// In en, this message translates to:
  /// **'{taskType} tasks cannot be paused; use Cancel instead'**
  String taskPauseNotSupportedWithCancel(String taskType);

  /// No description provided for @taskPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused task \"{taskName}\"'**
  String taskPaused(String taskName);

  /// No description provided for @taskPhaseAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing video…'**
  String get taskPhaseAnalyzing;

  /// No description provided for @taskPhaseClipping.
  ///
  /// In en, this message translates to:
  /// **'Clipping video…'**
  String get taskPhaseClipping;

  /// No description provided for @taskPhaseDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading results…'**
  String get taskPhaseDownloading;

  /// No description provided for @taskPhaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Processing failed'**
  String get taskPhaseFailed;

  /// No description provided for @taskPhaseGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating final video…'**
  String get taskPhaseGenerating;

  /// No description provided for @taskPhasePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get taskPhasePaused;

  /// No description provided for @taskPhasePending.
  ///
  /// In en, this message translates to:
  /// **'Task submitted, waiting…'**
  String get taskPhasePending;

  /// No description provided for @taskPhaseProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get taskPhaseProcessing;

  /// No description provided for @taskPhaseUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading video…'**
  String get taskPhaseUploading;

  /// No description provided for @taskRecords.
  ///
  /// In en, this message translates to:
  /// **'Task records'**
  String get taskRecords;

  /// No description provided for @taskResumed.
  ///
  /// In en, this message translates to:
  /// **'Resumed task \"{taskName}\"'**
  String taskResumed(String taskName);

  /// No description provided for @taskStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get taskStatusCancelled;

  /// No description provided for @taskStatusCancelledShort.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get taskStatusCancelledShort;

  /// No description provided for @taskStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskStatusCompleted;

  /// No description provided for @taskStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get taskStatusFailed;

  /// No description provided for @taskStatusFilter.
  ///
  /// In en, this message translates to:
  /// **'Task status'**
  String get taskStatusFilter;

  /// No description provided for @taskStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get taskStatusInProgress;

  /// No description provided for @taskStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get taskStatusPaused;

  /// No description provided for @taskStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get taskStatusPending;

  /// No description provided for @taskStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get taskStatusProcessing;

  /// No description provided for @taskSubmittedWaiting.
  ///
  /// In en, this message translates to:
  /// **'Task submitted, waiting to start...'**
  String get taskSubmittedWaiting;

  /// No description provided for @taskTypeDownload.
  ///
  /// In en, this message translates to:
  /// **'File download'**
  String get taskTypeDownload;

  /// No description provided for @taskTypeFilter.
  ///
  /// In en, this message translates to:
  /// **'Task type'**
  String get taskTypeFilter;

  /// No description provided for @taskTypeFilterSelected.
  ///
  /// In en, this message translates to:
  /// **'Task type · {count}'**
  String taskTypeFilterSelected(int count);

  /// No description provided for @taskTypeImageCompress.
  ///
  /// In en, this message translates to:
  /// **'Image compress'**
  String get taskTypeImageCompress;

  /// No description provided for @taskTypeSegmentDetectShort.
  ///
  /// In en, this message translates to:
  /// **'Real-time detect'**
  String get taskTypeSegmentDetectShort;

  /// No description provided for @taskTypeVideoClip.
  ///
  /// In en, this message translates to:
  /// **'Video clip'**
  String get taskTypeVideoClip;

  /// No description provided for @taskTypeVideoCompress.
  ///
  /// In en, this message translates to:
  /// **'Video compress'**
  String get taskTypeVideoCompress;

  /// No description provided for @taskTypeVideoSegmentDetect.
  ///
  /// In en, this message translates to:
  /// **'Real-time video segment detection'**
  String get taskTypeVideoSegmentDetect;

  /// No description provided for @taskTypeVideoUpload.
  ///
  /// In en, this message translates to:
  /// **'Video upload'**
  String get taskTypeVideoUpload;

  /// No description provided for @tasksSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted {successCount} task(s){failSuffix}'**
  String tasksSubmitted(int successCount, String failSuffix);

  /// No description provided for @tasksSubmittedFailSuffix.
  ///
  /// In en, this message translates to:
  /// **', {failCount} failed'**
  String tasksSubmittedFailSuffix(int failCount);

  /// No description provided for @testEnvironmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Test environment'**
  String get testEnvironmentSubtitle;

  /// No description provided for @testPageAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open test page'**
  String get testPageAccessSubtitle;

  /// No description provided for @testPageForFeaturesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For testing various features'**
  String get testPageForFeaturesSubtitle;

  /// No description provided for @testPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Test page'**
  String get testPageTitle;

  /// No description provided for @themeColorPresetDescription.
  ///
  /// In en, this message translates to:
  /// **'Primary and accent colors for controls'**
  String get themeColorPresetDescription;

  /// No description provided for @themeColorPresetTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme colors'**
  String get themeColorPresetTitle;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @themeModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Default appearance or follow the system'**
  String get themeModeDescription;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme mode'**
  String get themeModeTitle;

  /// No description provided for @themePresetAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get themePresetAmber;

  /// No description provided for @themePresetForest.
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get themePresetForest;

  /// No description provided for @themePresetGraphite.
  ///
  /// In en, this message translates to:
  /// **'Graphite'**
  String get themePresetGraphite;

  /// No description provided for @themePresetOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get themePresetOcean;

  /// No description provided for @themePresetViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get themePresetViolet;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @thumbnailFileNotGenerated.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail file was not generated: {path}'**
  String thumbnailFileNotGenerated(String path);

  /// No description provided for @thumbnailGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate thumbnail: {path}: {error}'**
  String thumbnailGenerateFailed(String path, String error);

  /// No description provided for @thumbnailGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate thumbnail: {detail}'**
  String thumbnailGenerationFailed(String detail);

  /// No description provided for @timeRangeFilter.
  ///
  /// In en, this message translates to:
  /// **'Time range'**
  String get timeRangeFilter;

  /// No description provided for @totalDurationLabel.
  ///
  /// In en, this message translates to:
  /// **'Total duration'**
  String get totalDurationLabel;

  /// No description provided for @totalUsage.
  ///
  /// In en, this message translates to:
  /// **'Total used'**
  String get totalUsage;

  /// No description provided for @trainingPreset.
  ///
  /// In en, this message translates to:
  /// **'Training match preset'**
  String get trainingPreset;

  /// No description provided for @transitionCrossfade.
  ///
  /// In en, this message translates to:
  /// **'Crossfade'**
  String get transitionCrossfade;

  /// No description provided for @transitionNone.
  ///
  /// In en, this message translates to:
  /// **'None (concatenate)'**
  String get transitionNone;

  /// No description provided for @transitionSlide.
  ///
  /// In en, this message translates to:
  /// **'Slide'**
  String get transitionSlide;

  /// No description provided for @trimSplitLabel.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get trimSplitLabel;

  /// No description provided for @tryModifySearchConditions.
  ///
  /// In en, this message translates to:
  /// **'Try changing your search'**
  String get tryModifySearchConditions;

  /// No description provided for @typographyScaleComfortable.
  ///
  /// In en, this message translates to:
  /// **'Comfortable'**
  String get typographyScaleComfortable;

  /// No description provided for @typographyScaleCompact.
  ///
  /// In en, this message translates to:
  /// **'Compact'**
  String get typographyScaleCompact;

  /// No description provided for @typographyScaleCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get typographyScaleCustom;

  /// No description provided for @typographyScaleCustomHint.
  ///
  /// In en, this message translates to:
  /// **'50–200'**
  String get typographyScaleCustomHint;

  /// No description provided for @typographyScaleDescription.
  ///
  /// In en, this message translates to:
  /// **'UI text size. Standard follows the system'**
  String get typographyScaleDescription;

  /// No description provided for @typographyScaleStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get typographyScaleStandard;

  /// No description provided for @typographyScaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get typographyScaleTitle;

  /// No description provided for @uiZoomDescription.
  ///
  /// In en, this message translates to:
  /// **'Scale text, icons, and spacing together'**
  String get uiZoomDescription;

  /// No description provided for @uiZoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Interface zoom'**
  String get uiZoomTitle;

  /// No description provided for @unfavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get unfavorite;

  /// No description provided for @unfavoriteCurrentRound.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite current round'**
  String get unfavoriteCurrentRound;

  /// No description provided for @unknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown device'**
  String get unknownDevice;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @unknownFile.
  ///
  /// In en, this message translates to:
  /// **'Unknown file'**
  String get unknownFile;

  /// No description provided for @unknownLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownLabel;

  /// No description provided for @unknownPlatform.
  ///
  /// In en, this message translates to:
  /// **'Unknown platform'**
  String get unknownPlatform;

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @untitledName.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitledName;

  /// No description provided for @updateContent.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get updateContent;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Update later'**
  String get updateLater;

  /// No description provided for @updatePlaybackListFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update playback list: {error}'**
  String updatePlaybackListFailedWithError(String error);

  /// No description provided for @updateTime.
  ///
  /// In en, this message translates to:
  /// **'Update date'**
  String get updateTime;

  /// No description provided for @uploadVideoHint.
  ///
  /// In en, this message translates to:
  /// **'Upload your match videos to automatically trim rest periods. You can leave this page while processing; you\'ll get a desktop notification when done.'**
  String get uploadVideoHint;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @uploadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Uploading video...'**
  String get uploadingVideo;

  /// No description provided for @useDemoVideo.
  ///
  /// In en, this message translates to:
  /// **'Or use a demo video'**
  String get useDemoVideo;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get used;

  /// No description provided for @usedDuration.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get usedDuration;

  /// No description provided for @userNameLabel.
  ///
  /// In en, this message translates to:
  /// **'User name'**
  String get userNameLabel;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @validityDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String validityDays(int days);

  /// No description provided for @versionCodenameLabel.
  ///
  /// In en, this message translates to:
  /// **'Version codename'**
  String get versionCodenameLabel;

  /// No description provided for @versionIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Version ID'**
  String get versionIdLabel;

  /// No description provided for @versionInfo.
  ///
  /// In en, this message translates to:
  /// **'Version info'**
  String get versionInfo;

  /// No description provided for @versionNumber.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get versionNumber;

  /// No description provided for @videoClipProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Video clip progress'**
  String get videoClipProgressTitle;

  /// No description provided for @videoComparisonSection.
  ///
  /// In en, this message translates to:
  /// **'Video comparison'**
  String get videoComparisonSection;

  /// No description provided for @videoCompressException.
  ///
  /// In en, this message translates to:
  /// **'Compression error: {error}'**
  String videoCompressException(String error);

  /// No description provided for @videoCompressFailed.
  ///
  /// In en, this message translates to:
  /// **'Compression failed: {logs}'**
  String videoCompressFailed(String logs);

  /// No description provided for @videoCompressInfoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to get video information'**
  String get videoCompressInfoUnavailable;

  /// No description provided for @videoCompressInputNotFound.
  ///
  /// In en, this message translates to:
  /// **'Input file not found: {path}'**
  String videoCompressInputNotFound(String path);

  /// No description provided for @videoCompressOutputNotGenerated.
  ///
  /// In en, this message translates to:
  /// **'Output file was not generated'**
  String get videoCompressOutputNotGenerated;

  /// No description provided for @videoCropFailed.
  ///
  /// In en, this message translates to:
  /// **'Video crop failed'**
  String get videoCropFailed;

  /// No description provided for @videoDuration.
  ///
  /// In en, this message translates to:
  /// **'Video duration: {duration}'**
  String videoDuration(String duration);

  /// No description provided for @videoDurationAndSize.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration} | Size: {size}'**
  String videoDurationAndSize(String duration, String size);

  /// No description provided for @videoDurationSeconds.
  ///
  /// In en, this message translates to:
  /// **'Video duration: {seconds} s'**
  String videoDurationSeconds(int seconds);

  /// No description provided for @videoEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Video editing'**
  String get videoEditTitle;

  /// No description provided for @videoExpiresAt.
  ///
  /// In en, this message translates to:
  /// **'{date} | expires {timeAgo}'**
  String videoExpiresAt(String date, String timeAgo);

  /// No description provided for @videoFileLabel.
  ///
  /// In en, this message translates to:
  /// **'Video file'**
  String get videoFileLabel;

  /// No description provided for @videoFileNotExist.
  ///
  /// In en, this message translates to:
  /// **'Video file does not exist'**
  String get videoFileNotExist;

  /// No description provided for @videoFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Video file not found: {path}'**
  String videoFileNotFound(String path);

  /// No description provided for @videoFileNotFoundWithPath.
  ///
  /// In en, this message translates to:
  /// **'Video file does not exist: {path}'**
  String videoFileNotFoundWithPath(String path);

  /// No description provided for @videoFileNotGenerated.
  ///
  /// In en, this message translates to:
  /// **'Video file was not generated'**
  String get videoFileNotGenerated;

  /// No description provided for @videoFormatConvertFailed.
  ///
  /// In en, this message translates to:
  /// **'Video format conversion failed'**
  String get videoFormatConvertFailed;

  /// No description provided for @videoInfoFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get video info: {output}'**
  String videoInfoFetchFailed(String output);

  /// No description provided for @videoLabel.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoLabel;

  /// No description provided for @videoListTitle.
  ///
  /// In en, this message translates to:
  /// **'Video list'**
  String get videoListTitle;

  /// No description provided for @videoLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading video...'**
  String get videoLoading;

  /// No description provided for @videoMergeFailed.
  ///
  /// In en, this message translates to:
  /// **'Video merge failed'**
  String get videoMergeFailed;

  /// No description provided for @videoNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Video name'**
  String get videoNameLabel;

  /// No description provided for @videoPathEmpty.
  ///
  /// In en, this message translates to:
  /// **'Video file path is empty'**
  String get videoPathEmpty;

  /// No description provided for @videoPlayerFileMovedOrDeleted.
  ///
  /// In en, this message translates to:
  /// **'The file was moved or deleted:\n{path}'**
  String videoPlayerFileMovedOrDeleted(String path);

  /// No description provided for @videoPlayerFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get videoPlayerFileNotFound;

  /// No description provided for @videoPlayerInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize player: {error}'**
  String videoPlayerInitFailed(String error);

  /// No description provided for @videoPlayerInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing player...'**
  String get videoPlayerInitializing;

  /// No description provided for @videoPlayerLoadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Loading video...'**
  String get videoPlayerLoadingVideo;

  /// No description provided for @videoPlayerNetworkInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize network player: {error}'**
  String videoPlayerNetworkInitFailed(String error);

  /// No description provided for @videoProcessType.
  ///
  /// In en, this message translates to:
  /// **'Video processing type'**
  String get videoProcessType;

  /// No description provided for @videoProcessTypeAllMatchMerged.
  ///
  /// In en, this message translates to:
  /// **'All rallies'**
  String get videoProcessTypeAllMatchMerged;

  /// No description provided for @videoProcessTypeGreatMatch.
  ///
  /// In en, this message translates to:
  /// **'Highlight rallies'**
  String get videoProcessTypeGreatMatch;

  /// No description provided for @videoProcessTypeRaw.
  ///
  /// In en, this message translates to:
  /// **'Original video'**
  String get videoProcessTypeRaw;

  /// No description provided for @videoProcessingComplete.
  ///
  /// In en, this message translates to:
  /// **'Video processing complete'**
  String get videoProcessingComplete;

  /// No description provided for @videoProcessingCompletedViewOutput.
  ///
  /// In en, this message translates to:
  /// **'Processing complete. You can view the output video.'**
  String get videoProcessingCompletedViewOutput;

  /// No description provided for @videoProcessingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Video is processing...'**
  String get videoProcessingInProgress;

  /// No description provided for @videoProcessingProgress.
  ///
  /// In en, this message translates to:
  /// **'Video processing progress'**
  String get videoProcessingProgress;

  /// No description provided for @videoQualityWarning.
  ///
  /// In en, this message translates to:
  /// **'Camera angle, framing, and resolution affect detection quality. Shoot horizontally at ≥ 720p and avoid heavy compression.'**
  String get videoQualityWarning;

  /// No description provided for @videoSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save video'**
  String get videoSaveFailed;

  /// No description provided for @videoSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Video saved to {path}'**
  String videoSavedTo(String path);

  /// No description provided for @videoScaleFailed.
  ///
  /// In en, this message translates to:
  /// **'Video scaling failed'**
  String get videoScaleFailed;

  /// No description provided for @videoSegmentDetection.
  ///
  /// In en, this message translates to:
  /// **'Video segment detection'**
  String get videoSegmentDetection;

  /// No description provided for @videoStillProcessingTryLater.
  ///
  /// In en, this message translates to:
  /// **'Video is still processing. Please try again later.'**
  String get videoStillProcessingTryLater;

  /// No description provided for @videoStreamNotFound.
  ///
  /// In en, this message translates to:
  /// **'Video stream not found'**
  String get videoStreamNotFound;

  /// No description provided for @videoWaitingProcessing.
  ///
  /// In en, this message translates to:
  /// **'Video is waiting to be processed...'**
  String get videoWaitingProcessing;

  /// No description provided for @videoWaitingWithQueue.
  ///
  /// In en, this message translates to:
  /// **'Video is waiting... {count} video(s) ahead in queue'**
  String videoWaitingWithQueue(int count);

  /// No description provided for @videosFolderName.
  ///
  /// In en, this message translates to:
  /// **'Huji'**
  String get videosFolderName;

  /// No description provided for @viewAppLogsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View app logs'**
  String get viewAppLogsSubtitle;

  /// No description provided for @viewChangelogHistory.
  ///
  /// In en, this message translates to:
  /// **'View version history'**
  String get viewChangelogHistory;

  /// No description provided for @viewFromEndLabel.
  ///
  /// In en, this message translates to:
  /// **'View from end'**
  String get viewFromEndLabel;

  /// No description provided for @viewLogsButton.
  ///
  /// In en, this message translates to:
  /// **'View logs'**
  String get viewLogsButton;

  /// No description provided for @viewProgress.
  ///
  /// In en, this message translates to:
  /// **'View progress'**
  String get viewProgress;

  /// No description provided for @viewTasks.
  ///
  /// In en, this message translates to:
  /// **'View tasks'**
  String get viewTasks;

  /// No description provided for @viewVideoButton.
  ///
  /// In en, this message translates to:
  /// **'View video'**
  String get viewVideoButton;

  /// No description provided for @waitingProcessTime.
  ///
  /// In en, this message translates to:
  /// **'Waiting time: {seconds} s'**
  String waitingProcessTime(int seconds);

  /// No description provided for @windowControlAlwaysOnTop.
  ///
  /// In en, this message translates to:
  /// **'Always on top'**
  String get windowControlAlwaysOnTop;

  /// No description provided for @windowControlClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get windowControlClose;

  /// No description provided for @windowControlMaximize.
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get windowControlMaximize;

  /// No description provided for @windowControlMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get windowControlMinimize;

  /// No description provided for @windowControlRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get windowControlRestore;

  /// No description provided for @wrapLinesLabel.
  ///
  /// In en, this message translates to:
  /// **'Wrap lines'**
  String get wrapLinesLabel;
}

class _HujiLocalizationsDelegate
    extends LocalizationsDelegate<HujiLocalizations> {
  const _HujiLocalizationsDelegate();

  @override
  Future<HujiLocalizations> load(Locale locale) {
    return SynchronousFuture<HujiLocalizations>(
      lookupHujiLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_HujiLocalizationsDelegate old) => false;
}

HujiLocalizations lookupHujiLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return HujiLocalizationsEn();
    case 'zh':
      return HujiLocalizationsZh();
  }

  throw FlutterError(
    'HujiLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
