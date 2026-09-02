// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class HujiLocalizationsEn extends HujiLocalizations {
  HujiLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aboutChangelogDescription =>
      'We are committed to delivering the best video editing experience. Each update brings new features and improvements. Thank you for your support!';

  @override
  String get aboutChangelogTitle => 'About changelog';

  @override
  String get account => 'Account';

  @override
  String get accountAndSecurity => 'Account & security';

  @override
  String get accountLoggedIn => 'Signed in';

  @override
  String get accountLogout => 'Sign out';

  @override
  String get accountMismatch =>
      'The entered account does not match the current account';

  @override
  String get accountNotLoggedIn => 'Not signed in';

  @override
  String get accountPageSubtitle => 'Sign-in status and profile';

  @override
  String get accountTapToLogin => 'Tap to sign in';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionClose => 'Close';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String actionConfirmWithCount(int count) {
    return 'Confirm ($count)';
  }

  @override
  String get actionContinue => 'Continue';

  @override
  String actionCountdownSeconds(int countdown) {
    return '${countdown}s';
  }

  @override
  String get actionCreate => 'Create';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionDone => 'Done';

  @override
  String get actionExport => 'Export';

  @override
  String get actionGetVerificationCode => 'Get code';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionPlay => 'Play';

  @override
  String get actionProcessing => 'Processing...';

  @override
  String get actionRefresh => 'Refresh';

  @override
  String get actionReload => 'Reload';

  @override
  String get actionRename => 'Rename';

  @override
  String actionResendCodeCountdown(int countdown) {
    return 'Resend in ${countdown}s';
  }

  @override
  String get actionReset => 'Reset';

  @override
  String get actionResume => 'Resume';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionSendVerificationCode => 'Send code';

  @override
  String get actionShare => 'Share';

  @override
  String get actionTypeFireBall => 'Serve';

  @override
  String get actionTypePickBall => 'Ball pickup';

  @override
  String get actionTypePlayBall => 'Highlight';

  @override
  String get actionTypePlayback => 'Replay';

  @override
  String get actionTypeTransition => 'Transition';

  @override
  String get actionView => 'View';

  @override
  String get activeCpuCountLabel => 'Active CPUs';

  @override
  String get addClipSegmentLabel => 'Add segment';

  @override
  String get addMoreFiles => '+ Add more';

  @override
  String addSelectedFiles(int count) {
    return 'Add $count file(s)';
  }

  @override
  String albumAllMediaSubtitle(String mediaType) {
    return 'All $mediaType files';
  }

  @override
  String albumCount(int count) {
    return '$count album(s)';
  }

  @override
  String get allRounds => 'All rounds';

  @override
  String get analyzingVideoContent => 'Analyzing video content...';

  @override
  String get androidVersionLabel => 'Android version';

  @override
  String get appFoldersTab => 'App folders';

  @override
  String get appNameLabel => 'App name';

  @override
  String get appTitle => 'Huji';

  @override
  String get appVersionLabel => 'App version';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearancePageSubtitle => 'Theme, text size, and language';

  @override
  String get applyFilter => 'Apply filters';

  @override
  String get architectureLabel => 'Architecture';

  @override
  String get authorize => 'Authorize';

  @override
  String avatarUploadFailed(String error) {
    return 'Failed to upload avatar: $error';
  }

  @override
  String get avatarUploadSuccess => 'Avatar uploaded successfully';

  @override
  String get backToPreview => '↩ Back to preview';

  @override
  String get backendClip => 'Background clip';

  @override
  String get backgroundDownload => 'Download in background';

  @override
  String get backgroundMediaProcessingDescription =>
      'Allows the app to process video compression in the background, even when you switch apps or lock the screen.';

  @override
  String get backgroundMediaProcessingPermission =>
      'Background media processing permission';

  @override
  String get backgroundServicePermissionDeniedHint =>
      'If you deny this permission, video compression will run in the foreground and may affect other apps.';

  @override
  String get backgroundServicePermissionIntro =>
      'To keep video compression running in the background, please grant the following permission:';

  @override
  String get backgroundServicePermissionTitle =>
      'Background service permission required';

  @override
  String get badmintonAutoClipSubtitle =>
      'Automatic badminton match video clipping';

  @override
  String get badmintonDefaultPreset => 'Badminton default';

  @override
  String get badmintonMatchVideoClip => 'Badminton match video clipping';

  @override
  String get badmintonVideoAutoClip => 'Badminton auto clip';

  @override
  String get basicInfo => 'Basic info';

  @override
  String get batchSelect => 'Select';

  @override
  String batchSelectedCount(int count) {
    return 'Selected $count';
  }

  @override
  String batchTasksDeleted(int count) {
    return 'Deleted $count task(s)';
  }

  @override
  String get booleanNo => 'No';

  @override
  String get booleanYes => 'Yes';

  @override
  String get browserDownload => 'Download in browser';

  @override
  String get buildNumber => 'Build number';

  @override
  String get buildVersionLabel => 'Build version';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get cachedBadge => 'Cached';

  @override
  String get calculating => 'Calculating...';

  @override
  String get calculatingFileSize => 'Calculating size...';

  @override
  String get cancelTask => 'Cancel task';

  @override
  String cannotAccessDirectory(String error) {
    return 'Cannot access this directory: $error';
  }

  @override
  String get cannotGenerateThumbnail => 'Unable to generate thumbnail';

  @override
  String get cannotLoadVideo => 'Unable to load video';

  @override
  String get cannotOpenDownloadLink => 'Unable to open download link';

  @override
  String get cannotOpenLink => 'Unable to open link';

  @override
  String cannotOpenLogViewer(String error) {
    return 'Cannot open log viewer: $error';
  }

  @override
  String get cannotOpenLogViewerNavigatorNotInitialized =>
      'Cannot open log viewer: Navigator not initialized';

  @override
  String get changeAvatar => 'Change avatar';

  @override
  String get changePassword => 'Change password';

  @override
  String get changelog => 'Changelog';

  @override
  String get checkAlbumPermissionOrEmpty =>
      'Check album permissions or whether albums are empty';

  @override
  String get classNameLabel => 'Class name:';

  @override
  String get clearAllFilters => 'Clear all';

  @override
  String get clearAppCacheSubtitle => 'Clear app cache';

  @override
  String clearCacheFailed(String error) {
    return 'Failed to clear cache: $error';
  }

  @override
  String get clearCacheTitle => 'Clear cache';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String clearLogsFailed(String error) {
    return 'Failed to clear logs: $error';
  }

  @override
  String get clearSearch => 'Clear search';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get clearTypeFilter => 'Clear type filter';

  @override
  String get clearedLogsOlderThan7Days => 'Cleared logs older than 7 days';

  @override
  String get clipCompleted => 'Clip completed!';

  @override
  String get clipConfig => 'Clip settings';

  @override
  String get clipMode => 'Clip mode';

  @override
  String get clipOptions => 'Clip options';

  @override
  String get clipOptionsTitle => 'Options';

  @override
  String get clipRecords => 'Clip records';

  @override
  String get clipTaskCreatedRedirecting =>
      'Clip task created. Redirecting to tasks...';

  @override
  String get clippingVideo => 'Clipping video...';

  @override
  String get cloudClip => 'Cloud clip';

  @override
  String get cloudClipUnavailable => 'Cloud clipping is unavailable';

  @override
  String get cloudDetection => 'Cloud detection';

  @override
  String get cloudDetectionHelp => 'Requires internet; higher accuracy';

  @override
  String get cloudDetectionHint =>
      'Uses cloud services for detection; internet required';

  @override
  String cloudDetectionTaskName(String fileName) {
    return 'Cloud detection: $fileName';
  }

  @override
  String get compressedSize => 'Compressed size';

  @override
  String get compressionRatio => 'Compression ratio';

  @override
  String compressionResults(int count) {
    return 'Compression results ($count images)';
  }

  @override
  String get computerNameLabel => 'Computer name';

  @override
  String configPresetMismatch(int count, String presetName) {
    return '$count settings differ from \"$presetName\"';
  }

  @override
  String confirmBatchDeleteMessage(int count) {
    return 'Delete $count selected task(s)? This cannot be undone.';
  }

  @override
  String get confirmCancel => 'Confirm cancel';

  @override
  String confirmCancelTaskMessage(String taskName) {
    return 'Cancel task \"$taskName\"? This cannot be undone.';
  }

  @override
  String get confirmClearCacheMessage => 'Clear cache for this video?';

  @override
  String get confirmDelete => 'Confirm delete';

  @override
  String get confirmDeleteCurrentPlayingRound =>
      'Delete the currently playing round? This cannot be undone.';

  @override
  String get confirmDeleteFileMessage =>
      'Delete this file? This cannot be undone.';

  @override
  String get confirmDeleteLocalVideoMessage =>
      'Are you sure you want to delete this local video?';

  @override
  String confirmDeleteTaskMessage(String taskName) {
    return 'Delete task \"$taskName\"? This cannot be undone.';
  }

  @override
  String get confirmExportTitle => 'Confirm export';

  @override
  String get confirmLogoutMessage => 'Are you sure you want to sign out?';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmPurchase => 'Confirm purchase';

  @override
  String get confirmSubscription => 'Confirm subscription';

  @override
  String contactInfoPrefix(String contact) {
    return 'Contact info: $contact';
  }

  @override
  String get contactOptionalHint => 'Contact info (optional)';

  @override
  String get contactUs => 'Contact us';

  @override
  String get copyPath => 'Copy path';

  @override
  String countdownSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String createFolderFailedWithError(String error) {
    return 'Failed to create folder: $error';
  }

  @override
  String get createFolderHere => 'New folder here';

  @override
  String get createTaskFailed => 'Failed to create task';

  @override
  String createTaskFailedWithError(String error) {
    return 'Failed to create task: $error';
  }

  @override
  String get createTimeLabel => 'Created at';

  @override
  String createdAt(String time) {
    return 'Created at: $time';
  }

  @override
  String createdAtWithValue(String time) {
    return 'Created: $time';
  }

  @override
  String get createdTimeRange => 'Created time range';

  @override
  String get creatingTask => 'Creating task...';

  @override
  String get current => 'Current';

  @override
  String get currentDirectoryLabel => 'Current directory';

  @override
  String get currentDuration => 'Current duration';

  @override
  String currentEditingRound(String label) {
    return 'Editing: $label';
  }

  @override
  String currentFile(String path) {
    return 'Current file: $path';
  }

  @override
  String get currentPlanLabel => 'Current plan';

  @override
  String get currentVersion => 'Current version';

  @override
  String get customClip => 'Custom clip';

  @override
  String get customerHotline => 'Customer hotline';

  @override
  String get dartVersionLabel => 'Dart version';

  @override
  String get dataManagementSection => 'Data management';

  @override
  String get databaseDebugSubtitle => 'View database contents';

  @override
  String get databaseDebugTitle => 'Database debug';

  @override
  String get dateRangeTo => 'to';

  @override
  String get debugFeaturesSection => 'Debug features';

  @override
  String get defaultHighlightName => 'Highlights';

  @override
  String get defaultPreset => 'Default preset';

  @override
  String get deleteCurrentRound => 'Delete current round';

  @override
  String deleteFailedWithError(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get deleteFile => 'Delete file';

  @override
  String get deleteTask => 'Delete task';

  @override
  String get demoBadmintonSubtitle => '~51s · sample video';

  @override
  String get demoBadmintonTitle => 'Badminton demo';

  @override
  String get demoPingPongSubtitle => '~23s · sample video';

  @override
  String get demoPingPongTitle => 'Table tennis demo';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String get desktopDevice => 'Desktop device';

  @override
  String get desktopLibraryEmptyHint =>
      'Click \"New clip\" to upload match footage';

  @override
  String get desktopLibraryEmptyTitle => 'No videos yet';

  @override
  String desktopLibraryItemCount(int count) {
    return '$count items';
  }

  @override
  String desktopLibraryLoadFailed(String error) {
    return 'Failed to load: $error';
  }

  @override
  String get desktopLibraryTitle => 'Video library';

  @override
  String get desktopNavLibrary => 'Library';

  @override
  String get desktopNavSettings => 'Settings';

  @override
  String get desktopNavTasks => 'Tasks';

  @override
  String get desktopNewClip => 'New clip';

  @override
  String get desktopWorkspaceSection => 'Workspace';

  @override
  String get detectedSegments => 'Detected segments';

  @override
  String get detectionMode => 'Detection mode';

  @override
  String get devToolsSection => 'Developer tools';

  @override
  String get developerModeAlreadyEnabled => 'Developer mode is already enabled';

  @override
  String get developerModeEnabledMessage =>
      'Developer mode enabled. You can now access developer features.';

  @override
  String get developerModeTitle => 'Developer mode';

  @override
  String get developerModeWarning =>
      'These features are for development and debugging only. Use with caution.';

  @override
  String get developerOptions => 'Developer options';

  @override
  String get developerOptionsDescription =>
      'Access developer tools and debugging features';

  @override
  String get developerPasswordIncorrect => 'Incorrect developer password';

  @override
  String get deviceBrandLabel => 'Brand';

  @override
  String get deviceIdLabel => 'Device ID';

  @override
  String get deviceIdentifierLabel => 'Device identifier';

  @override
  String get deviceInfoFetchFailed => 'Failed to fetch';

  @override
  String deviceInfoFetchFailedWithError(String error) {
    return 'Failed to get device info: $error';
  }

  @override
  String get deviceInfoFetching => 'Fetching...';

  @override
  String get deviceInfoLabel => 'Device info';

  @override
  String get deviceLabel => 'Device';

  @override
  String get deviceModelLabel => 'Model';

  @override
  String get deviceNameLabel => 'Device name';

  @override
  String get deviceTypeLabel => 'Device type';

  @override
  String get distroNameLabel => 'Distribution';

  @override
  String get distroVersionLabel => 'Distribution version';

  @override
  String get downloadCompleted => 'Download completed';

  @override
  String get downloadError => 'Download error';

  @override
  String downloadErrorWithDetails(String error) {
    return 'An error occurred during download: $error';
  }

  @override
  String get downloadFailed => 'Download failed';

  @override
  String get downloadInBackground => 'Download in background';

  @override
  String get downloadInBrowser => 'Download in browser';

  @override
  String get downloadInProgress => 'Downloading';

  @override
  String get downloadLinkOpenedInBrowser => 'Download link opened in browser';

  @override
  String get downloadLinkUnavailable => 'Download link unavailable';

  @override
  String get downloadNow => 'Download now';

  @override
  String get downloadProgress => 'Download progress';

  @override
  String get downloadStarting => 'Starting download...';

  @override
  String get downloadWillContinueInBackground =>
      'Download will continue in the background';

  @override
  String get downloadingResult => 'Downloading result...';

  @override
  String get dragToReorderHint => 'Long press and drag to reorder';

  @override
  String get dragVideoHere => 'Drag videos here';

  @override
  String durationLabel(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get durationPackages => 'Duration packages';

  @override
  String get durationPlans => 'Duration plans';

  @override
  String durationSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String get durationShortenedLabel => 'Duration reduced';

  @override
  String get editBreadcrumb => 'Edit';

  @override
  String get editFeatureUnavailable => 'Editing is unavailable';

  @override
  String get editName => 'Edit name';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get editRound => 'Edit round';

  @override
  String get editToolAiClip => 'AI clip';

  @override
  String get editToolAudio => 'Audio';

  @override
  String get editToolClip => 'Clip';

  @override
  String get editToolPip => 'Picture-in-picture';

  @override
  String get editToolSticker => 'Stickers';

  @override
  String get editToolText => 'Text';

  @override
  String get editVideo => 'Edit video';

  @override
  String get email => 'Email';

  @override
  String get emailLoginOnlyNotice =>
      'Due to policy requirements, only email login is available for now. Contact us if you cannot sign in.';

  @override
  String get emailSupport => 'Email support';

  @override
  String get endDateLabel => 'End date';

  @override
  String get enterConfirmPassword => 'Confirm your password';

  @override
  String get enterConfirmPasswordRequired => 'Please confirm your password';

  @override
  String get enterDeveloperPasswordHint =>
      'Enter the developer password to enable developer mode';

  @override
  String get enterDeveloperPasswordTitle => 'Enter developer password';

  @override
  String get enterKeywordToStartSearch => 'Enter a keyword to start searching';

  @override
  String get enterName => 'Enter name';

  @override
  String get enterNewPassword => 'Enter new password';

  @override
  String get enterPhoneOrEmail => 'Enter phone or email';

  @override
  String get enterSearchKeyword => 'Enter a search keyword';

  @override
  String get enterVerificationCode => 'Enter verification code';

  @override
  String entityInfoDateAndItemCount(String date, int count) {
    return '$date $count items';
  }

  @override
  String get errorGalleryReadFailed =>
      'Failed to read the photo library. Retry or check album permissions.';

  @override
  String get errorImageLoadFailed =>
      'Failed to load image. It may be corrupted or unsupported on this device.';

  @override
  String get errorLoginExpired => 'Session expired. Please sign in again.';

  @override
  String get errorNetworkRetry =>
      'Network error. Check your connection and try again.';

  @override
  String get errorResourceNotFound =>
      'Resource not found or no longer available.';

  @override
  String get errorStorageFull =>
      'Insufficient storage or app data is not writable. Free up space and try again.';

  @override
  String get errorVideoNotSupported =>
      'This device cannot play this video. Try transcoding or compressing it first.';

  @override
  String estimatedRemainingTime(String duration) {
    return 'Estimated remaining time: $duration';
  }

  @override
  String estimatedRemainingTimeSeconds(int seconds) {
    return 'Estimated remaining time: $seconds s';
  }

  @override
  String get exceptionDetailsLabel => 'Details';

  @override
  String get existingVideoClip => 'Clip existing video';

  @override
  String get existingVideoClipDescription =>
      'Select local video files for automatic clipping and segment extraction';

  @override
  String get existingVideoClipMode => 'Existing video clip mode';

  @override
  String get existingVideoClipSubtitle => 'Clip local video files';

  @override
  String get exitFullscreen => 'Exit fullscreen';

  @override
  String get experimentalFeatureASubtitle => 'Experimental feature A';

  @override
  String get experimentalFeatureATitle => 'Experimental feature A';

  @override
  String get experimentalFeatureBSubtitle => 'Experimental feature B';

  @override
  String get experimentalFeatureBTitle => 'Experimental feature B';

  @override
  String get experimentalFeaturesSection => 'Experimental features';

  @override
  String get expired => 'Expired';

  @override
  String get exportComplete => 'Export complete';

  @override
  String get exportConfigTitle => '📤 Export settings';

  @override
  String get exportEncoding => 'Encoding...';

  @override
  String get exportFailedTitle => 'Export failed';

  @override
  String get exportFileNotGenerated => 'Export file was not generated';

  @override
  String get exportFormatMp4H264 => 'MP4 (H.264)';

  @override
  String get exportLogsSubtitle => 'Export app logs';

  @override
  String get exportLogsTitle => 'Export logs';

  @override
  String get exportPreparing => 'Preparing export...';

  @override
  String exportProgressPercent(String percent) {
    return 'Exporting... $percent%';
  }

  @override
  String get exportQualityMobileShare => 'Mobile sharing';

  @override
  String get exportQualityOriginal => 'Original';

  @override
  String get exportQualityOriginalMeta => 'Original resolution';

  @override
  String get exportQualityRecommended => 'Recommended';

  @override
  String get exportQualitySmallerSize => 'Smaller file';

  @override
  String get exportVideoTitle => 'Export video';

  @override
  String get exporting => 'Exporting...';

  @override
  String get extendMoreEditFeaturesHint => 'Extend more editing features here';

  @override
  String get faqClippingDuration => 'How long does clipping take?';

  @override
  String get faqClippingDurationAnswer =>
      'For a one-hour video, clipping usually takes about 10 minutes.';

  @override
  String get faqHowToSelectSport => 'How do I choose a sport type?';

  @override
  String get faqHowToSelectSportAnswer =>
      'On the clipping settings page, choose a sport such as badminton or table tennis. The system will clip intelligently based on the sport.';

  @override
  String get faqHowToUploadVideo => 'How do I upload a video?';

  @override
  String get faqHowToUploadVideoAnswer =>
      'On the home screen, tap \"Start clipping\" and select the video file to upload.';

  @override
  String get faqSupportedFormats => 'Which video formats are supported?';

  @override
  String get faqSupportedFormatsAnswer =>
      'Common formats such as MP4, AVI, MOV, and MKV are supported.';

  @override
  String get faqTitle => 'FAQ';

  @override
  String get fasterAndMoreAccurate => 'Faster & more accurate';

  @override
  String get favoriteCurrentRound => 'Favorite current round';

  @override
  String get favoriteRounds => 'Favorite rounds';

  @override
  String get favoriteSegment => 'Favorite segment';

  @override
  String get featureBatchProcessing => 'Batch processing';

  @override
  String get featureCloudAndLocalClip => 'Cloud and local clipping';

  @override
  String get featureInDevelopment => 'Feature in development...';

  @override
  String get featureInstantSegmentMarking => 'Instant segment marking';

  @override
  String get featureLiveRecording => 'Live recording';

  @override
  String get featureMultipleFormats => 'Multiple video formats supported';

  @override
  String get featureNotSupportedOnDesktop =>
      'This feature is not supported on desktop';

  @override
  String get featureOnSiteRecording => 'Ideal for on-site match recording';

  @override
  String get featureRecordAndClipEfficiency =>
      'Record and clip for higher efficiency';

  @override
  String get featureSmartSegmentDetection => 'Smart segment detection';

  @override
  String get feedback => 'Feedback';

  @override
  String get feedbackDescriptionHint =>
      'Please describe your issue or suggestion in detail...';

  @override
  String get feedbackSubmittedSuccessfully =>
      'Feedback submitted. Thank you for your suggestion!';

  @override
  String get feedbackTitleHint => 'Title (e.g. bug/suggestion)';

  @override
  String get female => 'Female';

  @override
  String get fetchingDownloadLink => 'Fetching download link...';

  @override
  String ffmpegConvertFailed(String output) {
    return 'FFmpeg conversion failed: $output';
  }

  @override
  String ffmpegExecuteException(String error) {
    return 'Execution error: $error';
  }

  @override
  String ffmpegExecuteFailed(String logs) {
    return 'Execution failed: $logs';
  }

  @override
  String ffmpegExitCode(String code) {
    return 'ffmpeg exited with code $code';
  }

  @override
  String get ffmpegNotInitialized => 'FFmpeg is not initialized';

  @override
  String get ffmpegOperationCancelled => 'FFmpeg operation cancelled';

  @override
  String get fileDeleted => 'File deleted';

  @override
  String get fileDetailsTitle => 'Details';

  @override
  String get fileDoesNotExist => 'File does not exist';

  @override
  String get taskResultUnavailable => 'Unable to view task result';

  @override
  String fileInfoAccessedAt(String time) {
    return 'Accessed: $time';
  }

  @override
  String fileInfoCachePath(String path) {
    return 'Cache path: $path';
  }

  @override
  String fileInfoCreatedAt(String time) {
    return 'Created: $time';
  }

  @override
  String fileInfoFileName(String name) {
    return 'File name: $name';
  }

  @override
  String get fileInfoLabel => 'File info:';

  @override
  String fileInfoModifiedAt(String time) {
    return 'Modified: $time';
  }

  @override
  String fileInfoSize(String size) {
    return 'Size: $size';
  }

  @override
  String get fileName => 'File name';

  @override
  String get fileNameAlreadyExists => 'File name already exists';

  @override
  String fileNameWithSegmentCount(String fileName, int count) {
    return '$fileName ($count segments)';
  }

  @override
  String fileSizeLabel(String size) {
    return 'Size: $size';
  }

  @override
  String filesSelectedCount(int count) {
    return '$count file(s) selected';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterConditions => 'Filters';

  @override
  String get filterLocal => 'Local';

  @override
  String get filterOptionsTitle => 'Filter options';

  @override
  String get filterProcessStatus => 'Process status';

  @override
  String get filterSportType => 'Sport type';

  @override
  String get flutterVersionLabel => 'Flutter version';

  @override
  String get folderAlreadyExists => 'Folder already exists';

  @override
  String get folderCreatedSuccess => 'Folder created';

  @override
  String get folderEmpty => 'This folder is empty';

  @override
  String get folderInfo => 'Folder info';

  @override
  String get folderNameHint => 'Enter folder name';

  @override
  String get formatLabel => 'Format';

  @override
  String foundFileCount(int count) {
    return 'Found $count file(s)';
  }

  @override
  String frameExtractionFailed(String output) {
    return 'Frame extraction failed: $output';
  }

  @override
  String frameOutOfRange(String maxFrames) {
    return 'Frame index out of range: 0-$maxFrames';
  }

  @override
  String get freeBadge => 'Free';

  @override
  String get fullDiskSearchTab => 'Search all';

  @override
  String get fullscreenPlayback => 'Fullscreen playback';

  @override
  String get galleryNotSupportedOnDesktop =>
      'Gallery access is not supported on desktop';

  @override
  String get galleryPermissionMessage =>
      'To select photos and videos, grant photo library access in Settings.';

  @override
  String get galleryPermissionRequired => 'Photo library access required';

  @override
  String get gender => 'Gender';

  @override
  String get general => 'General';

  @override
  String get generalPageSubtitle => 'Startup, storage, and privacy';

  @override
  String generateThumbnailFailed(String path, String error) {
    return 'Failed to generate thumbnail: $path: $error';
  }

  @override
  String get generatingFinalVideo => 'Generating final video...';

  @override
  String get generatingThumbnail => 'Generating thumbnail...';

  @override
  String getFolderInfoFailed(String error) {
    return 'Failed to get folder info: $error';
  }

  @override
  String get getMatchSegments => 'Extract match segments';

  @override
  String get getxVersionLabel => 'GetX version';

  @override
  String get goToFeature => 'Go to feature';

  @override
  String get goToSettings => 'Go to settings';

  @override
  String get hardwareLabel => 'Hardware';

  @override
  String get helpAndFeedback => 'Help & feedback';

  @override
  String get highlightClip => 'Highlight clip';

  @override
  String get highlightClipHelp =>
      'Automatically identify and keep highlight rallies';

  @override
  String get highlightClipTooltip =>
      'Auto-clip long highlight rallies in a game';

  @override
  String get homeBadmintonClip => 'Badminton editing';

  @override
  String get homeBadmintonClipDesc => 'Edit badminton match videos';

  @override
  String get homeCarouselAiClipSubtitle =>
      'Auto-clip highlights and remove rest/ball-pickup segments';

  @override
  String get homeCarouselAiClipTitle => 'AI match auto-editing';

  @override
  String get homeImageCompress => 'Image compression';

  @override
  String get homeImageCompressDesc => 'Compress image files';

  @override
  String get homeLoading => 'Loading...';

  @override
  String get homePageTitle => 'Home';

  @override
  String get homePingpongClip => 'Table tennis editing';

  @override
  String get homePingpongClipDesc => 'Edit table tennis match videos';

  @override
  String get homeStartClip => 'Start editing';

  @override
  String get homeToolsSection => 'Tools';

  @override
  String get homeVideoCategoryCompleted => 'Completed';

  @override
  String get homeVideoCategoryProcessing => 'Processing';

  @override
  String get homeVideoCategoryRaw => 'Raw';

  @override
  String get homeVideoCategoryUnknown => 'Unknown';

  @override
  String get homeVideoCompress => 'Video compression';

  @override
  String get homeVideoCompressDesc => 'Compress video files';

  @override
  String get homeVideoNoMoreRecords => 'No more records';

  @override
  String homeVideoProcessingProgress(int progress) {
    return 'Processing $progress%';
  }

  @override
  String get homeVideoSubtitleCompleted => 'Completed';

  @override
  String get homeVideoSubtitlePending => 'Pending | Raw file';

  @override
  String homeVideoSubtitleProcessing(String taskId) {
    return 'Processing | Task ID: $taskId';
  }

  @override
  String get homeVideoTitleEditing => 'Edit video';

  @override
  String homeVideoTitleProcessing(String taskId) {
    return 'Processing record #$taskId';
  }

  @override
  String get homeVideoTitleRaw => 'Raw video';

  @override
  String get homeVideoTitleUnknown => 'Unknown video';

  @override
  String get hostNameLabel => 'Host name';

  @override
  String imageCompressResultsTitle(int count) {
    return 'Compress results ($count)';
  }

  @override
  String get imageDetails => 'Image details';

  @override
  String get imageFileLabel => 'Image file';

  @override
  String get imageLabel => 'Image';

  @override
  String get infoCreatedAt => 'Created';

  @override
  String get infoFileCount => 'Files';

  @override
  String get infoFolderCount => 'Folders';

  @override
  String get infoModifiedAt => 'Modified';

  @override
  String get infoPath => 'Path';

  @override
  String get infoTotalItems => 'Total items';

  @override
  String infoUpdateFailed(String error) {
    return 'Failed to update profile: $error';
  }

  @override
  String get infoUpdatedSuccessfully => 'Profile updated successfully';

  @override
  String initFailedWithError(String error) {
    return 'Initialization failed: $error';
  }

  @override
  String get inputFileNameHint => 'Enter file name...';

  @override
  String get inputFileNameKeywordHint => 'Enter file name keyword...';

  @override
  String get inputKeywordHint => 'Enter keyword...';

  @override
  String get inputVideoLabel => 'Input video';

  @override
  String get installNow => 'Install now';

  @override
  String get installTime => 'Install date';

  @override
  String get intervalMustBePositive => 'Interval must be greater than 0';

  @override
  String get invalidIndex => 'Invalid index';

  @override
  String get issueTypeBug => 'Bug';

  @override
  String get issueTypeSuggestion => 'Suggestion';

  @override
  String itemCountUnit(int count) {
    return '$count';
  }

  @override
  String get itemTypeDirectory => 'directory';

  @override
  String get itemTypeFile => 'file';

  @override
  String get itemTypeItem => 'item';

  @override
  String get labelDuration => 'Duration';

  @override
  String get labelError => 'Error';

  @override
  String get labelSize => 'Size';

  @override
  String get labelType => 'Type';

  @override
  String get labelUnknown => 'Unknown';

  @override
  String get language => 'Language';

  @override
  String get languageChinese => '中文';

  @override
  String get languageDescription => 'Language for menus, buttons, and labels';

  @override
  String get languageEnglish => 'English';

  @override
  String get latestVersion => 'Latest version';

  @override
  String get leavePageProcessingNotification =>
      'You can leave this page. You\'ll be notified via messages when processing completes.';

  @override
  String get linkRequiresBrowserDownload =>
      'This link must be downloaded in a browser';

  @override
  String get loadAlbumFailed => 'Failed to load albums';

  @override
  String loadAlbumFailedWithError(String error) {
    return 'Failed to load albums: $error';
  }

  @override
  String loadChangelogFailed(String error) {
    return 'Failed to load changelog: $error';
  }

  @override
  String loadDemoVideoFailed(String error) {
    return 'Failed to load demo video: $error';
  }

  @override
  String loadFailed(String error) {
    return 'Failed to load: $error';
  }

  @override
  String get loadFailedShort => 'Failed to load';

  @override
  String loadLogFilesFailed(String error) {
    return 'Failed to load log files: $error';
  }

  @override
  String get loadMore => 'Load more...';

  @override
  String loadMoreFailedWithError(String error) {
    return 'Failed to load more: $error';
  }

  @override
  String loadSubscriptionFailed(String error) {
    return 'Failed to load subscription info: $error';
  }

  @override
  String loadUserInfoFailed(String error) {
    return 'Failed to load user info: $error';
  }

  @override
  String get loadVideoDataFailed => 'Failed to load video data';

  @override
  String loadVideoDetailFailed(String error) {
    return 'Failed to load video details: $error';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get loadingChangelog => 'Loading changelog...';

  @override
  String get localClip => 'Local clip';

  @override
  String localClipFailed(String error) {
    return 'Local video clipping failed: $error';
  }

  @override
  String get localClipTaskCreatedRedirecting =>
      'Local clip task created. Redirecting to tasks...';

  @override
  String get localDetecting => 'Running local detection…';

  @override
  String get localDetection => 'Local detection';

  @override
  String localDetectionFailed(String error) {
    return 'Local detection failed: $error';
  }

  @override
  String get localDetectionHelp => 'Works offline; no internet required';

  @override
  String localDetectionTaskName(String fileName) {
    return 'Local detection: $fileName';
  }

  @override
  String localDetectionTasksSubmitted(int count) {
    return 'Submitted $count local detection task(s). You can leave this page and check the task list.';
  }

  @override
  String get localModelNotFoundFallback =>
      'Local models not found; falling back to cloud detection';

  @override
  String get localOnnxDetectionHint =>
      'Uses local ONNX models for offline detection';

  @override
  String get localTasks => 'Local tasks';

  @override
  String get localVideoClip => 'Local video clip';

  @override
  String get localVideoStatusPending => 'Pending detection';

  @override
  String get localVideoStatusProcessing => 'Detecting';

  @override
  String get localizedModelLabel => 'Localized model';

  @override
  String get logFilesGeneratedAtRuntime =>
      'Log files are generated while the app is running';

  @override
  String get logLevelLabel => 'Log level:';

  @override
  String get logViewerTitle => 'Log viewer';

  @override
  String get loginAlreadyHaveAccount => 'Already have an account?';

  @override
  String get loginAuthCodeHint => 'Enter verification code';

  @override
  String get loginAuthCodeLabel => 'Verification code';

  @override
  String get loginAuthCodeMode => 'Verification code';

  @override
  String get loginAuthCodeSent => 'Verification code sent';

  @override
  String get loginAuthCodeSentCheck =>
      'Verification code sent. Please check your messages.';

  @override
  String get loginBackToLogin => 'Back to sign in';

  @override
  String get loginConfirmNewPassword => 'Confirm new password';

  @override
  String get loginConfirmNewPasswordHint => 'Confirm your new password';

  @override
  String loginFailed(String error) {
    return 'Sign in failed: $error';
  }

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginIdentifierHint => 'Enter your phone number or email';

  @override
  String get loginIdentifierLabel => 'Phone / email';

  @override
  String get loginIdentifierLabelOr => 'Phone or email';

  @override
  String get loginLoginNow => 'Sign in now';

  @override
  String get loginNeedLoginSubtitle =>
      'Please sign in to your account to continue';

  @override
  String get loginNeedLoginTitle => 'Sign in required';

  @override
  String get loginNewPassword => 'New password';

  @override
  String get loginNewPasswordHint => 'Enter new password';

  @override
  String get loginNoAccount => 'Don\'t have an account? ';

  @override
  String get loginPasswordHint => 'Enter your password';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordMismatch => 'Passwords do not match';

  @override
  String get loginPasswordMode => 'Password';

  @override
  String get loginPasswordTab => 'Account & password';

  @override
  String get loginRegisterAccount => 'Create account';

  @override
  String loginRegisterFailed(String error) {
    return 'Sign up failed: $error';
  }

  @override
  String get loginRegisterNow => 'Sign up now';

  @override
  String get loginRegisterSuccess => 'Account created successfully';

  @override
  String get loginRegisterTitle => 'Create account';

  @override
  String get loginRegistering => 'Signing up...';

  @override
  String get loginRememberPassword => 'Remember password';

  @override
  String get loginSocialLoginDivider => 'Or sign in with (coming soon)';

  @override
  String get loginSocialLoginUnavailable =>
      'This sign-in method is not available yet';

  @override
  String get loginRememberedPassword => 'Remember your password? ';

  @override
  String get loginRequiredForClipHistory => 'Sign in to view clip history';

  @override
  String loginResetPasswordFailed(String error) {
    return 'Password reset failed: $error';
  }

  @override
  String get loginResetPasswordSuccess => 'Password reset successfully';

  @override
  String get loginResetPasswordTitle => 'Reset password';

  @override
  String loginSendAuthCodeFailed(String error) {
    return 'Failed to send verification code: $error';
  }

  @override
  String loginSendFailed(String error) {
    return 'Send failed: $error';
  }

  @override
  String get loginSubtitle => 'Please sign in to your account';

  @override
  String get loginSuccess => 'Signed in successfully';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginValidationAuthCodeFormat =>
      'Enter a 4–6 digit verification code';

  @override
  String get loginValidationAuthCodeRequired =>
      'Please enter verification code';

  @override
  String get loginValidationIdentifierInvalid =>
      'Please enter a valid phone number or email';

  @override
  String get loginValidationIdentifierRequired =>
      'Please enter phone number or email';

  @override
  String get loginValidationPasswordMinLength =>
      'Password must be at least 8 characters';

  @override
  String get loginValidationPasswordRequired => 'Please enter password';

  @override
  String get loginWelcome => 'Welcome';

  @override
  String logoutFailed(String error) {
    return 'Failed to sign out: $error';
  }

  @override
  String get male => 'Male';

  @override
  String get manufacturerLabel => 'Manufacturer';

  @override
  String get markAllReadSuccess => 'All messages marked as read';

  @override
  String get markReadFailed => 'Failed to mark as read';

  @override
  String get matchType => 'Match type';

  @override
  String get matchTypeDoubles => 'Doubles match';

  @override
  String get matchTypeSingles => 'Singles match';

  @override
  String maxSelectionCountReached(int count) {
    return 'You can select at most $count file(s)';
  }

  @override
  String maxSelectionCountReachedFor(int count, String itemType) {
    return 'You can select at most $count $itemType';
  }

  @override
  String get maxServeDuration => 'Max serve duration';

  @override
  String get maxServeDurationTooltip => 'Limit serve duration (seconds)';

  @override
  String mediaItemCount(int count, String mediaType) {
    return '$count $mediaType';
  }

  @override
  String get mediaTypeAll => 'media';

  @override
  String get mediaTypeImage => 'images';

  @override
  String get mediaTypeVideo => 'videos';

  @override
  String get memorySizeLabel => 'Memory size';

  @override
  String get mergeAdjacentRounds => 'Merge adjacent rounds';

  @override
  String get mergeAdjacentRoundsHelp =>
      'Auto-merge rounds less than 3 seconds apart';

  @override
  String get mergeServeAndHit => 'Merge serve and hit';

  @override
  String get mergeServeAndHitTooltip =>
      'Include serve-only rallies (faults) and practice segments when enabled';

  @override
  String messageTimeLabel(String time) {
    return 'Time: $time';
  }

  @override
  String get messagesTitle => 'Messages';

  @override
  String get minDurationHint => 'Rounds shorter than this will not be kept';

  @override
  String get minHighlightDuration => 'Minimum highlight duration';

  @override
  String get minHighlightDurationSeconds => 'Min highlight duration (sec)';

  @override
  String get minHighlightDurationTooltip =>
      'Minimum highlight duration (seconds)';

  @override
  String get minRoundDuration => 'Min rally duration (sec)';

  @override
  String get minRoundDurationTooltip => 'Minimum rally duration (seconds)';

  @override
  String minutesDecimalValue(String value) {
    return '$value min';
  }

  @override
  String minutesValue(int minutes) {
    return '$minutes min';
  }

  @override
  String get mobileDevice => 'Mobile device';

  @override
  String modelNotFound(String modelName) {
    return 'Model not found: $modelName';
  }

  @override
  String get monthlyBilledLabel => '/ month, billed monthly';

  @override
  String get name => 'Name';

  @override
  String namedFeatureInDevelopment(String featureName) {
    return '$featureName is under development...';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navProfile => 'Profile';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navVideos => 'Videos';

  @override
  String get network => 'Network';

  @override
  String get networkDebugSubtitle => 'Debug network requests';

  @override
  String get networkDebugTitle => 'Network debug';

  @override
  String get networkPageSubtitle => 'API environment and downloads';

  @override
  String get newClip => 'New clip';

  @override
  String get newFileNameLabel => 'New file name';

  @override
  String get newFolder => 'New folder';

  @override
  String get newVersionFound => 'New version available';

  @override
  String get noAlbumsFound => 'No albums found';

  @override
  String get noChangelogEntries => 'No changelog entries';

  @override
  String get noCompletedTasks => 'No completed tasks';

  @override
  String get noFavoriteRounds => 'No favorite rounds';

  @override
  String get noItemsSelected => 'No items selected';

  @override
  String get noLogFilesFound => 'No log files found';

  @override
  String get noMatchingFiles => 'No matching files found';

  @override
  String noMatchingMediaFiles(String mediaType) {
    return 'No matching $mediaType files found';
  }

  @override
  String noMediaFiles(String mediaType) {
    return 'No $mediaType files found';
  }

  @override
  String get noMessages => 'No messages';

  @override
  String get noMoreData => 'No more data';

  @override
  String get noPlayableVideos => 'No playable videos';

  @override
  String get noPlayingRound => 'No round is currently playing';

  @override
  String get noProcessingRecords => 'No processing records';

  @override
  String get noRoundSegments => 'No round segments';

  @override
  String get noSegmentsToExport => 'No segments to export';

  @override
  String get noSegmentsToSave => 'No segments to save';

  @override
  String get noSegmentsYet => 'No segments yet';

  @override
  String get noTasks => 'No tasks';

  @override
  String get noValidSegments => 'No valid segments found';

  @override
  String get noVideo => 'No video';

  @override
  String get noVideoData => 'No video data';

  @override
  String get noVideoDataAvailable => 'No video data available';

  @override
  String get noVideos => 'No videos yet';

  @override
  String get notAvailable => 'N/A';

  @override
  String get notBound => 'Not linked';

  @override
  String get officialMatchPreset => 'Official match preset';

  @override
  String get officialWebsite => 'Official website';

  @override
  String openBrowserFailed(String error) {
    return 'Failed to open browser: $error';
  }

  @override
  String openCloudClipFailed(String error) {
    return 'Failed to enable cloud clipping: $error';
  }

  @override
  String get openEditFeatureFailed => 'Failed to open editing';

  @override
  String get openFile => 'Open file';

  @override
  String openFileFailed(String error) {
    return 'Failed to open file: $error';
  }

  @override
  String get openFolder => 'Open folder';

  @override
  String openFolderFailed(String error) {
    return 'Failed to open folder: $error';
  }

  @override
  String get openThisFolder => 'Open this folder';

  @override
  String get operationCancelled => 'Operation cancelled';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String operationFailedWithError(String error) {
    return 'Operation failed: $error';
  }

  @override
  String get orLabel => 'or';

  @override
  String get originalSize => 'Original size';

  @override
  String get outputQualityLabel => 'Output quality';

  @override
  String get outputVideoLabel => 'Output video';

  @override
  String packageDurationValidity(int minutes, String validity) {
    return '$minutes min · valid for $validity';
  }

  @override
  String get pageLoadFailed => 'Failed to load page';

  @override
  String passwordChangeFailed(String error) {
    return 'Failed to change password: $error';
  }

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get passwordSettings => 'Password settings';

  @override
  String get pathCopiedToClipboard => 'Path copied to clipboard';

  @override
  String pathNotFound(String path) {
    return 'Path not found: $path';
  }

  @override
  String get pauseTask => 'Pause task';

  @override
  String get pendingLogsTitle => 'Pending logs';

  @override
  String pendingLogsWithCount(int count) {
    return 'Pending logs ($count entries)';
  }

  @override
  String get performanceMonitorSubtitle => 'Monitor app performance';

  @override
  String get performanceMonitorTitle => 'Performance monitor';

  @override
  String get personalCenter => 'Personal center';

  @override
  String get permanent => 'Permanent';

  @override
  String get permissionCheckTitle => 'Permission check';

  @override
  String permissionChecking(String permissionName) {
    return 'Checking: $permissionName';
  }

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String permissionDeniedRetry(String permissionName) {
    return '$permissionName was denied. Please try again.';
  }

  @override
  String get permissionDescriptionBody =>
      'The app needs the following permissions to work properly. If a permission is denied, related features may not work.';

  @override
  String get permissionDescriptionTitle => 'About permissions';

  @override
  String get permissionDetailAudio => 'Plays video and audio content.';

  @override
  String get permissionDetailCamera =>
      'Records new video content, including photo and video capture.';

  @override
  String get permissionDetailDefault => 'Required for app functionality.';

  @override
  String get permissionDetailMicrophone =>
      'Captures audio while recording videos.';

  @override
  String get permissionDetailNotification =>
      'Shows progress notifications while processing videos in the background.';

  @override
  String get permissionDetailPhotos =>
      'Accesses photos and videos in your library for editing.';

  @override
  String get permissionDetailStorage =>
      'Saves edited videos to device storage and reads existing videos.';

  @override
  String get permissionDetailVideos =>
      'Accesses video files on device storage in various formats.';

  @override
  String permissionDiagnosticDenied(int count) {
    return '  Denied: $count';
  }

  @override
  String get permissionDiagnosticDetailStatus => 'Detailed status:';

  @override
  String permissionDiagnosticFetchFailed(String error) {
    return 'Failed to load diagnostics: $error';
  }

  @override
  String permissionDiagnosticGranted(int count) {
    return '  Granted: $count';
  }

  @override
  String permissionDiagnosticGrantedRate(String percent) {
    return '  Grant rate: $percent%';
  }

  @override
  String permissionDiagnosticPermanentlyDenied(int count) {
    return '  Permanently denied: $count';
  }

  @override
  String get permissionDiagnosticStats => 'Permission summary:';

  @override
  String permissionDiagnosticTime(String timestamp) {
    return 'Diagnosed at: $timestamp';
  }

  @override
  String get permissionDiagnosticTitle => 'Permission diagnostics';

  @override
  String permissionDiagnosticTotal(int count) {
    return '  Total: $count';
  }

  @override
  String get permissionExplanation =>
      'This permission is required for the app to work properly. Tap \"Allow\" in the system dialog.';

  @override
  String permissionGrantedSuccess(String permissionName) {
    return '$permissionName granted successfully';
  }

  @override
  String get permissionManagement => 'Permission management';

  @override
  String get permissionNameAudio => 'Audio';

  @override
  String get permissionNameCamera => 'Camera';

  @override
  String get permissionNameMicrophone => 'Microphone';

  @override
  String get permissionNameNotification => 'Notifications';

  @override
  String get permissionNamePhotos => 'Photos';

  @override
  String get permissionNameStorage => 'Storage';

  @override
  String get permissionNameUnknown => 'Unknown permission';

  @override
  String get permissionNameVideos => 'Videos';

  @override
  String permissionPermanentlyDenied(String permissionName) {
    return '$permissionName was permanently denied. Please enable it manually in Settings.';
  }

  @override
  String get permissionStatusDenied => 'Denied';

  @override
  String get permissionStatusGranted => 'Granted';

  @override
  String get permissionStatusLimited => 'Limited';

  @override
  String permissionStatusMessage(String permissionName, String status) {
    return '$permissionName status: $status';
  }

  @override
  String get permissionStatusPermanentlyDenied => 'Permanently denied';

  @override
  String get permissionStatusRestricted => 'Restricted';

  @override
  String get permissionStatusUnknown => 'Unknown';

  @override
  String get permissionSuggestionDenied =>
      'Tap \"Request permission\" to try again.';

  @override
  String get permissionSuggestionLimited =>
      'Partially granted; some features may be limited.';

  @override
  String get permissionSuggestionPermanentlyDenied =>
      'Enable manually in system settings.';

  @override
  String get permissionSuggestionRestricted =>
      'Permission is restricted by the system. Contact your administrator.';

  @override
  String get permissionTestSubtitle => 'Test app permissions';

  @override
  String get permissionTestTitle => 'Permission test';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get phoneStorageTab => 'Phone storage';

  @override
  String get pickFromGallery => 'Choose from gallery';

  @override
  String pickImageFailed(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String get pingPongAutoClipSubtitle =>
      'Automatic table tennis match video clipping';

  @override
  String get pingPongMatchVideoClip => 'Table tennis match video clipping';

  @override
  String get pingPongVideoAutoClip => 'Table tennis auto clip';

  @override
  String get platformLabel => 'Platform';

  @override
  String playSegmentFailedWithError(String error) {
    return 'Failed to play segment: $error';
  }

  @override
  String get playSelectedSegmentOnly => 'Play segment only';

  @override
  String get playSpeed => 'Playback speed';

  @override
  String get playVideo => 'Play video';

  @override
  String get playbackItemNotFound => 'Playback item not found';

  @override
  String get playingNow => '▶ Playing';

  @override
  String get pleaseEnterDescription => 'Please enter a detailed description';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get pleaseSelectGender => 'Please select gender';

  @override
  String get points => 'Points';

  @override
  String get popular => 'Popular';

  @override
  String get precisionEditButton => '✎ Precision edit';

  @override
  String get precisionEditTitle => 'Precision edit';

  @override
  String get prepareDownload => 'Preparing download';

  @override
  String prepareVideoFailed(String error) {
    return 'Failed to prepare video: $error';
  }

  @override
  String get presetComingSoon => 'Preset feature coming soon';

  @override
  String get previewTitle => 'Preview';

  @override
  String processDetectionResultFailed(String error) {
    return 'Failed to process detection result: $error';
  }

  @override
  String get processFailedRetry => 'Processing failed. Please try again.';

  @override
  String get processStatusPreparing => 'Preparing';

  @override
  String get processVideoFailed => 'Failed to process video';

  @override
  String processedTimeLabel(int seconds) {
    return 'Processed time: $seconds s';
  }

  @override
  String get processingEffectLabel => 'Processing result';

  @override
  String get processingHistory => 'Processing history';

  @override
  String get processingNow => 'Processing now';

  @override
  String processingSpeed(String speed) {
    return 'Processing speed: $speed sec/min';
  }

  @override
  String processingSpeedPerSecond(String speed) {
    return 'Processing speed: $speed s/s';
  }

  @override
  String get productNameLabel => 'Product name';

  @override
  String get profileDefaultUsername => 'Username';

  @override
  String progressPercentLabel(String percent) {
    return 'Progress: $percent%';
  }

  @override
  String get progressTaskCancelled => 'Task cancelled';

  @override
  String get progressTaskCompleted => 'Task completed';

  @override
  String get purchase => 'Purchase';

  @override
  String get purchaseConfirm => 'Confirm purchase';

  @override
  String purchaseConfirmMessage(String packageName, int minutes, String price) {
    return 'Purchase $packageName?\nDuration: $minutes min\nPrice: ¥$price';
  }

  @override
  String get purchaseFeatureInDevelopment =>
      'Purchase feature is under development...';

  @override
  String get qualityLabel => 'Quality';

  @override
  String queuePosition(String position) {
    return 'Queue position: $position';
  }

  @override
  String get quickAccessCamera => 'Camera';

  @override
  String get quickAccessDocuments => 'Documents';

  @override
  String get quickAccessDownload => 'Downloads';

  @override
  String get quickAccessPictures => 'Pictures';

  @override
  String get quickAccessVideos => 'Videos';

  @override
  String get quickTry => 'Quick try';

  @override
  String get quickTryHint =>
      'No video needed — try the clipping flow with built-in samples';

  @override
  String readLogContentFailed(String error) {
    return 'Failed to read log content: $error';
  }

  @override
  String get realtimeDetecting => 'Detecting in real time';

  @override
  String get recommended => 'Recommended';

  @override
  String get recordAndClip => 'Record & clip';

  @override
  String get recordAndClipCloud => 'Record & clip (cloud)';

  @override
  String get recordAndClipDescription =>
      'Record with the camera while marking and clipping segments in real time';

  @override
  String get recordAndClipLocal => 'Record & clip (local)';

  @override
  String get recordAndClipMode => 'Record & clip mode';

  @override
  String get recordAndClipRealtimeDetection =>
      'Record & clip real-time detection';

  @override
  String get recordAndClipSubtitle => 'Record and clip video in real time';

  @override
  String get recordDetailTitle => 'Record details';

  @override
  String get refreshStatus => 'Refresh status';

  @override
  String get registryOwnerLabel => 'Registry owner';

  @override
  String get remainingDuration => 'Remaining time';

  @override
  String remark(String info) {
    return 'Remark: $info';
  }

  @override
  String get remarkInfoSection => 'Remarks';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get removeReplay => 'Remove replays';

  @override
  String get removeReplayHelp => 'Automatically skip replay segments';

  @override
  String get removeReplayTooltipPro =>
      'Usually only in pro matches, e.g. WTT replays';

  @override
  String get removeReplayTooltipShort => 'Usually only in pro matches';

  @override
  String get renameFileTitle => 'Rename file';

  @override
  String get renameSucceeded => 'Renamed successfully';

  @override
  String get renew => 'Renew';

  @override
  String reorderFailedWithError(String error) {
    return 'Failed to reorder: $error';
  }

  @override
  String get reprocessButton => 'Reprocess';

  @override
  String get requestAllPermissions => 'Request all permissions';

  @override
  String get requestPermission => 'Request permission';

  @override
  String requestPermissionError(String error) {
    return 'Error requesting permission: $error';
  }

  @override
  String requestPermissionTitle(String permissionName) {
    return 'Request $permissionName';
  }

  @override
  String get reserveAfterRound => 'Post-round buffer (sec)';

  @override
  String get reserveAfterRoundTooltip =>
      'Seconds to keep after each rally ends';

  @override
  String get reserveBeforeRound => 'Pre-round buffer';

  @override
  String get reserveBeforeRoundTooltip =>
      'Seconds to keep before each rally starts';

  @override
  String get resetAppConfirmMessage =>
      'This will clear all app data, including settings, cache, and user data. This action cannot be undone.';

  @override
  String get resetAppSubtitle => 'Clear all app data';

  @override
  String get resetAppTitle => 'Reset app';

  @override
  String get resumeTask => 'Resume task';

  @override
  String retryFailed(String error) {
    return 'Retry failed: $error';
  }

  @override
  String get returnToHome => 'Return to home';

  @override
  String get roundClip => 'Round clip';

  @override
  String roundCountBadge(int count) {
    return '$count';
  }

  @override
  String roundCountDurationSummary(int count, String duration) {
    return '$count rounds · $duration total';
  }

  @override
  String get roundCountLabel => 'Rounds';

  @override
  String roundCountShort(int count) {
    return '$count rounds';
  }

  @override
  String get roundCountUnit => 'rounds';

  @override
  String get roundDeletedSuccess => 'Deleted current round';

  @override
  String get roundFavoritedSuccess => 'Favorited current round';

  @override
  String get roundList => 'Round list';

  @override
  String get roundOrder => 'Round order';

  @override
  String get roundTransitionLabel => 'Between-round transition';

  @override
  String get roundUnfavoritedSuccess => 'Unfavorited current round';

  @override
  String get saveAll => 'Save all';

  @override
  String get saveAsPreset => 'Save current as preset';

  @override
  String get saveCleaningTempFiles => 'Cleaning up temporary files...';

  @override
  String get saveComplete => 'Save complete!';

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get saveFailedShort => 'Save failed';

  @override
  String get saveLocationLabel => 'Save location:';

  @override
  String get saveMergingSegments => 'Merging video segments...';

  @override
  String get savePreparing => 'Preparing to save...';

  @override
  String get savePreparingInProgress => 'Preparing save...';

  @override
  String get saveProcessingSegmentsStart => 'Processing video segments...';

  @override
  String get saveProgressTitle => 'Save progress';

  @override
  String get saveSavingMetadata => 'Saving metadata...';

  @override
  String get saveSavingToGallery => 'Saving to gallery...';

  @override
  String saveSegmentFailedWithError(String error) {
    return 'Failed to save segments: $error';
  }

  @override
  String get saveToGallery => 'Save to gallery';

  @override
  String get saveToLabel => 'Save to';

  @override
  String get saveTrimmingSegment => 'Trimming segment...';

  @override
  String get saveTrimmingSegments => 'Trimming video segments...';

  @override
  String saveTrimmingSegmentsProgress(String percent) {
    return 'Trimming video segments... $percent%';
  }

  @override
  String savedImagesCount(int count) {
    return 'Saved $count image(s) to gallery';
  }

  @override
  String get savedToGallery => 'Saved to gallery';

  @override
  String screenshotCaptureFailedWithLogs(String logs) {
    return 'Screenshot failed: $logs';
  }

  @override
  String get screenshotCapturing => 'Capturing screenshot...';

  @override
  String get screenshotCompleted => 'Screenshot complete';

  @override
  String get screenshotFailedTitle => 'Screenshot failed';

  @override
  String get screenshotFileNotGenerated => 'Screenshot file was not generated';

  @override
  String get screenshotGeneratingImage => 'Generating image...';

  @override
  String get screenshotPrepare => 'Preparing screenshot...';

  @override
  String get screenshotProgressTitle => 'Screenshot progress';

  @override
  String get screenshotSavingToGallery => 'Saving to gallery...';

  @override
  String get sdkVersionLabel => 'SDK version';

  @override
  String searchFailedWithError(String error) {
    return 'Search failed: $error';
  }

  @override
  String get searchFilesTitle => 'Search files';

  @override
  String get searchLogsHint => 'Search logs...';

  @override
  String get searchMediaTitle => 'Search media';

  @override
  String get searchPathDcim => 'DCIM / Camera';

  @override
  String get searchPathDocuments => 'Documents folder';

  @override
  String get searchPathDownload => 'Downloads folder';

  @override
  String get searchPathEntireStorage => 'Entire storage';

  @override
  String get searchPathMovies => 'Movies folder';

  @override
  String get searchPathMusic => 'Music folder';

  @override
  String get searchPathPictures => 'Pictures folder';

  @override
  String searchResultsAdded(int count) {
    return 'Added $count search result(s) to selection';
  }

  @override
  String get searchScope => 'Search scope';

  @override
  String get searching => 'Searching...';

  @override
  String get searchingFiles => 'Searching files...';

  @override
  String get securitySettings => 'Security settings';

  @override
  String get seekBackward1s => '-1s';

  @override
  String get seekBackward5s => '-5s';

  @override
  String get seekForward1s => '+1s';

  @override
  String get seekForward5s => '+5s';

  @override
  String get segmentNotFound => 'Segment not found';

  @override
  String segmentsDetectedResult(int count, int seconds) {
    return 'Detected $count match segment(s) (${seconds}s)';
  }

  @override
  String get selectAlbum => 'Select album';

  @override
  String get selectAll => 'Select all';

  @override
  String get selectClipMode => 'Select clipping method';

  @override
  String get selectClipModeHint => 'Choose how you want to clip your video';

  @override
  String get selectDirectoryPrompt => 'Please select a directory';

  @override
  String get selectDirectoryTitle => 'Select directory';

  @override
  String get selectExportQualityTitle => 'Select export quality';

  @override
  String get selectFiles => 'Select files';

  @override
  String get selectFilesAndDirectoriesTitle => 'Select files and directories';

  @override
  String get selectFilesOrDirectoriesPrompt =>
      'Please select file(s) or directory';

  @override
  String get selectFilesPrompt => 'Please select file(s)';

  @override
  String get selectFilesTitle => 'Select files';

  @override
  String get selectGender => 'Select gender';

  @override
  String get selectImagesTitle => 'Select images';

  @override
  String get selectMediaTitle => 'Select media';

  @override
  String get selectRoundFromLeft => 'Select a round from the left';

  @override
  String get selectSportType => 'Select sport type';

  @override
  String get selectSportTypeHint =>
      'Select the sport type of the video you want to clip';

  @override
  String get selectThisDirectory => 'Select this directory';

  @override
  String get selectTimeRange => 'Select time range';

  @override
  String get selectVideoFileFirst => 'Please select a video file first';

  @override
  String get selectVideoFileFirstError => 'Please select a video file first';

  @override
  String get selectVideosTitle => 'Select videos';

  @override
  String selectedCountShort(int count) {
    return 'Selected: $count';
  }

  @override
  String selectedFirstNItems(int count) {
    return 'Selected first $count item(s)';
  }

  @override
  String selectedItemsCount(int count) {
    return '$count selected';
  }

  @override
  String get selectedRounds => 'Selected rounds';

  @override
  String selectionSummaryDirsOnly(String dirCount) {
    return ' ($dirCount dirs)';
  }

  @override
  String selectionSummaryFilesAndDirs(String fileCount, String dirCount) {
    return ' ($fileCount files, $dirCount dirs)';
  }

  @override
  String selectionSummaryFilesOnly(String fileCount) {
    return ' ($fileCount files)';
  }

  @override
  String selectionSummaryItems(int count) {
    return '$count items';
  }

  @override
  String get settings => 'Settings';

  @override
  String get settingsAllDownloadFiles => 'All downloaded files';

  @override
  String get settingsAllFilesCleanupDone => 'All files cleaned';

  @override
  String settingsAllFilesCleanupFailed(String error) {
    return 'Failed to clean all files: $error';
  }

  @override
  String get settingsAlreadyLatestVersion => 'You\'re on the latest version';

  @override
  String get settingsApiServer => 'API server';

  @override
  String get settingsApiServerDefault => 'Default';

  @override
  String get settingsApiServerDesc =>
      'Choose the API environment to connect to';

  @override
  String get settingsApiServerSandbox => 'Sandbox';

  @override
  String get settingsAppData => 'App data';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsCacheCleanupDone => 'Cache cleaned';

  @override
  String settingsCacheCleanupFailed(String error) {
    return 'Failed to clean cache: $error';
  }

  @override
  String get settingsCacheFiles => 'Cache files';

  @override
  String get settingsCheckUpdate => 'Check for updates';

  @override
  String get settingsCheckUpdateOnStart => 'Check for updates on startup';

  @override
  String get settingsCheckUpdateOnStartDesc =>
      'Automatically check for new versions when the app launches';

  @override
  String get settingsChooseCleanupContent => 'Choose what to clean up:';

  @override
  String get settingsChooseLanguage => 'Choose language';

  @override
  String get settingsCleanupAll => 'Clean all';

  @override
  String get settingsClearAll => 'Clear all';

  @override
  String get settingsClearCache => 'Clear cache';

  @override
  String get settingsConfirmCleanup => 'Confirm cleanup';

  @override
  String get settingsConfirmCleanupAction => 'Clean up';

  @override
  String settingsConfirmCleanupMessage(String title) {
    return 'Clean up $title? This cannot be undone.';
  }

  @override
  String get settingsConfirmDeleteAction => 'Delete';

  @override
  String settingsConfirmDeleteFileMessage(String fileName) {
    return 'Delete file \"$fileName\"? This cannot be undone.';
  }

  @override
  String get settingsDarkMode => 'Dark mode';

  @override
  String get settingsDefaultSavePath => 'Default save path';

  @override
  String get settingsDefaultSavePathValue => '~/Videos/Huji';

  @override
  String get settingsDownloadCleanupDone => 'Downloads cleaned';

  @override
  String settingsDownloadCleanupFailed(String error) {
    return 'Failed to clean downloads: $error';
  }

  @override
  String get settingsDownloadConcurrency => 'Download concurrency';

  @override
  String get settingsDownloadConcurrencyDesc =>
      'Number of videos to download at once';

  @override
  String get settingsDownloadFileList => 'Downloaded files';

  @override
  String get settingsDownloadFiles => 'Downloaded files';

  @override
  String settingsDownloadListFailed(String error) {
    return 'Failed to load download list: $error';
  }

  @override
  String get settingsExternalStorage => 'External storage';

  @override
  String settingsFileDeleteFailed(String error) {
    return 'Failed to delete file: $error';
  }

  @override
  String get settingsFileDeleteSuccess => 'File deleted';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageUpdated => 'Language updated';

  @override
  String get settingsNoDownloadFiles => 'No downloaded files';

  @override
  String get settingsNotificationsUpdated => 'Notification settings updated';

  @override
  String get settingsPageSubtitle => 'Customize your Huji desktop experience';

  @override
  String get settingsPermissions => 'Permissions';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsPushNotifications => 'Push notifications';

  @override
  String get settingsSendUsageStats => 'Send usage statistics';

  @override
  String get settingsSendUsageStatsDesc =>
      'Send anonymous usage data to help improve the app';

  @override
  String get settingsStorage => 'Storage';

  @override
  String get settingsThemeChanged => 'Theme updated';

  @override
  String get settingsTitle => 'Settings';

  @override
  String settingsTotalUsedSpace(String size) {
    return 'Total used: $size';
  }

  @override
  String get settingsUserAgreement => 'Terms of service';

  @override
  String get settingsUsername => 'Username';

  @override
  String get settingsVersionInfo => 'Version info';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutBack => 'Back to About';

  @override
  String get settingsAppVersion => 'App version';

  @override
  String get settingsViewDeviceInfo => 'View device info';

  @override
  String get settingsViewChangelog => 'View changelog';

  @override
  String get settingsViewDownloadFiles => 'View downloaded files';

  @override
  String get setupLater => 'Set up later';

  @override
  String get shareFeatureInDevelopment =>
      'Share feature is under development...';

  @override
  String shareLogsFailed(String error) {
    return 'Failed to share logs: $error';
  }

  @override
  String get shortcutsCategoryEditing => 'Editing';

  @override
  String get shortcutsCategoryMeta => 'General';

  @override
  String get shortcutsCategoryNavigation => 'Navigation';

  @override
  String get shortcutsCategoryPlayback => 'Playback';

  @override
  String get shortcutsCategoryView => 'View';

  @override
  String get shortcutsChange => 'Change';

  @override
  String shortcutsCheatsheetSubtitle(String chord) {
    return 'Press $chord anytime to open this list';
  }

  @override
  String get shortcutsCommandCloseOrBack => 'Close / Back';

  @override
  String get shortcutsCommandNewClip => 'New Clip';

  @override
  String get shortcutsCommandOpenSettings => 'Open Settings';

  @override
  String get shortcutsCommandOpenTasks => 'Open Tasks';

  @override
  String get shortcutsCommandShowCheatsheet => 'Show Keyboard Shortcuts';

  @override
  String get shortcutsCommandToggleSidebar => 'Toggle Sidebar';

  @override
  String get shortcutsCommandPlaybackPlayPause => 'Play / Pause';

  @override
  String get shortcutsCommandPlaybackSeekBackward => 'Seek backward';

  @override
  String get shortcutsCommandPlaybackSeekForward => 'Seek forward';

  @override
  String get shortcutsCommandPlaybackPrevSegment => 'Previous segment';

  @override
  String get shortcutsCommandPlaybackNextSegment => 'Next segment';

  @override
  String get shortcutsCommandPrecisionPlayPause => 'Play / Pause';

  @override
  String get shortcutsCommandPrecisionSplit => 'Split at playhead';

  @override
  String get shortcutsCommandPrecisionAddSegment => 'Add segment';

  @override
  String get shortcutsCommandPrecisionDeleteSegment => 'Delete segment';

  @override
  String get shortcutsCommandPrecisionPlaySelectedOnly =>
      'Play selected segment only';

  @override
  String get shortcutsCommandPrecisionToggleSlowMotion => 'Toggle slow motion';

  @override
  String get shortcutsCommandPrecisionPrevRound => 'Previous round';

  @override
  String get shortcutsCommandPrecisionNextRound => 'Next round';

  @override
  String get shortcutsCommandPrecisionSeekBackward =>
      'Seek backward 0.1s (hold to accelerate)';

  @override
  String get shortcutsCommandPrecisionSeekForward =>
      'Seek forward 0.1s (hold to accelerate)';

  @override
  String get shortcutsConflictTooltip => 'Conflicts with another command';

  @override
  String get shortcutsExport => 'Export';

  @override
  String get shortcutsExportFailed => 'Failed to export shortcuts';

  @override
  String get shortcutsExportSuccess => 'Shortcuts exported';

  @override
  String get shortcutsImport => 'Import';

  @override
  String shortcutsImportConflictMessage(int count) {
    return '$count imported bindings conflict with existing commands. Replace them?';
  }

  @override
  String get shortcutsImportConflictTitle => 'Conflicts detected';

  @override
  String get shortcutsImportInvalidFile => 'Not a valid shortcuts file';

  @override
  String get shortcutsImportSuccess => 'Shortcuts imported';

  @override
  String get shortcutsNotSet => 'Not set';

  @override
  String get shortcutsPressNewChord => 'Press a new key combination';

  @override
  String get shortcutsPressNewChordHint => 'Esc to cancel · Backspace to clear';

  @override
  String get shortcutsRebind => 'Change shortcut';

  @override
  String get shortcutsReplaceAction => 'Replace all';

  @override
  String get shortcutsReplaceCancel => 'Keep current';

  @override
  String shortcutsReplaceConfirmBody(String chord, String command) {
    return '$chord is already used by \"$command\". Replace it?';
  }

  @override
  String get shortcutsReplaceConfirmTitle => 'Replace shortcut?';

  @override
  String get shortcutsReplaceProceed => 'Replace';

  @override
  String get shortcutsReset => 'Reset to default';

  @override
  String get shortcutsResetAll => 'Restore all defaults';

  @override
  String get shortcutsResetAllConfirmBody =>
      'All customized shortcuts will be restored to their defaults.';

  @override
  String get shortcutsResetAllConfirmTitle => 'Restore all defaults?';

  @override
  String get shortcutsSearchHint => 'Search shortcuts';

  @override
  String get shortcutsSectionSubtitle =>
      'View and customize keyboard shortcuts';

  @override
  String get shortcutsSectionTitle => 'Keyboard Shortcuts';

  @override
  String get shortcutsUnbind => 'Unbind';

  @override
  String get shortcutsViewCheatsheet => 'View all shortcuts';

  @override
  String get showSystemLogsLabel => 'Show system logs';

  @override
  String get sizeReducedLabel => 'Size reduced';

  @override
  String get slowMotion => 'Slow motion';

  @override
  String softwareEncoderDetectFailed(String error) {
    return 'Software encoder detection failed: $error';
  }

  @override
  String get softwareEncoderNotFound => 'No suitable software encoder found';

  @override
  String get sortByFileSize => 'File size';

  @override
  String get sortByFileType => 'File type';

  @override
  String get sortByModifiedTime => 'Modified time';

  @override
  String get sortByName => 'Name';

  @override
  String get sortOptionsTitle => 'Sort by';

  @override
  String get sourceLocal => 'Local';

  @override
  String get sourceNetwork => 'Network';

  @override
  String get splashInitializing => 'Initializing...';

  @override
  String get splashTagline => 'Table tennis & badminton match video editing';

  @override
  String get sportBadminton => 'Badminton';

  @override
  String get sportClipDescription =>
      'Supports singles and doubles; automatically identifies highlight rallies';

  @override
  String get sportPingPong => 'Table tennis';

  @override
  String get sportTypeBadminton => 'Badminton';

  @override
  String get sportTypePingpong => 'Table tennis';

  @override
  String get startDateLabel => 'Start date';

  @override
  String get startDetectionClip => 'Start detection & clip';

  @override
  String get startDownload => 'Starting download...';

  @override
  String get startExport => 'Start export';

  @override
  String get startFrameMustBeLessThanEnd =>
      'Start frame must be less than end frame';

  @override
  String get startTimeCannotBeNegative => 'Start time cannot be negative';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusPreparing => 'Preparing';

  @override
  String get statusProcessing => 'Processing';

  @override
  String storageCategoryWithSize(String label, String size) {
    return '$label: $size';
  }

  @override
  String get storageInfoCalculating => 'Calculating storage info...';

  @override
  String storageInfoFetchFailedWithError(String error) {
    return 'Failed to get storage info: $error';
  }

  @override
  String get storagePermissionRequired =>
      'Storage permission is required to access files';

  @override
  String get submitFailedRetryLater =>
      'Submission failed. Please try again later.';

  @override
  String get submitFeedback => 'Submit feedback';

  @override
  String get subscribe => 'Subscribe';

  @override
  String get subscriptionConfirm => 'Confirm subscription';

  @override
  String subscriptionConfirmMessage(String planName, String price) {
    return 'Subscribe to the $planName plan?\nMonthly fee: ¥$price';
  }

  @override
  String subscriptionFailed(String error) {
    return 'Subscription failed: $error';
  }

  @override
  String get subscriptionPlans => 'Subscription plans';

  @override
  String subscriptionSuccess(String planName) {
    return 'Successfully subscribed to $planName!';
  }

  @override
  String get supportedVideoFormats => 'Common video formats supported';

  @override
  String get switchTabClearSelectionMessage =>
      'Switching tabs will clear your current selection. Continue?';

  @override
  String get switchTabTitle => 'Switch tab';

  @override
  String get switchToGridMode => 'Switch to grid view';

  @override
  String get switchToListMode => 'Switch to list view';

  @override
  String get systemInfoSubtitle => 'View detailed system information';

  @override
  String get systemInfoTitle => 'System info';

  @override
  String get systemNameLabel => 'System name';

  @override
  String get systemVersionLabel => 'System version';

  @override
  String get tabFiles => 'Files';

  @override
  String get tabPhotoGallery => 'Gallery';

  @override
  String get takePhoto => 'Take photo';

  @override
  String taskCancelled(String taskName) {
    return 'Cancelled task \"$taskName\"';
  }

  @override
  String taskDeleted(String taskName) {
    return 'Deleted task \"$taskName\"';
  }

  @override
  String taskPauseNotSupported(String taskType) {
    return '$taskType tasks cannot be paused';
  }

  @override
  String taskPauseNotSupportedWithCancel(String taskType) {
    return '$taskType tasks cannot be paused; use Cancel instead';
  }

  @override
  String taskPaused(String taskName) {
    return 'Paused task \"$taskName\"';
  }

  @override
  String get taskPhaseAnalyzing => 'Analyzing video…';

  @override
  String get taskPhaseClipping => 'Clipping video…';

  @override
  String get taskPhaseDownloading => 'Downloading results…';

  @override
  String get taskPhaseFailed => 'Processing failed';

  @override
  String get taskPhaseGenerating => 'Generating final video…';

  @override
  String get taskPhasePaused => 'Paused';

  @override
  String get taskPhasePending => 'Task submitted, waiting…';

  @override
  String get taskPhaseProcessing => 'Processing…';

  @override
  String get taskPhaseUploading => 'Uploading video…';

  @override
  String get taskRecords => 'Task records';

  @override
  String taskResumed(String taskName) {
    return 'Resumed task \"$taskName\"';
  }

  @override
  String get taskStatusCancelled => 'Cancelled';

  @override
  String get taskStatusCancelledShort => 'Cancelled';

  @override
  String get taskStatusCompleted => 'Completed';

  @override
  String get taskStatusFailed => 'Failed';

  @override
  String get taskStatusFilter => 'Task status';

  @override
  String get taskStatusInProgress => 'In progress';

  @override
  String get taskStatusPaused => 'Paused';

  @override
  String get taskStatusPending => 'Pending';

  @override
  String get taskStatusProcessing => 'Processing';

  @override
  String get taskSubmittedWaiting => 'Task submitted, waiting to start...';

  @override
  String get taskTypeDownload => 'File download';

  @override
  String get taskTypeFilter => 'Task type';

  @override
  String taskTypeFilterSelected(int count) {
    return 'Task type · $count';
  }

  @override
  String get taskTypeImageCompress => 'Image compress';

  @override
  String get taskTypeSegmentDetectShort => 'Real-time detect';

  @override
  String get taskTypeVideoClip => 'Video clip';

  @override
  String get taskTypeVideoCompress => 'Video compress';

  @override
  String get taskTypeVideoSegmentDetect => 'Real-time video segment detection';

  @override
  String get taskTypeVideoUpload => 'Video upload';

  @override
  String tasksSubmitted(int successCount, String failSuffix) {
    return 'Submitted $successCount task(s)$failSuffix';
  }

  @override
  String tasksSubmittedFailSuffix(int failCount) {
    return ', $failCount failed';
  }

  @override
  String get testEnvironmentSubtitle => 'Test environment';

  @override
  String get testPageAccessSubtitle => 'Open test page';

  @override
  String get testPageForFeaturesSubtitle => 'For testing various features';

  @override
  String get testPageTitle => 'Test page';

  @override
  String get themeColorPresetDescription =>
      'Primary and accent colors for controls';

  @override
  String get themeColorPresetTitle => 'Theme colors';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeModeDescription => 'Default appearance or follow the system';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeTitle => 'Theme mode';

  @override
  String get themePresetAmber => 'Amber';

  @override
  String get themePresetForest => 'Forest';

  @override
  String get themePresetGraphite => 'Graphite';

  @override
  String get themePresetOcean => 'Ocean';

  @override
  String get themePresetViolet => 'Violet';

  @override
  String get themeSystem => 'System';

  @override
  String thumbnailFileNotGenerated(String path) {
    return 'Thumbnail file was not generated: $path';
  }

  @override
  String thumbnailGenerateFailed(String path, String error) {
    return 'Failed to generate thumbnail: $path: $error';
  }

  @override
  String thumbnailGenerationFailed(String detail) {
    return 'Failed to generate thumbnail: $detail';
  }

  @override
  String get timeRangeFilter => 'Time range';

  @override
  String get totalDurationLabel => 'Total duration';

  @override
  String get totalUsage => 'Total used';

  @override
  String get trainingPreset => 'Training match preset';

  @override
  String get transitionCrossfade => 'Crossfade';

  @override
  String get transitionNone => 'None (concatenate)';

  @override
  String get transitionSlide => 'Slide';

  @override
  String get trimSplitLabel => 'Split';

  @override
  String get tryModifySearchConditions => 'Try changing your search';

  @override
  String get typographyScaleComfortable => 'Comfortable';

  @override
  String get typographyScaleCompact => 'Compact';

  @override
  String get typographyScaleCustom => 'Custom';

  @override
  String get typographyScaleCustomHint => '50–200';

  @override
  String get typographyScaleDescription =>
      'UI text size. Standard follows the system';

  @override
  String get typographyScaleStandard => 'Standard';

  @override
  String get typographyScaleTitle => 'Text size';

  @override
  String get uiZoomDescription => 'Scale text, icons, and spacing together';

  @override
  String get uiZoomTitle => 'Interface zoom';

  @override
  String get unfavorite => 'Remove from favorites';

  @override
  String get unfavoriteCurrentRound => 'Unfavorite current round';

  @override
  String get unknownDevice => 'Unknown device';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get unknownFile => 'Unknown file';

  @override
  String get unknownLabel => 'Unknown';

  @override
  String get unknownPlatform => 'Unknown platform';

  @override
  String get unlimited => 'Unlimited';

  @override
  String get untitledName => 'Untitled';

  @override
  String get updateContent => 'What\'s new';

  @override
  String get updateLater => 'Update later';

  @override
  String updatePlaybackListFailedWithError(String error) {
    return 'Failed to update playback list: $error';
  }

  @override
  String get updateTime => 'Update date';

  @override
  String get uploadVideoHint =>
      'Upload your match videos to automatically trim rest periods. You can leave this page while processing; you\'ll get a desktop notification when done.';

  @override
  String get uploading => 'Uploading...';

  @override
  String get uploadingVideo => 'Uploading video...';

  @override
  String get useDemoVideo => 'Or use a demo video';

  @override
  String get used => 'Used';

  @override
  String get usedDuration => 'Used';

  @override
  String get userNameLabel => 'User name';

  @override
  String get usernameLabel => 'Username';

  @override
  String validityDays(int days) {
    return '$days days';
  }

  @override
  String get versionCodenameLabel => 'Version codename';

  @override
  String get versionIdLabel => 'Version ID';

  @override
  String get versionInfo => 'Version info';

  @override
  String get versionNumber => 'Version';

  @override
  String get videoClipProgressTitle => 'Video clip progress';

  @override
  String get videoComparisonSection => 'Video comparison';

  @override
  String videoCompressException(String error) {
    return 'Compression error: $error';
  }

  @override
  String videoCompressFailed(String logs) {
    return 'Compression failed: $logs';
  }

  @override
  String get videoCompressInfoUnavailable => 'Unable to get video information';

  @override
  String videoCompressInputNotFound(String path) {
    return 'Input file not found: $path';
  }

  @override
  String get videoCompressOutputNotGenerated => 'Output file was not generated';

  @override
  String get videoCropFailed => 'Video crop failed';

  @override
  String videoDuration(String duration) {
    return 'Video duration: $duration';
  }

  @override
  String videoDurationAndSize(String duration, String size) {
    return 'Duration: $duration | Size: $size';
  }

  @override
  String videoDurationSeconds(int seconds) {
    return 'Video duration: $seconds s';
  }

  @override
  String get videoEditTitle => 'Video editing';

  @override
  String videoExpiresAt(String date, String timeAgo) {
    return '$date | expires $timeAgo';
  }

  @override
  String get videoFileLabel => 'Video file';

  @override
  String get videoFileNotExist => 'Video file does not exist';

  @override
  String videoFileNotFound(String path) {
    return 'Video file not found: $path';
  }

  @override
  String videoFileNotFoundWithPath(String path) {
    return 'Video file does not exist: $path';
  }

  @override
  String get videoFileNotGenerated => 'Video file was not generated';

  @override
  String get videoFormatConvertFailed => 'Video format conversion failed';

  @override
  String videoInfoFetchFailed(String output) {
    return 'Failed to get video info: $output';
  }

  @override
  String get videoLabel => 'Video';

  @override
  String get videoListTitle => 'Video list';

  @override
  String get videoLoading => 'Loading video...';

  @override
  String get videoMergeFailed => 'Video merge failed';

  @override
  String get videoNameLabel => 'Video name';

  @override
  String get videoPathEmpty => 'Video file path is empty';

  @override
  String videoPlayerFileMovedOrDeleted(String path) {
    return 'The file was moved or deleted:\n$path';
  }

  @override
  String get videoPlayerFileNotFound => 'File not found';

  @override
  String videoPlayerInitFailed(String error) {
    return 'Failed to initialize player: $error';
  }

  @override
  String get videoPlayerInitializing => 'Initializing player...';

  @override
  String get videoPlayerLoadingVideo => 'Loading video...';

  @override
  String videoPlayerNetworkInitFailed(String error) {
    return 'Failed to initialize network player: $error';
  }

  @override
  String get videoProcessType => 'Video processing type';

  @override
  String get videoProcessTypeAllMatchMerged => 'All rallies';

  @override
  String get videoProcessTypeGreatMatch => 'Highlight rallies';

  @override
  String get videoProcessTypeRaw => 'Original video';

  @override
  String get videoProcessingComplete => 'Video processing complete';

  @override
  String get videoProcessingCompletedViewOutput =>
      'Processing complete. You can view the output video.';

  @override
  String get videoProcessingInProgress => 'Video is processing...';

  @override
  String get videoProcessingProgress => 'Video processing progress';

  @override
  String get videoQualityWarning =>
      'Camera angle, framing, and resolution affect detection quality. Shoot horizontally at ≥ 720p and avoid heavy compression.';

  @override
  String get videoSaveFailed => 'Failed to save video';

  @override
  String videoSavedTo(String path) {
    return 'Video saved to $path';
  }

  @override
  String get videoScaleFailed => 'Video scaling failed';

  @override
  String get videoSegmentDetection => 'Video segment detection';

  @override
  String get videoStillProcessingTryLater =>
      'Video is still processing. Please try again later.';

  @override
  String get videoStreamNotFound => 'Video stream not found';

  @override
  String get videoWaitingProcessing => 'Video is waiting to be processed...';

  @override
  String videoWaitingWithQueue(int count) {
    return 'Video is waiting... $count video(s) ahead in queue';
  }

  @override
  String get videosFolderName => 'Huji';

  @override
  String get viewAppLogsSubtitle => 'View app logs';

  @override
  String get viewChangelogHistory => 'View version history';

  @override
  String get viewFromEndLabel => 'View from end';

  @override
  String get viewLogsButton => 'View logs';

  @override
  String get viewProgress => 'View progress';

  @override
  String get viewTasks => 'View tasks';

  @override
  String get viewVideoButton => 'View video';

  @override
  String waitingProcessTime(int seconds) {
    return 'Waiting time: $seconds s';
  }

  @override
  String get windowControlAlwaysOnTop => 'Always on top';

  @override
  String get windowControlClose => 'Close';

  @override
  String get windowControlMaximize => 'Maximize';

  @override
  String get windowControlMinimize => 'Minimize';

  @override
  String get windowControlRestore => 'Restore';

  @override
  String get wrapLinesLabel => 'Wrap lines';
}
