// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class HujiLocalizationsZh extends HujiLocalizations {
  HujiLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get aboutChangelogDescription =>
      '我们致力于为用户提供最好的视频剪辑体验。每次更新都会带来新的功能和改进，感谢您的支持！';

  @override
  String get aboutChangelogTitle => '关于更新日志';

  @override
  String get account => '账户';

  @override
  String get accountAndSecurity => '账号与安全';

  @override
  String get accountLoggedIn => '已登录';

  @override
  String get accountLogout => '退出登录';

  @override
  String get accountMismatch => '输入的账号与当前账号不一致';

  @override
  String get accountNotLoggedIn => '未登录';

  @override
  String get accountPageSubtitle => '登录状态与账户信息';

  @override
  String get accountTapToLogin => '点击登录';

  @override
  String get actionCancel => '取消';

  @override
  String get actionClear => '清除';

  @override
  String get actionClose => '关闭';

  @override
  String get actionConfirm => '确定';

  @override
  String actionConfirmWithCount(int count) {
    return '选择($count)';
  }

  @override
  String get actionContinue => '继续';

  @override
  String actionCountdownSeconds(int countdown) {
    return '${countdown}s';
  }

  @override
  String get actionCreate => '创建';

  @override
  String get actionDelete => '删除';

  @override
  String get actionDone => '完成';

  @override
  String get actionExport => '导出';

  @override
  String get actionGetVerificationCode => '获取验证码';

  @override
  String get actionPause => '暂停';

  @override
  String get actionPlay => '播放';

  @override
  String get actionProcessing => '处理中...';

  @override
  String get actionRefresh => '刷新';

  @override
  String get actionReload => '重新加载';

  @override
  String get actionRename => '重命名';

  @override
  String actionResendCodeCountdown(int countdown) {
    return '${countdown}s后重新获取';
  }

  @override
  String get actionReset => '重置';

  @override
  String get actionResume => '恢复';

  @override
  String get actionRetry => '重试';

  @override
  String get actionSave => '保存';

  @override
  String get actionSearch => '搜索';

  @override
  String get actionSendVerificationCode => '发送验证码';

  @override
  String get actionShare => '分享';

  @override
  String get actionTypeFireBall => '发球';

  @override
  String get actionTypePickBall => '捡球';

  @override
  String get actionTypePlayBall => '精彩球';

  @override
  String get actionTypePlayback => '回放';

  @override
  String get actionTypeTransition => '过渡';

  @override
  String get actionView => '查看';

  @override
  String get activeCpuCountLabel => '活动CPU数';

  @override
  String get addClipSegmentLabel => '添加片段';

  @override
  String get addMoreFiles => '+ 添加更多';

  @override
  String addSelectedFiles(int count) {
    return '添加 $count 个文件';
  }

  @override
  String albumAllMediaSubtitle(String mediaType) {
    return '所有$mediaType文件';
  }

  @override
  String albumCount(int count) {
    return '共 $count 个相册';
  }

  @override
  String get albumsSection => '相册';

  @override
  String get allImagesTile => '所有图片';

  @override
  String get allRounds => '全部回合';

  @override
  String get allVideosTile => '所有视频';

  @override
  String get analyzingVideoContent => '正在分析视频内容...';

  @override
  String get androidVersionLabel => 'Android版本';

  @override
  String get appFoldersTab => '应用文件夹';

  @override
  String get appNameLabel => '应用名称';

  @override
  String get appTitle => '弧迹';

  @override
  String get appVersionLabel => '应用版本';

  @override
  String get appearance => '外观';

  @override
  String get appearancePageSubtitle => '主题、文字大小与界面语言';

  @override
  String get applyFilter => '应用筛选';

  @override
  String get architectureLabel => '架构';

  @override
  String get authorize => '授权';

  @override
  String avatarUploadFailed(String error) {
    return '上传头像失败: $error';
  }

  @override
  String get avatarUploadSuccess => '头像上传成功';

  @override
  String get backToPreview => '↩ 返回预览';

  @override
  String get backendClip => '后台剪辑';

  @override
  String get backgroundDownload => '后台下载';

  @override
  String get backToParent => '返回上一级';

  @override
  String get backgroundMediaProcessingDescription =>
      '允许应用在后台处理视频压缩任务，即使您切换到其他应用或锁屏，压缩任务也会继续执行。';

  @override
  String get backgroundMediaProcessingPermission => '后台媒体处理权限';

  @override
  String get backgroundServicePermissionDeniedHint =>
      '如果拒绝授权，视频压缩将在前台进行，可能会影响您使用其他应用。';

  @override
  String get backgroundServicePermissionIntro => '为了让视频压缩任务能在后台继续执行，需要您授予以下权限：';

  @override
  String get backgroundServicePermissionTitle => '需要后台服务权限';

  @override
  String get badmintonAutoClipSubtitle => '羽毛球比赛视频自动剪辑';

  @override
  String get badmintonDefaultPreset => '羽毛球默认';

  @override
  String get badmintonMatchVideoClip => '羽毛球比赛视频剪辑';

  @override
  String get badmintonVideoAutoClip => '羽毛球视频自动剪辑';

  @override
  String get basicInfo => '基本信息';

  @override
  String get batchSelect => '选择';

  @override
  String batchSelectedCount(int count) {
    return '已选 $count';
  }

  @override
  String batchTasksDeleted(int count) {
    return '已删除 $count 个任务';
  }

  @override
  String get booleanNo => '否';

  @override
  String get booleanYes => '是';

  @override
  String get browserDownload => '浏览器下载';

  @override
  String get buildNumber => '构建号';

  @override
  String get buildVersionLabel => '构建版本';

  @override
  String get cacheCleared => '缓存已清除';

  @override
  String get cachedBadge => '已缓存';

  @override
  String get calculating => '计算中...';

  @override
  String get calculatingFileSize => '计算大小中...';

  @override
  String get cancelTask => '取消任务';

  @override
  String cannotAccessDirectory(String error) {
    return '无法访问此目录: $error';
  }

  @override
  String get cannotGenerateThumbnail => '无法生成缩略图';

  @override
  String get cannotLoadVideo => '无法加载视频';

  @override
  String get cannotOpenDownloadLink => '无法打开下载链接';

  @override
  String get cannotOpenLink => '无法打开链接';

  @override
  String cannotOpenLogViewer(String error) {
    return '无法打开日志查看器: $error';
  }

  @override
  String get cannotOpenLogViewerNavigatorNotInitialized =>
      '无法打开日志查看器: Navigator未初始化';

  @override
  String get changeAvatar => '更换头像';

  @override
  String get changePassword => '修改密码';

  @override
  String get changelog => '更新日志';

  @override
  String get checkAlbumPermissionOrEmpty => '请检查相册权限或相册是否为空';

  @override
  String get classNameLabel => '类名:';

  @override
  String get clearAllFilters => '清除全部';

  @override
  String get clearAppCacheSubtitle => '清除应用缓存';

  @override
  String clearCacheFailed(String error) {
    return '清除缓存失败: $error';
  }

  @override
  String get clearCacheTitle => '清除缓存';

  @override
  String get clearFilters => '清除筛选';

  @override
  String clearLogsFailed(String error) {
    return '清理日志失败: $error';
  }

  @override
  String get clearSearch => '清除搜索';

  @override
  String get clearSelection => '清除选择';

  @override
  String get clearTypeFilter => '清除类型筛选';

  @override
  String get clearedLogsOlderThan7Days => '已清理7天前的日志';

  @override
  String get clipCompleted => '剪辑完成！';

  @override
  String get clipConfig => '剪辑配置';

  @override
  String get clipMode => '剪辑模式';

  @override
  String get clipOptions => '剪辑选项';

  @override
  String get clipOptionsTitle => '选项';

  @override
  String get clipRecords => '剪辑记录';

  @override
  String get clipTaskCreatedRedirecting => '视频剪辑任务已创建，正在跳转到任务页面...';

  @override
  String get clippingVideo => '正在剪辑视频...';

  @override
  String get cloudClip => '云端剪辑';

  @override
  String get cloudClipUnavailable => '无法使用云端剪辑功能';

  @override
  String get cloudDetection => '云端检测';

  @override
  String get cloudDetectionHelp => '需要联网，精度更高';

  @override
  String get cloudDetectionHint => '使用云端服务进行检测，需要联网';

  @override
  String cloudDetectionTaskName(String fileName) {
    return '云端检测：$fileName';
  }

  @override
  String get compressedSize => '压缩后大小';

  @override
  String get compressionRatio => '压缩率';

  @override
  String compressionResults(int count) {
    return '压缩结果 ($count张)';
  }

  @override
  String get computerNameLabel => '计算机名称';

  @override
  String configPresetMismatch(int count, String presetName) {
    return '已设置 $count 项参数 · 与\"$presetName\" 不一致';
  }

  @override
  String confirmBatchDeleteMessage(int count) {
    return '确定要删除选中的 $count 个任务吗？此操作不可撤销。';
  }

  @override
  String get confirmCancel => '确认取消';

  @override
  String confirmCancelTaskMessage(String taskName) {
    return '确定要取消任务\"$taskName\"吗？此操作不可撤销。';
  }

  @override
  String get confirmClearCacheMessage => '确定要清除该视频的缓存吗？';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get confirmDeleteCurrentPlayingRound => '确定要删除当前正在播放的回合吗？此操作不可撤销。';

  @override
  String get confirmDeleteFileMessage => '确定要删除该文件吗？此操作不可恢复。';

  @override
  String get confirmDeleteLocalVideoMessage => '确定要删除这个本地视频吗？';

  @override
  String confirmDeleteTaskMessage(String taskName) {
    return '确定要删除任务\"$taskName\"吗？此操作不可撤销。';
  }

  @override
  String get confirmExportTitle => '确认导出';

  @override
  String get confirmLogoutMessage => '确定要退出登录吗？';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get confirmPurchase => '确认购买';

  @override
  String get confirmSubscription => '确认订阅';

  @override
  String contactInfoPrefix(String contact) {
    return '联系方式: $contact';
  }

  @override
  String get contactOptionalHint => '联系方式（可选）';

  @override
  String get contactUs => '联系我们';

  @override
  String get copyPath => '复制路径';

  @override
  String countdownSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String createFolderFailedWithError(String error) {
    return '创建文件夹失败: $error';
  }

  @override
  String get createFolderHere => '在此处新建文件夹';

  @override
  String get createTaskFailed => '创建任务失败';

  @override
  String createTaskFailedWithError(String error) {
    return '创建任务失败: $error';
  }

  @override
  String get createTimeLabel => '创建时间';

  @override
  String createdAt(String time) {
    return '创建时间: $time';
  }

  @override
  String createdAtWithValue(String time) {
    return '创建时间: $time';
  }

  @override
  String get createdTimeRange => '创建时间范围';

  @override
  String get creatingTask => '正在创建任务...';

  @override
  String get current => '当前';

  @override
  String get currentDirectoryLabel => '当前目录';

  @override
  String get currentDuration => '当前时长';

  @override
  String currentEditingRound(String label) {
    return '当前编辑：$label';
  }

  @override
  String currentFile(String path) {
    return '当前文件: $path';
  }

  @override
  String get currentPlanLabel => '当前方案';

  @override
  String get currentVersion => '当前版本';

  @override
  String get customClip => '自定义剪辑';

  @override
  String get customerHotline => '客服热线';

  @override
  String get dartVersionLabel => 'Dart版本';

  @override
  String get dataManagementSection => '数据管理';

  @override
  String get databaseDebugSubtitle => '查看数据库内容';

  @override
  String get databaseDebugTitle => '数据库调试';

  @override
  String get dateRangeTo => '至';

  @override
  String get debugFeaturesSection => '调试功能';

  @override
  String get defaultHighlightName => '集锦';

  @override
  String get defaultPreset => '默认预设';

  @override
  String get deleteCurrentRound => '删除当前回合';

  @override
  String deleteFailedWithError(String error) {
    return '删除失败: $error';
  }

  @override
  String get deleteFile => '删除文件';

  @override
  String get deleteTask => '删除任务';

  @override
  String get demoBadmintonSubtitle => '约 51 秒 · 算法样例视频';

  @override
  String get demoBadmintonTitle => '羽毛球演示';

  @override
  String get demoPingPongSubtitle => '约 23 秒 · 算法样例视频';

  @override
  String get demoPingPongTitle => '乒乓球演示';

  @override
  String get deselectAll => '取消全选';

  @override
  String get desktopDevice => '桌面设备';

  @override
  String get desktopLibraryEmptyHint => '点击「新建剪辑」上传比赛视频';

  @override
  String get desktopLibraryEmptyTitle => '暂无视频';

  @override
  String desktopLibraryItemCount(int count) {
    return '共 $count 个';
  }

  @override
  String desktopLibraryLoadFailed(String error) {
    return '加载失败：$error';
  }

  @override
  String get desktopLibraryTitle => '视频库';

  @override
  String get desktopNavLibrary => '视频库';

  @override
  String get desktopNavSettings => '设置';

  @override
  String get desktopNavTasks => '任务';

  @override
  String get desktopNewClip => '新建剪辑';

  @override
  String get desktopWorkspaceSection => '工作区';

  @override
  String get detectedSegments => '检测到的片段';

  @override
  String get detectionMode => '检测方式';

  @override
  String get devToolsSection => '开发工具';

  @override
  String get developerModeAlreadyEnabled => '开发模式已启用';

  @override
  String get developerModeEnabledMessage => '开发模式已启用，您现在可以访问开发功能';

  @override
  String get developerModeTitle => '开发者模式';

  @override
  String get developerModeWarning => '这些功能仅供开发调试使用，请谨慎操作。';

  @override
  String get developerOptions => '开发者选项';

  @override
  String get developerOptionsDescription => '访问开发工具和调试功能';

  @override
  String get developerPasswordIncorrect => '请输入正确的开发者密码';

  @override
  String get deviceBrandLabel => '设备品牌';

  @override
  String get deviceIdLabel => '设备ID';

  @override
  String get deviceIdentifierLabel => '设备标识符';

  @override
  String get deviceInfoFetchFailed => '获取失败';

  @override
  String deviceInfoFetchFailedWithError(String error) {
    return '获取设备信息失败: $error';
  }

  @override
  String get deviceInfoFetching => '获取中...';

  @override
  String get deviceInfoLabel => '设备信息';

  @override
  String get deviceLabel => '设备';

  @override
  String get deviceModelLabel => '设备型号';

  @override
  String get deviceNameLabel => '设备名称';

  @override
  String get deviceTypeLabel => '设备类型';

  @override
  String get discordCommunity => 'Discord 社区';

  @override
  String get distroNameLabel => '发行版名称';

  @override
  String get distroVersionLabel => '发行版版本';

  @override
  String get downloadCompleted => '下载完成';

  @override
  String get downloadError => '下载错误';

  @override
  String downloadErrorWithDetails(String error) {
    return '下载过程中发生错误: $error';
  }

  @override
  String get downloadFailed => '下载失败';

  @override
  String get downloadInBackground => '后台下载';

  @override
  String get downloadInBrowser => '浏览器下载';

  @override
  String get downloadInProgress => '下载中';

  @override
  String get downloadLinkOpenedInBrowser => '已在浏览器中打开下载链接';

  @override
  String get downloadLinkUnavailable => '下载链接不可用';

  @override
  String get downloadNow => '立即下载';

  @override
  String get downloadProgress => '下载进度';

  @override
  String get downloadStarting => '开始下载...';

  @override
  String get downloadWillContinueInBackground => '下载将在后台继续';

  @override
  String get downloadingResult => '正在下载结果...';

  @override
  String get dragToReorderHint => '长按拖动可调整顺序';

  @override
  String get dragVideoHere => '拖拽视频到这里';

  @override
  String durationLabel(String duration) {
    return '时长: $duration';
  }

  @override
  String get durationPackages => '时长套餐';

  @override
  String get durationPlans => '时长方案';

  @override
  String durationSeconds(int seconds) {
    return '$seconds 秒';
  }

  @override
  String get durationShortenedLabel => '时长缩短';

  @override
  String get editBreadcrumb => '编辑';

  @override
  String get editFeatureUnavailable => '无法使用编辑功能';

  @override
  String get editName => '修改名字';

  @override
  String get editProfile => '编辑资料';

  @override
  String get editRound => '编辑回合';

  @override
  String get editToolAiClip => 'AI剪辑';

  @override
  String get editToolAudio => '音频';

  @override
  String get editToolClip => '剪辑';

  @override
  String get editToolPip => '画中画';

  @override
  String get editToolSticker => '贴纸';

  @override
  String get editToolText => '文字';

  @override
  String get editVideo => '编辑视频';

  @override
  String get email => '邮箱';

  @override
  String get emailLoginOnlyNotice => '由于政策原因，暂时只能使用邮箱登录，如无法登陆请联系我 ！';

  @override
  String get emailSupport => '邮箱支持';

  @override
  String get endDateLabel => '结束日期';

  @override
  String get enterConfirmPassword => '请确认密码';

  @override
  String get enterConfirmPasswordRequired => '请输入确认密码';

  @override
  String get enterDeveloperPasswordHint => '请输入开发者密码以启用开发模式';

  @override
  String get enterDeveloperPasswordTitle => '输入开发者密码';

  @override
  String get enterKeywordToStartSearch => '输入关键词开始搜索';

  @override
  String get enterName => '请输入名字';

  @override
  String get enterNewPassword => '请输入新密码';

  @override
  String get enterPhoneOrEmail => '请输入手机/邮箱';

  @override
  String get enterSearchKeyword => '请输入搜索关键词';

  @override
  String get enterVerificationCode => '请输入验证码';

  @override
  String entityInfoDateAndItemCount(String date, int count) {
    return '$date · $count个项目';
  }

  @override
  String get errorGalleryReadFailed => '读取相册失败，请重试或检查系统相册权限';

  @override
  String get errorImageLoadFailed => '图片加载失败，可能是图片损坏或当前设备暂不支持该格式';

  @override
  String get errorLoginExpired => '登录已失效，请重新登录';

  @override
  String get errorNetworkRetry => '网络异常，请检查网络后重试';

  @override
  String get errorResourceNotFound => '资源不存在或已失效';

  @override
  String get errorStorageFull => '存储空间不足或应用数据不可写，请清理空间后重试';

  @override
  String get errorVideoNotSupported => '当前设备暂不支持播放该视频，请尝试转码或压缩后再试';

  @override
  String estimatedRemainingTime(String duration) {
    return '预计剩余时间: $duration';
  }

  @override
  String estimatedRemainingTimeSeconds(int seconds) {
    return '预计剩余时间：$seconds s';
  }

  @override
  String get exceptionDetailsLabel => '详细信息';

  @override
  String get existingVideoClip => '已有视频剪辑';

  @override
  String get existingVideoClipDescription => '选择本地视频文件进行自动剪辑和片段提取';

  @override
  String get existingVideoClipMode => '已有视频剪辑模式';

  @override
  String get existingVideoClipSubtitle => '剪辑本地视频文件';

  @override
  String get exitFullscreen => '退出全屏';

  @override
  String get experimentalFeatureASubtitle => '实验性功能A';

  @override
  String get experimentalFeatureATitle => '实验功能A';

  @override
  String get experimentalFeatureBSubtitle => '实验性功能B';

  @override
  String get experimentalFeatureBTitle => '实验功能B';

  @override
  String get experimentalFeaturesSection => '实验功能';

  @override
  String get expired => '已过期';

  @override
  String get exportComplete => '导出完成';

  @override
  String get exportConfigTitle => '📤 导出配置';

  @override
  String get exportEncoding => '正在编码...';

  @override
  String get exportFailedTitle => '导出失败';

  @override
  String get exportFileNotGenerated => '导出文件未生成';

  @override
  String get exportFormatMp4H264 => 'MP4 (H.264)';

  @override
  String get exportLogsSubtitle => '导出应用日志';

  @override
  String get exportLogsTitle => '导出日志';

  @override
  String get exportPreparing => '准备导出...';

  @override
  String exportProgressPercent(String percent) {
    return '正在导出... $percent%';
  }

  @override
  String get exportQualityMobileShare => '移动分享';

  @override
  String get exportQualityOriginal => '原画';

  @override
  String get exportRunInBackground => '后台运行';

  @override
  String get exportQualityOriginalMeta => '原始分辨率';

  @override
  String get exportQualityRecommended => '推荐';

  @override
  String get exportQualitySmallerSize => '体积较小';

  @override
  String get exportVideoTitle => '导出视频';

  @override
  String get exporting => '导出中...';

  @override
  String get extendMoreEditFeaturesHint => '可在这里扩展更多编辑功能';

  @override
  String get faqClippingDuration => '剪辑需要多长时间？';

  @override
  String get faqClippingDurationAnswer => '一小时的视频，通常需要10分钟左右完成剪辑。';

  @override
  String get faqHowToSelectSport => '如何选择运动类型？';

  @override
  String get faqHowToSelectSportAnswer =>
      '在剪辑配置页面，您可以选择羽毛球、乒乓球等运动类型，系统会根据运动特点进行智能剪辑。';

  @override
  String get faqHowToUploadVideo => '如何上传视频？';

  @override
  String get faqHowToUploadVideoAnswer => '在首页点击\"开始剪辑\"按钮，选择要上传的视频文件即可。';

  @override
  String get faqSupportedFormats => '支持哪些视频格式？';

  @override
  String get faqSupportedFormatsAnswer => '支持MP4、AVI、MOV、MKV等常见视频格式。';

  @override
  String get faqTitle => '常见问题';

  @override
  String get fasterAndMoreAccurate => '更快更准';

  @override
  String get favoriteCurrentRound => '收藏当前回合';

  @override
  String get favoriteRounds => '收藏回合';

  @override
  String get favoriteSegment => '收藏片段';

  @override
  String get featureBatchProcessing => '批量处理能力';

  @override
  String get featureCloudAndLocalClip => '云端和本地剪辑';

  @override
  String get featureInDevelopment => '功能开发中...';

  @override
  String get featureInstantSegmentMarking => '即时片段标记';

  @override
  String get featureLiveRecording => '实时录制视频';

  @override
  String get featureMultipleFormats => '支持多种视频格式';

  @override
  String get featureNotSupportedOnDesktop => '此功能在桌面端暂不支持';

  @override
  String get featureOnSiteRecording => '适合现场比赛录制';

  @override
  String get featureRecordAndClipEfficiency => '边拍边剪，效率更高';

  @override
  String get featureSmartSegmentDetection => '智能片段识别';

  @override
  String get feedback => '意见反馈';

  @override
  String get feedbackDescriptionHint => '请详细描述您遇到的问题或建议...';

  @override
  String get feedbackSubmittedSuccessfully => '反馈提交成功，感谢您的建议！';

  @override
  String get feedbackTitleHint => '标题（如：功能异常/建议）';

  @override
  String get female => '女';

  @override
  String get fetchingDownloadLink => '正在获取下载链接...';

  @override
  String ffmpegConvertFailed(String output) {
    return 'FFmpeg转换失败: $output';
  }

  @override
  String ffmpegExecuteException(String error) {
    return '执行异常: $error';
  }

  @override
  String ffmpegExecuteFailed(String logs) {
    return '执行失败: $logs';
  }

  @override
  String ffmpegExitCode(String code) {
    return 'ffmpeg 退出码 $code';
  }

  @override
  String get ffmpegNotInitialized => 'FFmpeg未初始化';

  @override
  String get ffmpegOperationCancelled => 'FFmpeg操作已取消';

  @override
  String get fileDeleted => '文件已删除';

  @override
  String get fileDetailsTitle => '详细信息';

  @override
  String get fileDoesNotExist => '文件不存在';

  @override
  String get taskResultUnavailable => '无法查看任务结果';

  @override
  String fileInfoAccessedAt(String time) {
    return '访问时间: $time';
  }

  @override
  String fileInfoCachePath(String path) {
    return '缓存路径: $path';
  }

  @override
  String fileInfoCreatedAt(String time) {
    return '创建时间: $time';
  }

  @override
  String fileInfoFileName(String name) {
    return '文件名: $name';
  }

  @override
  String get fileInfoLabel => '文件信息:';

  @override
  String fileInfoModifiedAt(String time) {
    return '修改时间: $time';
  }

  @override
  String fileInfoSize(String size) {
    return '大小: $size';
  }

  @override
  String get fileName => '文件名';

  @override
  String get fileNameAlreadyExists => '文件名已存在';

  @override
  String fileNameWithSegmentCount(String fileName, int count) {
    return '$fileName ($count个片段)';
  }

  @override
  String fileSizeLabel(String size) {
    return '大小: $size';
  }

  @override
  String filesSelectedCount(int count) {
    return '已选择 $count 个文件';
  }

  @override
  String get filterAll => '全部';

  @override
  String get filterConditions => '筛选条件';

  @override
  String get filterLocal => '本地';

  @override
  String get filterOptionsTitle => '过滤选项';

  @override
  String get filterProcessStatus => '处理状态';

  @override
  String get filterSportType => '运动类型';

  @override
  String get flutterVersionLabel => 'Flutter版本';

  @override
  String get folderAlreadyExists => '文件夹已存在';

  @override
  String get folderCreatedSuccess => '文件夹创建成功';

  @override
  String get folderEmpty => '此文件夹为空';

  @override
  String get folderInfo => '文件夹信息';

  @override
  String folderItemCount(Object count) {
    return '$count个项目';
  }

  @override
  String get folderNameHint => '输入文件夹名称';

  @override
  String get formatLabel => '格式';

  @override
  String foundFileCount(int count) {
    return '找到 $count 个文件';
  }

  @override
  String frameExtractionFailed(String output) {
    return '帧提取失败: $output';
  }

  @override
  String frameOutOfRange(String maxFrames) {
    return '帧数超出范围: 0-$maxFrames';
  }

  @override
  String get freeBadge => '限免';

  @override
  String get fullDiskSearchTab => '全盘搜索';

  @override
  String get fullscreenPlayback => '全屏播放';

  @override
  String get galleryNotSupportedOnDesktop => '相册功能在桌面端暂不支持';

  @override
  String get galleryPermissionMessage => '为了选择照片和视频，请在设置中授予相册访问权限。';

  @override
  String get galleryPermissionRequired => '需要相册权限';

  @override
  String get gender => '性别';

  @override
  String get general => '常规';

  @override
  String get generalPageSubtitle => '启动、存储与隐私相关选项';

  @override
  String generateThumbnailFailed(String path, String error) {
    return '生成缩略图失败: $path: $error';
  }

  @override
  String get generatingFinalVideo => '正在生成最终视频...';

  @override
  String get generatingThumbnail => '生成缩略图中...';

  @override
  String getFolderInfoFailed(String error) {
    return '获取文件夹信息失败: $error';
  }

  @override
  String get getMatchSegments => '获取比赛片段';

  @override
  String get getxVersionLabel => 'GetX版本';

  @override
  String get goToFeature => '前往功能';

  @override
  String get goToSettings => '去设置';

  @override
  String get hardwareLabel => '硬件';

  @override
  String get helpAndFeedback => '帮助与反馈';

  @override
  String get highlightClip => '精彩球剪辑';

  @override
  String get highlightClipHelp => '自动识别并保留精彩回合';

  @override
  String get highlightClipTooltip => '自动剪辑单局时间长的精彩球';

  @override
  String get homeBadmintonClip => '羽毛球剪辑';

  @override
  String get homeBadmintonClipDesc => '剪辑羽毛球比赛视频';

  @override
  String get homeCarouselAiClipSubtitle => '自动剪辑精彩片段，移除休息捡球片段';

  @override
  String get homeCarouselAiClipTitle => 'AI比赛自动剪辑';

  @override
  String get homeImageCompress => '图片压缩';

  @override
  String get homeImageCompressDesc => '压缩图片文件';

  @override
  String get homeLoading => '正在加载...';

  @override
  String get homePageTitle => '主页';

  @override
  String get homePingpongClip => '乒乓球剪辑';

  @override
  String get homePingpongClipDesc => '剪辑乒乓球比赛视频';

  @override
  String get homeStartClip => '开始剪辑';

  @override
  String get homeToolsSection => '实用工具';

  @override
  String get homeVideoCategoryCompleted => '已完成';

  @override
  String get homeVideoCategoryProcessing => '处理中';

  @override
  String get homeVideoCategoryRaw => '原始';

  @override
  String get homeVideoCategoryUnknown => '未知';

  @override
  String get homeVideoCompress => '视频压缩';

  @override
  String get homeVideoCompressDesc => '压缩视频文件';

  @override
  String get homeVideoNoMoreRecords => '暂无更多记录';

  @override
  String homeVideoProcessingProgress(int progress) {
    return '处理中 $progress%';
  }

  @override
  String get homeVideoSubtitleCompleted => '已完成';

  @override
  String get homeVideoSubtitlePending => '待处理 | 原始文件';

  @override
  String homeVideoSubtitleProcessing(String taskId) {
    return '处理中 | 处理记录ID: $taskId';
  }

  @override
  String get homeVideoTitleEditing => '编辑视频';

  @override
  String homeVideoTitleProcessing(String taskId) {
    return '处理中记录Id #$taskId';
  }

  @override
  String get homeVideoTitleRaw => '原始视频';

  @override
  String get homeVideoTitleUnknown => '未知视频';

  @override
  String get hostNameLabel => '主机名';

  @override
  String imageCompressResultsTitle(int count) {
    return '压缩结果 ($count张)';
  }

  @override
  String get imageDetails => '图片详情';

  @override
  String get imageFileLabel => '图片文件';

  @override
  String get imageLabel => '图片';

  @override
  String get infoCreatedAt => '创建时间';

  @override
  String get infoFileCount => '文件数量';

  @override
  String get infoFolderCount => '文件夹数量';

  @override
  String get infoModifiedAt => '修改时间';

  @override
  String get infoPath => '路径';

  @override
  String get infoTotalItems => '总项目';

  @override
  String get internalStorageSection => '内部存储设备';

  @override
  String infoUpdateFailed(String error) {
    return '信息更新失败: $error';
  }

  @override
  String get infoUpdatedSuccessfully => '信息更新成功';

  @override
  String initFailedWithError(String error) {
    return '初始化失败: $error';
  }

  @override
  String get inputFileNameHint => '输入文件名...';

  @override
  String get inputFileNameKeywordHint => '输入文件名关键词...';

  @override
  String get inputKeywordHint => '输入关键词...';

  @override
  String get inputVideoLabel => '输入视频';

  @override
  String get installNow => '立即安装';

  @override
  String get installTime => '安装时间';

  @override
  String get intervalMustBePositive => '时间间隔必须大于0';

  @override
  String get invalidIndex => '无效的索引';

  @override
  String get issueTypeBug => '功能异常';

  @override
  String get issueTypeSuggestion => '建议';

  @override
  String itemCountUnit(int count) {
    return '$count 个';
  }

  @override
  String get itemTypeDirectory => '目录';

  @override
  String get itemTypeFile => '文件';

  @override
  String get itemTypeItem => '项目';

  @override
  String get labelDuration => '时长';

  @override
  String get labelError => '错误';

  @override
  String get labelSize => '大小';

  @override
  String get labelType => '类型';

  @override
  String get labelUnknown => '未知';

  @override
  String get language => '语言';

  @override
  String get languageChinese => '中文';

  @override
  String get languageDescription => '菜单、按钮与标签所使用的语言';

  @override
  String get languageEnglish => 'English';

  @override
  String get latestVersion => '最新版本';

  @override
  String get leavePageProcessingNotification => '你可以离开页面，视频处理完后将会通过消息通知您。';

  @override
  String get linkRequiresBrowserDownload => '该链接需要在浏览器中下载';

  @override
  String get loadAlbumFailed => '加载相册失败';

  @override
  String loadAlbumFailedWithError(String error) {
    return '加载相册失败: $error';
  }

  @override
  String loadChangelogFailed(String error) {
    return '加载更新日志失败: $error';
  }

  @override
  String loadDemoVideoFailed(String error) {
    return '加载演示视频失败：$error';
  }

  @override
  String loadFailed(String error) {
    return '加载失败: $error';
  }

  @override
  String get loadFailedShort => '加载失败';

  @override
  String loadLogFilesFailed(String error) {
    return '加载日志文件失败: $error';
  }

  @override
  String get loadMore => '加载更多...';

  @override
  String loadMoreFailedWithError(String error) {
    return '加载更多失败: $error';
  }

  @override
  String loadSubscriptionFailed(String error) {
    return '加载订阅信息失败: $error';
  }

  @override
  String loadUserInfoFailed(String error) {
    return '加载用户信息失败: $error';
  }

  @override
  String get loadVideoDataFailed => '加载视频数据失败';

  @override
  String loadVideoDetailFailed(String error) {
    return '加载视频详情失败: $error';
  }

  @override
  String get loading => '加载中...';

  @override
  String get loadingChangelog => '正在加载更新日志...';

  @override
  String get localClip => '本地剪辑';

  @override
  String localClipFailed(String error) {
    return '本地视频剪辑失败: $error';
  }

  @override
  String get localClipTaskCreatedRedirecting => '本地视频剪辑任务已创建，正在跳转到任务页面...';

  @override
  String get localDetecting => '正在本地检测…';

  @override
  String get localDetection => '本地检测';

  @override
  String localDetectionFailed(String error) {
    return '本地检测失败: $error';
  }

  @override
  String get localDetectionHelp => '离线使用，无需联网';

  @override
  String localDetectionTaskName(String fileName) {
    return '本地检测：$fileName';
  }

  @override
  String localDetectionTasksSubmitted(int count) {
    return '已提交 $count 个本地检测任务，可离开页面查看任务列表';
  }

  @override
  String get localModelNotFoundFallback => '未找到本地模型，已回退为云端检测';

  @override
  String get localOnnxDetectionHint => '使用本地 ONNX 模型进行离线检测';

  @override
  String get localTasks => '本地任务';

  @override
  String get localVideoClip => '本地视频剪辑';

  @override
  String get localVideoStatusPending => '待检测';

  @override
  String get localVideoStatusProcessing => '检测中';

  @override
  String get localizedModelLabel => '本地化型号';

  @override
  String get logFilesGeneratedAtRuntime => '日志文件将在应用运行时生成';

  @override
  String get logLevelLabel => '日志级别:';

  @override
  String get logViewerTitle => '日志查看器';

  @override
  String get loginAlreadyHaveAccount => '已有账号?';

  @override
  String get loginAuthCodeHint => '请输入验证码';

  @override
  String get loginAuthCodeLabel => '验证码';

  @override
  String get loginAuthCodeMode => '验证码登录';

  @override
  String get loginAuthCodeSent => '验证码已发送';

  @override
  String get loginAuthCodeSentCheck => '验证码已发送，请注意查收';

  @override
  String get loginBackToLogin => '返回登录';

  @override
  String get loginConfirmNewPassword => '确认新密码';

  @override
  String get loginConfirmNewPasswordHint => '请确认新密码';

  @override
  String loginFailed(String error) {
    return '登录失败: $error';
  }

  @override
  String get loginForgotPassword => '忘记密码？';

  @override
  String get loginIdentifierHint => '请输入手机号或邮箱';

  @override
  String get loginIdentifierLabel => '手机号/邮箱';

  @override
  String get loginIdentifierLabelOr => '手机号或邮箱';

  @override
  String get loginLoginNow => '立即登录';

  @override
  String get loginNeedLoginSubtitle => '请先登录您的账户以继续使用';

  @override
  String get loginNeedLoginTitle => '需要登录才能访问此功能';

  @override
  String get loginNewPassword => '新密码';

  @override
  String get loginNewPasswordHint => '请输入新密码';

  @override
  String get loginNoAccount => '还没有账号? ';

  @override
  String get loginPasswordHint => '请输入密码';

  @override
  String get loginPasswordLabel => '密码';

  @override
  String get loginPasswordMismatch => '两次输入的密码不一致';

  @override
  String get loginPasswordMode => '密码登录';

  @override
  String get loginPasswordTab => '账号密码登录';

  @override
  String get loginRegisterAccount => '注册账户';

  @override
  String loginRegisterFailed(String error) {
    return '注册失败: $error';
  }

  @override
  String get loginRegisterNow => '立即注册';

  @override
  String get loginRegisterSuccess => '注册成功';

  @override
  String get loginRegisterTitle => '用户注册';

  @override
  String get loginRegistering => '注册中...';

  @override
  String get loginRememberPassword => '记住密码';

  @override
  String get loginSocialLoginDivider => '或使用其他方式登录(暂未开放)';

  @override
  String get loginSocialLoginUnavailable => '该登录方式暂未开放';

  @override
  String get loginRememberedPassword => '想起密码了？ ';

  @override
  String get loginRequiredForClipHistory => '需要登录才能查看剪辑记录';

  @override
  String loginResetPasswordFailed(String error) {
    return '密码重置失败: $error';
  }

  @override
  String get loginResetPasswordSuccess => '密码重置成功';

  @override
  String get loginResetPasswordTitle => '重置密码';

  @override
  String loginSendAuthCodeFailed(String error) {
    return '发送验证码失败: $error';
  }

  @override
  String loginSendFailed(String error) {
    return '发送失败: $error';
  }

  @override
  String get loginSubtitle => '请登录您的账户';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get loginTitle => '登录';

  @override
  String get loginValidationAuthCodeFormat => '请输入4-6位数字验证码';

  @override
  String get loginValidationAuthCodeRequired => '请输入验证码';

  @override
  String get loginValidationIdentifierInvalid => '请输入正确的手机号或邮箱';

  @override
  String get loginValidationIdentifierRequired => '请输入手机号或邮箱';

  @override
  String get loginValidationPasswordMinLength => '密码长度至少为8位';

  @override
  String get loginValidationPasswordRequired => '请输入密码';

  @override
  String get loginWelcome => '欢迎使用';

  @override
  String logoutFailed(String error) {
    return '退出登录失败: $error';
  }

  @override
  String get male => '男';

  @override
  String get manufacturerLabel => '制造商';

  @override
  String get markAllReadSuccess => '已全部标记为已读';

  @override
  String get markReadFailed => '标记已读失败';

  @override
  String get matchType => '比赛类型';

  @override
  String get matchTypeDoubles => '双打比赛';

  @override
  String get matchTypeSingles => '单打比赛';

  @override
  String maxSelectionCountReached(int count) {
    return '最多只能选择 $count 个文件';
  }

  @override
  String maxSelectionCountReachedFor(int count, String itemType) {
    return '最多只能选择 $count 个$itemType';
  }

  @override
  String get maxServeDuration => '最大发球时长';

  @override
  String get maxServeDurationTooltip => '限制发球时长(秒)';

  @override
  String mediaItemCount(int count, String mediaType) {
    return '$count 个$mediaType';
  }

  @override
  String get mediaFilesSection => '媒体文件';

  @override
  String get mediaTypeAll => '媒体';

  @override
  String get mediaTypeImage => '图片';

  @override
  String get mediaTypeVideo => '视频';

  @override
  String get memorySizeLabel => '内存大小';

  @override
  String get mergeAdjacentRounds => '合并相邻回合';

  @override
  String get mergeAdjacentRoundsHelp => '间隔小于 3 秒自动合并';

  @override
  String get mergeServeAndHit => '合并发球和击球';

  @override
  String get mergeServeAndHitTooltip => '勾选后，只有发球的回合（发球下网和失误）以及练球片段也会被剪辑进去';

  @override
  String messageTimeLabel(String time) {
    return '时间: $time';
  }

  @override
  String get messagesTitle => '消息';

  @override
  String get minDurationHint => '小于此时长的回合不会被保留';

  @override
  String get minHighlightDuration => '精彩球最小时长';

  @override
  String get minHighlightDurationSeconds => '精彩球最小时长(秒)';

  @override
  String get minHighlightDurationTooltip => '精彩球最小时长（秒）';

  @override
  String get minRoundDuration => '单回合最小时长(秒)';

  @override
  String get minRoundDurationTooltip => '单回合最小时长（秒）';

  @override
  String minutesDecimalValue(String value) {
    return '$value分钟';
  }

  @override
  String minutesValue(int minutes) {
    return '$minutes分钟';
  }

  @override
  String get mobileDevice => '移动设备';

  @override
  String modelNotFound(String modelName) {
    return '模型不存在: $modelName';
  }

  @override
  String get monthlyBilledLabel => '/ 每月';

  @override
  String get name => '名字';

  @override
  String namedFeatureInDevelopment(String featureName) {
    return '$featureName开发中...';
  }

  @override
  String get navHome => '主页';

  @override
  String get navProfile => '我的';

  @override
  String get navTasks => '任务';

  @override
  String get navVideos => '视频';

  @override
  String get network => '网络';

  @override
  String get networkDebugSubtitle => '网络请求调试';

  @override
  String get networkDebugTitle => '网络调试';

  @override
  String get networkPageSubtitle => 'API 环境与下载设置';

  @override
  String get newClip => '新建剪辑';

  @override
  String get newFileNameLabel => '新文件名';

  @override
  String get newFolder => '新建文件夹';

  @override
  String get newVersionFound => '发现新版本';

  @override
  String get noAlbumsFound => '没有找到相册';

  @override
  String get noChangelogEntries => '暂无更新日志';

  @override
  String get noCompletedTasks => '没有已完成的任务';

  @override
  String get noFavoriteRounds => '暂无收藏回合';

  @override
  String get noItemsSelected => '未选择项目';

  @override
  String get noLogFilesFound => '没有找到日志文件';

  @override
  String get noMatchingFiles => '没有找到匹配的文件';

  @override
  String noMatchingMediaFiles(String mediaType) {
    return '没有找到匹配的$mediaType文件';
  }

  @override
  String noMediaFiles(String mediaType) {
    return '没有找到$mediaType文件';
  }

  @override
  String get noMessages => '暂无消息';

  @override
  String get noMoreData => '没有更多数据了';

  @override
  String get noPlayableVideos => '没有可播放的视频';

  @override
  String get noPlayingRound => '没有正在播放的回合';

  @override
  String get noProcessingRecords => '暂无处理记录';

  @override
  String get noRoundSegments => '暂无回合片段';

  @override
  String get noSegmentsToExport => '没有可导出的片段';

  @override
  String get noSegmentsToSave => '没有可保存的片段';

  @override
  String get noSegmentsYet => '暂无片段';

  @override
  String get noTasks => '暂无任务';

  @override
  String get noValidSegments => '没有有效的片段';

  @override
  String get noVideo => '暂无视频';

  @override
  String get noVideoData => '暂无视频数据';

  @override
  String get noVideoDataAvailable => '没有可用的视频数据';

  @override
  String get noVideos => '暂无视频';

  @override
  String get notAvailable => '暂无';

  @override
  String get notBound => '暂未绑定';

  @override
  String get officialMatchPreset => '正式比赛配置';

  @override
  String get officialWebsite => '官方网站';

  @override
  String openBrowserFailed(String error) {
    return '打开浏览器失败: $error';
  }

  @override
  String openCloudClipFailed(String error) {
    return '打开云端剪辑功能失败: $error';
  }

  @override
  String get openEditFeatureFailed => '打开编辑功能失败';

  @override
  String get openFile => '打开文件';

  @override
  String openFileFailed(String error) {
    return '打开文件失败: $error';
  }

  @override
  String get openFolder => '打开文件夹';

  @override
  String openFolderFailed(String error) {
    return '打开文件夹失败: $error';
  }

  @override
  String get openThisFolder => '打开此文件夹';

  @override
  String get operationCancelled => '操作已被取消';

  @override
  String get operationFailed => '操作失败';

  @override
  String operationFailedWithError(String error) {
    return '操作失败: $error';
  }

  @override
  String get orLabel => '或者';

  @override
  String get originalSize => '原始大小';

  @override
  String get outputQualityLabel => '输出清晰度';

  @override
  String get outputVideoLabel => '输出视频';

  @override
  String packageDurationValidity(int minutes, String validity) {
    return '$minutes分钟 · $validity有效期';
  }

  @override
  String get pageLoadFailed => '页面加载失败';

  @override
  String passwordChangeFailed(String error) {
    return '密码修改失败: $error';
  }

  @override
  String get passwordChangedSuccessfully => '密码修改成功';

  @override
  String get passwordMinLength => '密码长度不能少于6位';

  @override
  String get passwordSettings => '密码设置';

  @override
  String get pathCopiedToClipboard => '路径已复制到剪贴板';

  @override
  String pathNotFound(String path) {
    return '路径不存在: $path';
  }

  @override
  String get pauseTask => '暂停任务';

  @override
  String get pendingLogsTitle => '待处理日志';

  @override
  String pendingLogsWithCount(int count) {
    return '待处理日志 ($count 条)';
  }

  @override
  String get performanceMonitorSubtitle => '监控应用性能';

  @override
  String get performanceMonitorTitle => '性能监控';

  @override
  String get personalCenter => '个人中心';

  @override
  String get permanent => '永久';

  @override
  String get permissionCheckTitle => '权限检查';

  @override
  String permissionChecking(String permissionName) {
    return '正在检查: $permissionName';
  }

  @override
  String get permissionDenied => '权限被拒绝';

  @override
  String permissionDeniedRetry(String permissionName) {
    return '$permissionName 被拒绝，请重试';
  }

  @override
  String get permissionDescriptionBody => '应用需要以下权限才能正常运行。如果权限被拒绝，相关功能可能无法使用。';

  @override
  String get permissionDescriptionTitle => '权限说明';

  @override
  String get permissionDetailAudio => '用于播放视频和音频内容，确保媒体播放功能正常';

  @override
  String get permissionDetailCamera => '用于录制新的视频内容，支持拍照和视频录制功能';

  @override
  String get permissionDetailDefault => '应用功能所需权限';

  @override
  String get permissionDetailMicrophone => '用于录制视频时的音频输入，确保视频有声音';

  @override
  String get permissionDetailNotification => '用于在后台处理视频时显示进度通知，让您了解处理状态';

  @override
  String get permissionDetailPhotos => '用于访问相册中的图片和视频，选择现有内容进行剪辑';

  @override
  String get permissionDetailStorage => '用于保存剪辑后的视频文件到设备存储，以及读取现有视频';

  @override
  String get permissionDetailVideos => '用于访问设备存储中的视频文件，支持各种视频格式';

  @override
  String permissionDiagnosticDenied(int count) {
    return '  已拒绝: $count';
  }

  @override
  String get permissionDiagnosticDetailStatus => '详细状态:';

  @override
  String permissionDiagnosticFetchFailed(String error) {
    return '获取诊断信息失败: $error';
  }

  @override
  String permissionDiagnosticGranted(int count) {
    return '  已授权: $count';
  }

  @override
  String permissionDiagnosticGrantedRate(String percent) {
    return '  授权率: $percent%';
  }

  @override
  String permissionDiagnosticPermanentlyDenied(int count) {
    return '  永久拒绝: $count';
  }

  @override
  String get permissionDiagnosticStats => '权限统计:';

  @override
  String permissionDiagnosticTime(String timestamp) {
    return '诊断时间: $timestamp';
  }

  @override
  String get permissionDiagnosticTitle => '权限诊断信息';

  @override
  String permissionDiagnosticTotal(int count) {
    return '  总数: $count';
  }

  @override
  String get permissionExplanation => '此权限对于应用正常运行是必要的。请在接下来的系统对话框中点击\"允许\"。';

  @override
  String permissionGrantedSuccess(String permissionName) {
    return '$permissionName 已成功授权';
  }

  @override
  String get permissionManagement => '权限管理';

  @override
  String get permissionNameAudio => '音频权限';

  @override
  String get permissionNameCamera => '相机权限';

  @override
  String get permissionNameMicrophone => '麦克风权限';

  @override
  String get permissionNameNotification => '通知权限';

  @override
  String get permissionNamePhotos => '相册权限';

  @override
  String get permissionNameStorage => '存储权限';

  @override
  String get permissionNameUnknown => '未知权限';

  @override
  String get permissionNameVideos => '视频权限';

  @override
  String permissionPermanentlyDenied(String permissionName) {
    return '$permissionName 被永久拒绝，请在设置中手动开启。';
  }

  @override
  String get permissionStatusDenied => '已拒绝';

  @override
  String get permissionStatusGranted => '已授权';

  @override
  String get permissionStatusLimited => '有限权限';

  @override
  String permissionStatusMessage(String permissionName, String status) {
    return '$permissionName 状态: $status';
  }

  @override
  String get permissionStatusPermanentlyDenied => '永久拒绝';

  @override
  String get permissionStatusRestricted => '受限制';

  @override
  String get permissionStatusUnknown => '未知';

  @override
  String get permissionSuggestionDenied => '点击\"请求权限\"按钮重新申请';

  @override
  String get permissionSuggestionLimited => '权限部分授权，部分功能可能受限';

  @override
  String get permissionSuggestionPermanentlyDenied => '需要在系统设置中手动开启';

  @override
  String get permissionSuggestionRestricted => '权限受到系统限制，请联系管理员';

  @override
  String get permissionTestSubtitle => '测试应用权限';

  @override
  String get permissionTestTitle => '权限测试';

  @override
  String get phoneNumber => '手机号';

  @override
  String get phoneStorageTab => '手机存储';

  @override
  String get pickFromGallery => '从相册选择';

  @override
  String pickImageFailed(String error) {
    return '选择图片失败: $error';
  }

  @override
  String get pingPongAutoClipSubtitle => '乒乓球比赛视频自动剪辑';

  @override
  String get pingPongMatchVideoClip => '乒乓球比赛视频剪辑';

  @override
  String get pingPongVideoAutoClip => '乒乓球视频自动剪辑';

  @override
  String get platformLabel => '平台';

  @override
  String playSegmentFailedWithError(String error) {
    return '播放片段失败: $error';
  }

  @override
  String get playSelectedSegmentOnly => '只播放片段';

  @override
  String get playSpeed => '播放速度';

  @override
  String get playVideo => '播放视频';

  @override
  String get playbackItemNotFound => '播放项不存在';

  @override
  String get playingNow => '▶ 播放中';

  @override
  String get pleaseEnterDescription => '请输入详细描述';

  @override
  String get pleaseEnterTitle => '请输入标题';

  @override
  String get pleaseSelectGender => '请选择性别';

  @override
  String get points => '积分';

  @override
  String get popular => '热门';

  @override
  String get precisionEditButton => '✎ 精修编辑';

  @override
  String get precisionEditTitle => '精修编辑';

  @override
  String get prepareDownload => '准备下载';

  @override
  String prepareVideoFailed(String error) {
    return '准备视频失败：$error';
  }

  @override
  String get presetComingSoon => '预设功能即将推出';

  @override
  String get previewTitle => '预览';

  @override
  String processDetectionResultFailed(String error) {
    return '处理检测结果失败: $error';
  }

  @override
  String get processFailedRetry => '处理失败，请重试';

  @override
  String get processStatusPreparing => '准备中';

  @override
  String get processVideoFailed => '处理视频失败';

  @override
  String processedTimeLabel(int seconds) {
    return '已处理时间：$seconds s';
  }

  @override
  String get processingEffectLabel => '处理效果';

  @override
  String get processingHistory => '处理记录';

  @override
  String get processingNow => '正在处理';

  @override
  String processingSpeed(String speed) {
    return '处理速度: $speed 秒/分钟';
  }

  @override
  String processingSpeedPerSecond(String speed) {
    return '处理速度：$speed s/s';
  }

  @override
  String get productNameLabel => '产品名称';

  @override
  String get profileDefaultUsername => '用户名';

  @override
  String progressPercentLabel(String percent) {
    return '进度: $percent%';
  }

  @override
  String get progressTaskCancelled => '任务已取消';

  @override
  String get progressTaskCompleted => '任务完成';

  @override
  String get purchase => '购买';

  @override
  String get purchaseConfirm => '购买确认';

  @override
  String purchaseConfirmMessage(String packageName, int minutes, String price) {
    return '确定要购买 $packageName 吗？\n时长：$minutes分钟\n价格：¥$price';
  }

  @override
  String get purchaseFeatureInDevelopment => '购买功能开发中...';

  @override
  String get qqGroup => 'QQ 群';

  @override
  String get qqGroupCopied => 'QQ 群号已复制';

  @override
  String get qualityLabel => '清晰度';

  @override
  String queuePosition(String position) {
    return '队列位置: $position';
  }

  @override
  String get quickAccessCamera => '相机';

  @override
  String get quickAccessDocuments => '文档';

  @override
  String get quickAccessDownload => '下载';

  @override
  String get quickAccessPictures => '图片';

  @override
  String get quickAccessVideos => '视频';

  @override
  String get quickTry => '快速体验';

  @override
  String get quickTryHint => '无需自备视频，使用内置样例立即体验剪辑流程';

  @override
  String readLogContentFailed(String error) {
    return '读取日志内容失败: $error';
  }

  @override
  String get realtimeDetecting => '实时检测中';

  @override
  String get recommended => '推荐';

  @override
  String get recordAndClip => '边拍边剪辑';

  @override
  String get recordAndClipCloud => '边拍边剪(云端)';

  @override
  String get recordAndClipDescription => '使用摄像头实时录制视频，同时进行片段标记和剪辑';

  @override
  String get recordAndClipLocal => '边拍边剪(本地)';

  @override
  String get recordAndClipMode => '边拍边剪辑模式';

  @override
  String get recordAndClipRealtimeDetection => '边拍边剪辑实时检测';

  @override
  String get recordAndClipSubtitle => '实时录制并剪辑视频';

  @override
  String get recordDetailTitle => '记录详情';

  @override
  String get refreshStatus => '刷新状态';

  @override
  String get registryOwnerLabel => '注册表所有者';

  @override
  String get remainingDuration => '剩余时长';

  @override
  String remark(String info) {
    return '备注: $info';
  }

  @override
  String get remarkInfoSection => '备注信息';

  @override
  String get removeFromFavorites => '从收藏中移除';

  @override
  String get removeReplay => '移除回放';

  @override
  String get removeReplayHelp => '自动跳过回放片段';

  @override
  String get removeReplayTooltipPro => '一般专业比赛才有，例如wtt中的回放';

  @override
  String get removeReplayTooltipShort => '一般专业比赛才有';

  @override
  String get renameFileTitle => '重命名文件';

  @override
  String get renameSucceeded => '重命名成功';

  @override
  String get renew => '续费';

  @override
  String reorderFailedWithError(String error) {
    return '重新排序失败: $error';
  }

  @override
  String get reprocessButton => '重新处理';

  @override
  String get requestAllPermissions => '请求所有权限';

  @override
  String get requestPermission => '请求权限';

  @override
  String requestPermissionError(String error) {
    return '请求权限时发生错误: $error';
  }

  @override
  String requestPermissionTitle(String permissionName) {
    return '请求 $permissionName';
  }

  @override
  String get reserveAfterRound => '单回合后保留时长(秒)';

  @override
  String get reserveAfterRoundTooltip => '单回合比赛结束后预留的时间（秒）';

  @override
  String get reserveBeforeRound => '单回合前保留时间';

  @override
  String get reserveBeforeRoundTooltip => '单回合比赛开始前预留的时间（秒）';

  @override
  String get resetAppConfirmMessage => '这将清除所有应用数据，包括设置、缓存和用户数据。此操作不可撤销。';

  @override
  String get resetAppSubtitle => '清除所有应用数据';

  @override
  String get resetAppTitle => '重置应用';

  @override
  String get resumeTask => '恢复任务';

  @override
  String retryFailed(String error) {
    return '重试失败: $error';
  }

  @override
  String get returnToHome => '返回首页';

  @override
  String get roundClip => '回合剪辑';

  @override
  String roundCountBadge(int count) {
    return '$count 个';
  }

  @override
  String roundCountDurationSummary(int count, String duration) {
    return '$count 个 · 合计 $duration';
  }

  @override
  String get roundCountLabel => '回合数';

  @override
  String roundCountShort(int count) {
    return '$count个回合';
  }

  @override
  String get roundCountUnit => '个回合';

  @override
  String get roundDeletedSuccess => '已删除当前回合';

  @override
  String get roundFavoritedSuccess => '已收藏当前回合';

  @override
  String get roundList => '回合列表';

  @override
  String get roundOrder => '回合顺序';

  @override
  String get roundTransitionLabel => '回合间转场';

  @override
  String get roundUnfavoritedSuccess => '已取消收藏当前回合';

  @override
  String get saveAll => '保存全部';

  @override
  String get saveAsPreset => '保存当前为预设';

  @override
  String get saveCleaningTempFiles => '正在清理临时文件...';

  @override
  String get saveComplete => '保存完成！';

  @override
  String saveFailed(String error) {
    return '保存失败: $error';
  }

  @override
  String get saveFailedShort => '保存失败';

  @override
  String get saveLocationLabel => '保存位置:';

  @override
  String get saveMergingSegments => '正在合并视频片段...';

  @override
  String get savePreparing => '准备保存...';

  @override
  String get savePreparingInProgress => '正在准备保存...';

  @override
  String get saveProcessingSegmentsStart => '开始处理视频片段...';

  @override
  String get saveProgressTitle => '保存进度';

  @override
  String get saveSavingMetadata => '正在保存元数据...';

  @override
  String get saveSavingToGallery => '正在保存到相册...';

  @override
  String saveSegmentFailedWithError(String error) {
    return '保存片段失败: $error';
  }

  @override
  String get saveToGallery => '保存到相册';

  @override
  String get saveToLabel => '保存到';

  @override
  String get saveTrimmingSegment => '正在裁剪片段';

  @override
  String get saveTrimmingSegments => '正在裁剪视频片段...';

  @override
  String saveTrimmingSegmentsProgress(String percent) {
    return '正在裁剪视频片段... $percent%';
  }

  @override
  String savedImagesCount(int count) {
    return '成功保存 $count 张图片到相册';
  }

  @override
  String get savedToGallery => '已保存到相册';

  @override
  String screenshotCaptureFailedWithLogs(String logs) {
    return '截图失败: $logs';
  }

  @override
  String get screenshotCapturing => '正在截图...';

  @override
  String get screenshotCompleted => '截图完成';

  @override
  String get screenshotFailedTitle => '截图失败';

  @override
  String get screenshotFileNotGenerated => '截图文件未生成';

  @override
  String get screenshotGeneratingImage => '正在生成图片...';

  @override
  String get screenshotPrepare => '准备截图...';

  @override
  String get screenshotProgressTitle => '截图进度';

  @override
  String get screenshotSavingToGallery => '正在保存到相册...';

  @override
  String get sdkVersionLabel => 'SDK版本';

  @override
  String searchFailedWithError(String error) {
    return '搜索失败: $error';
  }

  @override
  String get searchFilesTitle => '搜索文件';

  @override
  String get searchLogsHint => '搜索日志...';

  @override
  String get searchMediaTitle => '搜索媒体文件';

  @override
  String get searchPathDcim => 'DCIM相机';

  @override
  String get searchPathDocuments => '文档文件夹';

  @override
  String get searchPathDownload => '下载文件夹';

  @override
  String get searchPathEntireStorage => '整个存储';

  @override
  String get searchPathMovies => '视频文件夹';

  @override
  String get searchPathMusic => '音乐文件夹';

  @override
  String get searchPathPictures => '图片文件夹';

  @override
  String searchResultsAdded(int count) {
    return '已添加 $count 个搜索结果到选择列表';
  }

  @override
  String get searchScope => '搜索范围';

  @override
  String get searching => '搜索中...';

  @override
  String get searchingFiles => '正在搜索文件...';

  @override
  String get securitySettings => '安全设置';

  @override
  String get seekBackward1s => '-1秒';

  @override
  String get seekBackward5s => '-5秒';

  @override
  String get seekForward1s => '+1秒';

  @override
  String get seekForward5s => '+5秒';

  @override
  String get segmentNotFound => '找不到对应的片段';

  @override
  String segmentsDetectedResult(int count, int seconds) {
    return '检测到 $count 个比赛片段 (${seconds}s)';
  }

  @override
  String get selectAlbum => '选择相册';

  @override
  String get selectAll => '全选';

  @override
  String get selectAction => '选择';

  @override
  String get selectClipMode => '选择剪辑方式';

  @override
  String get selectClipModeHint => '请选择您想要的剪辑方式';

  @override
  String get selectDirectoryPrompt => '请选择目录';

  @override
  String get selectDirectoryTitle => '选择目录';

  @override
  String get selectExportQualityTitle => '选择导出质量';

  @override
  String get selectFiles => '选择文件';

  @override
  String get selectFilesAndDirectoriesTitle => '选择文件和目录';

  @override
  String get selectFilesOrDirectoriesPrompt => '请选择文件或目录';

  @override
  String get selectFilesPrompt => '请选择文件';

  @override
  String get selectFilesTitle => '选择文件';

  @override
  String selectionPromptForType(String mediaType) {
    return '请选择$mediaType文件';
  }

  @override
  String get selectGender => '选择性别';

  @override
  String get selectImagesTitle => '选择图片';

  @override
  String get selectMediaTitle => '选择媒体文件';

  @override
  String get selectRoundFromLeft => '请从左侧选择一个回合';

  @override
  String get selectSportType => '选择运动类型';

  @override
  String get selectSportTypeHint => '请选择您要剪辑的视频运动类型';

  @override
  String get selectThisDirectory => '选择此目录';

  @override
  String get selectTimeRange => '选择时间范围';

  @override
  String get selectVideoFileFirst => '请先选择视频文件';

  @override
  String get selectVideoFileFirstError => '请先选择视频文件';

  @override
  String get selectVideosTitle => '选择视频';

  @override
  String selectedCountShort(int count) {
    return '已选: $count';
  }

  @override
  String selectedFirstNItems(int count) {
    return '已选择前 $count 个项目';
  }

  @override
  String selectedItemsCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String get selectedRounds => '已选回合';

  @override
  String selectionSummaryDirsOnly(String dirCount) {
    return ' ($dirCount个目录)';
  }

  @override
  String selectionSummaryFilesAndDirs(String fileCount, String dirCount) {
    return ' ($fileCount个文件, $dirCount个目录)';
  }

  @override
  String selectionSummaryFilesOnly(String fileCount) {
    return ' ($fileCount个文件)';
  }

  @override
  String selectionSummaryItems(int count) {
    return '已选择$count个项目';
  }

  @override
  String get settings => '设置';

  @override
  String get settingsAllDownloadFiles => '所有下载文件';

  @override
  String get settingsAllFilesCleanupDone => '全部文件清理完成';

  @override
  String settingsAllFilesCleanupFailed(String error) {
    return '全部文件清理失败: $error';
  }

  @override
  String get settingsAlreadyLatestVersion => '当前已是最新版本';

  @override
  String get settingsApiServer => 'API 服务器';

  @override
  String get settingsApiServerDefault => '默认';

  @override
  String get settingsApiServerDesc => '选择连接的 API 环境';

  @override
  String get settingsApiServerSandbox => 'Sandbox';

  @override
  String get settingsAppData => '应用数据';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsCacheCleanupDone => '缓存文件清理完成';

  @override
  String settingsCacheCleanupFailed(String error) {
    return '缓存文件清理失败: $error';
  }

  @override
  String get settingsCacheFiles => '缓存文件';

  @override
  String get settingsCheckUpdate => '检查更新';

  @override
  String get settingsCheckUpdateOnStart => '启动时检查更新';

  @override
  String get settingsCheckUpdateOnStartDesc => '应用启动时自动检查新版本';

  @override
  String get settingsChooseCleanupContent => '选择要清理的内容：';

  @override
  String get settingsChooseLanguage => '选择语言';

  @override
  String get settingsCleanupAll => '全部清理';

  @override
  String get settingsClearAll => '清空全部';

  @override
  String get settingsClearCache => '清理缓存';

  @override
  String get settingsConfirmCleanup => '确认清理';

  @override
  String get settingsConfirmCleanupAction => '确定清理';

  @override
  String settingsConfirmCleanupMessage(String title) {
    return '确定要清理$title吗？此操作不可撤销。';
  }

  @override
  String get settingsConfirmDeleteAction => '确定删除';

  @override
  String settingsConfirmDeleteFileMessage(String fileName) {
    return '确定要删除文件 \"$fileName\" 吗？此操作不可撤销。';
  }

  @override
  String get settingsDarkMode => '深色模式';

  @override
  String get settingsDefaultSavePath => '默认保存路径';

  @override
  String get settingsDefaultSavePathValue => '~/Videos/弧迹';

  @override
  String get settingsDownloadCleanupDone => '下载文件清理完成';

  @override
  String settingsDownloadCleanupFailed(String error) {
    return '下载文件清理失败: $error';
  }

  @override
  String get settingsDownloadConcurrency => '下载并发数';

  @override
  String get settingsDownloadConcurrencyDesc => '同时下载的视频数量';

  @override
  String get settingsDownloadFileList => '下载文件列表';

  @override
  String get settingsDownloadFiles => '下载文件';

  @override
  String settingsDownloadListFailed(String error) {
    return '获取下载文件列表失败: $error';
  }

  @override
  String get settingsExternalStorage => '外部存储';

  @override
  String settingsFileDeleteFailed(String error) {
    return '文件删除失败: $error';
  }

  @override
  String get settingsFileDeleteSuccess => '文件删除成功';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageUpdated => '语言设置已更新';

  @override
  String get settingsNoDownloadFiles => '暂无下载文件';

  @override
  String get settingsNotificationsUpdated => '通知设置已更新';

  @override
  String get settingsPageSubtitle => '个性化你的弧迹桌面体验';

  @override
  String get settingsPermissions => '权限管理';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsPushNotifications => '推送通知';

  @override
  String get settingsSendUsageStats => '发送使用统计';

  @override
  String get settingsSendUsageStatsDesc => '匿名发送使用数据以帮助我们改进应用';

  @override
  String get settingsStorage => '存储空间';

  @override
  String get settingsThemeChanged => '主题切换成功';

  @override
  String get settingsTitle => '设置';

  @override
  String settingsTotalUsedSpace(String size) {
    return '总使用空间: $size';
  }

  @override
  String get settingsUserAgreement => '用户协议';

  @override
  String get settingsUsername => '用户名';

  @override
  String get settingsVersionInfo => '版本信息';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsAboutBack => '返回关于';

  @override
  String get settingsAppVersion => '应用版本';

  @override
  String get settingsViewDeviceInfo => '查看设备信息';

  @override
  String get settingsViewChangelog => '查看更新日志';

  @override
  String get settingsViewDownloadFiles => '查看下载文件';

  @override
  String get setupLater => '稍后设置';

  @override
  String get shareFeatureInDevelopment => '分享功能开发中...';

  @override
  String shareLogsFailed(String error) {
    return '分享日志失败: $error';
  }

  @override
  String get shortcutsCategoryEditing => '剪辑';

  @override
  String get shortcutsCategoryMeta => '通用';

  @override
  String get shortcutsCategoryNavigation => '导航';

  @override
  String get shortcutsCategoryPlayback => '播放';

  @override
  String get shortcutsCategoryView => '视图';

  @override
  String get shortcutsChange => '修改';

  @override
  String shortcutsCheatsheetSubtitle(String chord) {
    return '随时按 $chord 打开此列表';
  }

  @override
  String get shortcutsCommandCloseOrBack => '关闭 / 返回';

  @override
  String get shortcutsCommandNewClip => '新建剪辑';

  @override
  String get shortcutsCommandOpenSettings => '打开设置';

  @override
  String get shortcutsCommandOpenTasks => '打开任务';

  @override
  String get shortcutsCommandShowCheatsheet => '显示键盘快捷键';

  @override
  String get shortcutsCommandToggleSidebar => '切换侧栏';

  @override
  String get shortcutsCommandPlaybackPlayPause => '播放 / 暂停';

  @override
  String get shortcutsCommandPlaybackSeekBackward => '后退';

  @override
  String get shortcutsCommandPlaybackSeekForward => '前进';

  @override
  String get shortcutsCommandPlaybackPrevSegment => '上一段';

  @override
  String get shortcutsCommandPlaybackNextSegment => '下一段';

  @override
  String get shortcutsCommandPrecisionPlayPause => '播放 / 暂停';

  @override
  String get shortcutsCommandPrecisionSplit => '在当前位置分割';

  @override
  String get shortcutsCommandPrecisionAddSegment => '添加片段';

  @override
  String get shortcutsCommandPrecisionDeleteSegment => '删除片段';

  @override
  String get shortcutsCommandPrecisionPlaySelectedOnly => '仅播放选中片段';

  @override
  String get shortcutsCommandPrecisionToggleSlowMotion => '切换慢放';

  @override
  String get shortcutsCommandPrecisionPrevRound => '上一个回合';

  @override
  String get shortcutsCommandPrecisionNextRound => '下一个回合';

  @override
  String get shortcutsCommandPrecisionSeekBackward => '后退 0.1 秒（长按加速）';

  @override
  String get shortcutsCommandPrecisionSeekForward => '前进 0.1 秒（长按加速）';

  @override
  String get shortcutsConflictTooltip => '与其他命令冲突';

  @override
  String get shortcutsExport => '导出';

  @override
  String get shortcutsExportFailed => '导出快捷键失败';

  @override
  String get shortcutsExportSuccess => '快捷键已导出';

  @override
  String get shortcutsImport => '导入';

  @override
  String shortcutsImportConflictMessage(int count) {
    return '有 $count 个导入的键位与现有命令冲突,要替换吗?';
  }

  @override
  String get shortcutsImportConflictTitle => '检测到冲突';

  @override
  String get shortcutsImportInvalidFile => '无效的快捷键文件';

  @override
  String get shortcutsImportSuccess => '快捷键已导入';

  @override
  String get shortcutsNotSet => '未设置';

  @override
  String get shortcutsPressNewChord => '按下新的组合键';

  @override
  String get shortcutsPressNewChordHint => '按 Esc 取消 · Backspace 清除';

  @override
  String get shortcutsRebind => '更改快捷键';

  @override
  String get shortcutsReplaceAction => '全部替换';

  @override
  String get shortcutsReplaceCancel => '保留当前';

  @override
  String shortcutsReplaceConfirmBody(String chord, String command) {
    return '$chord 已被「$command」使用,要替换吗?';
  }

  @override
  String get shortcutsReplaceConfirmTitle => '替换快捷键?';

  @override
  String get shortcutsReplaceProceed => '替换';

  @override
  String get shortcutsReset => '恢复默认';

  @override
  String get shortcutsResetAll => '恢复全部默认';

  @override
  String get shortcutsResetAllConfirmBody => '所有自定义快捷键将恢复为默认键位。';

  @override
  String get shortcutsResetAllConfirmTitle => '恢复全部默认?';

  @override
  String get shortcutsSearchHint => '搜索快捷键';

  @override
  String get shortcutsSectionSubtitle => '查看与自定义键盘快捷键';

  @override
  String get shortcutsSectionTitle => '键盘快捷键';

  @override
  String get shortcutsUnbind => '清除绑定';

  @override
  String get shortcutsViewCheatsheet => '查看全部快捷键';

  @override
  String get showSystemLogsLabel => '显示系统日志';

  @override
  String get sidebarOpenTabsSection => '打开的页面';

  @override
  String get workspaceNoOpenTabs => '没有打开的页面';

  @override
  String get sidebarProcessingSection => '正在处理';

  @override
  String get sizeReducedLabel => '大小减少';

  @override
  String get slowMotion => '慢放';

  @override
  String softwareEncoderDetectFailed(String error) {
    return '软件编码器检测失败: $error';
  }

  @override
  String get softwareEncoderNotFound => '未找到合适的软件编码器';

  @override
  String get sortByFileSize => '按文件大小排序';

  @override
  String get sortByFileType => '按文件类型排序';

  @override
  String get sortByModifiedTime => '按修改时间排序';

  @override
  String get sortByName => '按名称排序';

  @override
  String get sortOptionsTitle => '排序方式';

  @override
  String get sourceLocal => '本地';

  @override
  String get sourceNetwork => '网络';

  @override
  String get splashInitializing => '正在初始化...';

  @override
  String get splashTagline => '乒乓球羽毛球比赛视频剪辑';

  @override
  String get sportBadminton => '羽毛球';

  @override
  String get sportClipDescription => '支持单打、双打比赛，自动识别精彩球片段';

  @override
  String get sportPingPong => '乒乓球';

  @override
  String get sportTypeBadminton => '羽毛球';

  @override
  String get sportTypePingpong => '乒乓球';

  @override
  String get startDateLabel => '开始日期';

  @override
  String get startDetectionClip => '开始检测剪辑';

  @override
  String get startDownload => '开始下载...';

  @override
  String get startExport => '开始导出';

  @override
  String get startFrameMustBeLessThanEnd => '起始帧必须小于结束帧';

  @override
  String get startTimeCannotBeNegative => '开始时间不能小于0';

  @override
  String get statusCompleted => '已完成';

  @override
  String get statusFailed => '失败';

  @override
  String get statusPreparing => '准备中';

  @override
  String get statusProcessing => '处理中';

  @override
  String storageCategoryWithSize(String label, String size) {
    return '$label: $size';
  }

  @override
  String get storageInfoCalculating => '正在计算存储信息...';

  @override
  String storageInfoFetchFailedWithError(String error) {
    return '无法获取存储信息: $error';
  }

  @override
  String get storagePermissionRequired => '需要存储权限才能访问文件';

  @override
  String storageSummary(Object fileCount, Object folderCount) {
    return '$folderCount个文件夹，$fileCount个项目';
  }

  @override
  String get submitFailedRetryLater => '提交失败，请稍后重试';

  @override
  String get submitFeedback => '提交反馈';

  @override
  String get subscribe => '订阅';

  @override
  String get subscriptionConfirm => '订阅确认';

  @override
  String subscriptionConfirmMessage(String planName, String price) {
    return '确定要订阅 $planName 方案吗？\n月费：¥$price';
  }

  @override
  String subscriptionFailed(String error) {
    return '订阅失败: $error';
  }

  @override
  String get subscriptionPlans => '订阅方案';

  @override
  String subscriptionSuccess(String planName) {
    return '成功订阅 $planName 方案！';
  }

  @override
  String get supportedVideoFormats => '支持常见视频格式';

  @override
  String get switchTabClearSelectionMessage => '切换到其他标签会清空当前选择，是否继续？';

  @override
  String get switchTabTitle => '切换标签';

  @override
  String get switchToGridMode => '切换为宫格模式';

  @override
  String get switchToListMode => '切换为列表模式';

  @override
  String get systemInfoSubtitle => '查看系统详细信息';

  @override
  String get systemInfoTitle => '系统信息';

  @override
  String get systemNameLabel => '系统名称';

  @override
  String get systemVersionLabel => '系统版本';

  @override
  String get tabFiles => '文件';

  @override
  String get tabPhotoGallery => '相册';

  @override
  String get takePhoto => '拍照';

  @override
  String taskCancelled(String taskName) {
    return '已取消任务\"$taskName\"';
  }

  @override
  String taskDeleted(String taskName) {
    return '已删除任务\"$taskName\"';
  }

  @override
  String taskPauseNotSupported(String taskType) {
    return '$taskType任务不支持暂停';
  }

  @override
  String taskPauseNotSupportedWithCancel(String taskType) {
    return '$taskType任务不支持暂停，请使用取消按钮';
  }

  @override
  String taskPaused(String taskName) {
    return '已暂停任务\"$taskName\"';
  }

  @override
  String get taskPhaseAnalyzing => '正在分析视频内容…';

  @override
  String get taskPhaseClipping => '正在剪辑视频…';

  @override
  String get taskPhaseDownloading => '正在下载结果…';

  @override
  String get taskPhaseFailed => '处理失败';

  @override
  String get taskPhaseGenerating => '正在生成最终视频…';

  @override
  String get taskPhasePaused => '已暂停';

  @override
  String get taskPhasePending => '任务已提交，等待处理…';

  @override
  String get taskPhaseProcessing => '正在处理…';

  @override
  String get taskPhaseUploading => '正在上传视频…';

  @override
  String get taskRecords => '任务记录';

  @override
  String taskResumed(String taskName) {
    return '已恢复任务\"$taskName\"';
  }

  @override
  String get taskStatusCancelled => '已取消';

  @override
  String get taskStatusCancelledShort => '取消';

  @override
  String get taskStatusCompleted => '已完成';

  @override
  String get taskStatusFailed => '失败';

  @override
  String get taskStatusFilter => '任务状态';

  @override
  String get taskStatusInProgress => '进行中';

  @override
  String get taskStatusPaused => '暂停';

  @override
  String get taskStatusPending => '等待中';

  @override
  String get taskStatusProcessing => '处理中';

  @override
  String get taskSubmittedWaiting => '任务已提交，等待处理...';

  @override
  String get taskTypeDownload => '文件下载';

  @override
  String get taskTypeFilter => '任务类型';

  @override
  String taskTypeFilterSelected(int count) {
    return '任务类型 · $count';
  }

  @override
  String get taskTypeImageCompress => '图片压缩';

  @override
  String get taskTypeSegmentDetectShort => '实时检测';

  @override
  String get taskTypeVideoClip => '视频剪辑';

  @override
  String get taskTypeVideoCompress => '视频压缩';

  @override
  String get taskTypeVideoExport => '视频导出';

  @override
  String get taskTypeVideoSegmentDetect => '实时视频片段检测';

  @override
  String get taskTypeVideoUpload => '视频上传';

  @override
  String tasksSubmitted(int successCount, String failSuffix) {
    return '已提交 $successCount 个任务$failSuffix';
  }

  @override
  String tasksSubmittedFailSuffix(int failCount) {
    return '，$failCount 个失败';
  }

  @override
  String get testEnvironmentSubtitle => '测试环境';

  @override
  String get testPageAccessSubtitle => '访问测试页面';

  @override
  String get testPageForFeaturesSubtitle => '用于测试各种功能';

  @override
  String get testPageTitle => '测试页';

  @override
  String get themeColorPresetDescription => '用于按钮、开关与高亮的主色与强调色';

  @override
  String get themeColorPresetTitle => '主题色';

  @override
  String get themeDark => '深色';

  @override
  String get themeLight => '浅色';

  @override
  String get themeModeDark => '深色';

  @override
  String get themeModeDescription => '选择默认外观，或跟随系统设置';

  @override
  String get themeModeLight => '浅色';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get themeModeTitle => '主题模式';

  @override
  String get themePresetAmber => '琥珀';

  @override
  String get themePresetForest => '森林';

  @override
  String get themePresetGraphite => '石墨';

  @override
  String get themePresetOcean => '海洋';

  @override
  String get themePresetViolet => '紫罗兰';

  @override
  String get themeSystem => '跟随系统';

  @override
  String thumbnailFileNotGenerated(String path) {
    return '缩略图文件生成失败: $path';
  }

  @override
  String thumbnailGenerateFailed(String path, String error) {
    return '生成缩略图失败: $path: $error';
  }

  @override
  String thumbnailGenerationFailed(String detail) {
    return '生成缩略图失败: $detail';
  }

  @override
  String get timeRangeFilter => '时间范围';

  @override
  String get totalDurationLabel => '合计时长';

  @override
  String get totalUsage => '总使用';

  @override
  String get trainingPreset => '训练赛配置';

  @override
  String get transitionCrossfade => '交叉淡化';

  @override
  String get transitionNone => '无（直接拼接）';

  @override
  String get transitionSlide => '滑动';

  @override
  String get trimSplitLabel => '分割';

  @override
  String get tryModifySearchConditions => '尝试修改搜索条件';

  @override
  String get typographyScaleComfortable => '宽松';

  @override
  String get typographyScaleCompact => '紧凑';

  @override
  String get typographyScaleCustom => '自定义';

  @override
  String get typographyScaleCustomHint => '50–200';

  @override
  String get typographyScaleDescription => '界面文字大小。「标准」跟随系统';

  @override
  String get typographyScaleStandard => '标准';

  @override
  String get typographyScaleTitle => '文字大小';

  @override
  String get uiZoomDescription => '整体缩放界面——文字、图标与间距一起';

  @override
  String get uiZoomTitle => '界面缩放';

  @override
  String get unfavorite => '取消收藏';

  @override
  String get unfavoriteCurrentRound => '取消收藏当前回合';

  @override
  String get unknownDevice => '未知设备';

  @override
  String get unknownError => '未知错误';

  @override
  String get unknownFile => '未知文件';

  @override
  String get unknownLabel => '未知';

  @override
  String get unknownPlatform => '未知平台';

  @override
  String get unlimited => '无限';

  @override
  String get untitledName => '未命名';

  @override
  String get updateContent => '更新内容';

  @override
  String get updateLater => '以后更新';

  @override
  String updatePlaybackListFailedWithError(String error) {
    return '更新播放项列表失败: $error';
  }

  @override
  String get updateTime => '更新时间';

  @override
  String get uploadVideoHint => '上传你收集的视频，自动裁剪掉休息片段。视频处理期间可离开页面，处理完后会有桌面通知。';

  @override
  String get uploading => '上传中...';

  @override
  String get uploadingVideo => '正在上传视频...';

  @override
  String get useDemoVideo => '或使用演示视频';

  @override
  String get used => '已使用';

  @override
  String get usedDuration => '已使用';

  @override
  String get userNameLabel => '用户名';

  @override
  String get usernameLabel => '用户名';

  @override
  String validityDays(int days) {
    return '$days天';
  }

  @override
  String get versionCodenameLabel => '版本代号';

  @override
  String get versionIdLabel => '版本ID';

  @override
  String get versionInfo => '版本信息';

  @override
  String get versionNumber => '版本号';

  @override
  String get videoClipProgressTitle => '视频剪辑进度';

  @override
  String get videoComparisonSection => '视频对比';

  @override
  String videoCompressException(String error) {
    return '压缩异常: $error';
  }

  @override
  String videoCompressFailed(String logs) {
    return '压缩失败: $logs';
  }

  @override
  String get videoCompressInfoUnavailable => '无法获取视频信息';

  @override
  String videoCompressInputNotFound(String path) {
    return '输入文件不存在: $path';
  }

  @override
  String get videoCompressOutputNotGenerated => '输出文件未生成';

  @override
  String get videoCropFailed => '视频裁剪失败';

  @override
  String videoDuration(String duration) {
    return '视频时长: $duration';
  }

  @override
  String videoDurationAndSize(String duration, String size) {
    return '时长: $duration | 大小: $size';
  }

  @override
  String videoDurationSeconds(int seconds) {
    return '视频时长：$seconds s';
  }

  @override
  String get videoEditTitle => '视频编辑';

  @override
  String videoExpiresAt(String date, String timeAgo) {
    return '$date | $timeAgo过期';
  }

  @override
  String get videoFileLabel => '视频文件';

  @override
  String get videoFileNotExist => '视频文件不存在';

  @override
  String videoFileNotFound(String path) {
    return '视频文件不存在: $path';
  }

  @override
  String videoFileNotFoundWithPath(String path) {
    return '视频文件不存在: $path';
  }

  @override
  String get videoFileNotGenerated => '视频文件未生成';

  @override
  String get videoFormatConvertFailed => '视频格式转换失败';

  @override
  String videoInfoFetchFailed(String output) {
    return '获取视频信息失败: $output';
  }

  @override
  String get videoLabel => '视频';

  @override
  String get videoListTitle => '视频列表';

  @override
  String get videoLoading => '视频加载中...';

  @override
  String get videoMergeFailed => '视频合并失败';

  @override
  String get videoNameLabel => '视频名称';

  @override
  String get videoPathEmpty => '视频文件路径为空';

  @override
  String videoPlayerFileMovedOrDeleted(String path) {
    return '文件已被移动或删除：\n$path';
  }

  @override
  String get videoPlayerFileNotFound => '文件不存在';

  @override
  String videoPlayerInitFailed(String error) {
    return '初始化播放器失败: $error';
  }

  @override
  String get videoPlayerInitializing => '正在初始化播放器...';

  @override
  String get videoPlayerLoadingVideo => '正在加载视频...';

  @override
  String videoPlayerNetworkInitFailed(String error) {
    return '初始化网络播放器失败: $error';
  }

  @override
  String get videoProcessType => '视频处理类型';

  @override
  String get videoProcessTypeAllMatchMerged => '全部回合';

  @override
  String get videoProcessTypeGreatMatch => '精彩回合';

  @override
  String get videoProcessTypeRaw => '原视频';

  @override
  String get videoProcessTypeCompressed => '压缩视频';

  @override
  String get videoProcessTypeExported => '导出视频';

  @override
  String get videoProcessingComplete => '视频处理完成';

  @override
  String get videoProcessingCompletedViewOutput => '视频处理完成，可以查看输出视频';

  @override
  String get videoProcessingInProgress => '视频处理中...';

  @override
  String get videoProcessingProgress => '视频处理进度';

  @override
  String get videoQualityWarning =>
      '视频的角度、大小、分辨率会影响检测效果。建议水平拍摄，分辨率 ≥ 720p，不要过度压缩。';

  @override
  String get videoSaveFailed => '视频保存失败';

  @override
  String videoSavedTo(String path) {
    return '视频已保存到$path';
  }

  @override
  String get videoScaleFailed => '视频缩放失败';

  @override
  String get videoSegmentDetection => '视频片段检测';

  @override
  String get videoStillProcessingTryLater => '视频还在处理中，请稍后再试';

  @override
  String get videoStreamNotFound => '未找到视频流';

  @override
  String get videoWaitingProcessing => '视频等待处理中...';

  @override
  String videoWaitingWithQueue(int count) {
    return '视频等待处理中...前方有 $count 个视频在排队';
  }

  @override
  String get videosFolderName => '弧迹';

  @override
  String get viewAppLogsSubtitle => '查看应用日志';

  @override
  String get viewChangelogHistory => '查看历史版本';

  @override
  String get viewFromEndLabel => '从尾部查看';

  @override
  String get viewLogsButton => '查看日志';

  @override
  String get viewProgress => '查看进度';

  @override
  String get viewTasks => '查看任务';

  @override
  String get viewVideoButton => '查看视频';

  @override
  String waitingProcessTime(int seconds) {
    return '等待处理时间: $seconds s';
  }

  @override
  String get windowControlAlwaysOnTop => '置顶';

  @override
  String get windowControlClose => '关闭';

  @override
  String get windowControlMaximize => '最大化';

  @override
  String get windowControlMinimize => '最小化';

  @override
  String get windowControlRestore => '还原';

  @override
  String get wrapLinesLabel => '换行显示';
}
