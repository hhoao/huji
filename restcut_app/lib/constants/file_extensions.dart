import 'package:flutter/material.dart';

// ========== 文件类型枚举 ==========
enum FileType {
  image,
  video,
  audio,
  document,
  archive,
  code,
  executable,
  font,
  model,
  database,
  config,
  unknown,
}

/// 文件扩展名管理器
/// 统一管理所有文件类型的扩展名、图标、分类等信息
class FileExtensions {
  // ========== 图片文件扩展名 ==========
  static const Set<String> imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.bmp',
    '.webp',
    '.svg',
    '.ico',
    '.tiff',
    '.tif',
    '.heic',
    '.heif',
    '.raw',
    '.cr2',
    '.nef',
    '.arw',
  };

  // ========== 视频文件扩展名 ==========
  static const Set<String> videoExtensions = {
    '.mp4',
    '.avi',
    '.mov',
    '.mkv',
    '.webm',
    '.3gp',
    '.flv',
    '.wmv',
    '.m4v',
    '.mpg',
    '.mpeg',
    '.m2v',
    '.mts', // MPEG Transport Stream
    '.m2ts', // MPEG-2 Transport Stream
    '.vob',
    '.asf',
    '.rm',
    '.rmvb',
    '.divx',
    '.xvid',
  };

  // ========== 音频文件扩展名 ==========
  static const Set<String> audioExtensions = {
    '.mp3',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.wma',
    '.m4a',
    '.opus',
    '.amr',
    '.3ga',
    '.ac3',
    '.aiff',
    '.ape',
    '.au',
    '.ra',
    '.mid',
    '.midi',
  };

  // ========== 文档文件扩展名 ==========
  static const Set<String> documentExtensions = {
    '.pdf',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
    '.txt',
    '.rtf',
    '.odt',
    '.ods',
    '.odp',
    '.pages',
    '.numbers',
    '.key',
  };

  // ========== 压缩文件扩展名 ==========
  static const Set<String> archiveExtensions = {
    '.zip',
    '.rar',
    '.7z',
    '.tar',
    '.gz',
    '.bz2',
    '.xz',
    '.tar.gz',
    '.tar.bz2',
    '.tar.xz',
    '.cab',
    '.iso',
  };

  // ========== 代码文件扩展名 ==========
  static const Set<String> codeExtensions = {
    '.dart',
    '.java',
    '.kt',
    '.swift',
    '.js',
    '.ts', // TypeScript
    '.tsx', // TypeScript JSX
    '.html',
    '.css',
    '.scss',
    '.sass',
    '.less',
    '.xml',
    '.json',
    '.py',
    '.cpp',
    '.c',
    '.h',
    '.hpp',
    '.cs',
    '.php',
    '.rb',
    '.go',
    '.rs',
    '.sh',
    '.bat',
    '.ps1',
    '.sql',
    '.md',
    '.markdown',
  };

  // ========== 应用程序文件扩展名 ==========
  static const Set<String> executableExtensions = {
    '.apk',
    '.ipa',
    '.exe',
    '.msi',
    '.app',
    '.dmg',
    '.pkg',
    '.deb',
    '.rpm',
    '.appimage',
    '.flatpak',
    '.snap',
  };

  // ========== 字体文件扩展名 ==========
  static const Set<String> fontExtensions = {
    '.ttf',
    '.otf',
    '.woff',
    '.woff2',
    '.eot',
    '.fon',
    '.pfb',
    '.pfm',
  };

  // ========== 3D模型文件扩展名 ==========
  static const Set<String> modelExtensions = {
    '.obj',
    '.fbx',
    '.dae',
    '.3ds',
    '.blend',
    '.max',
    '.ma',
    '.mb',
    '.c4d',
    '.skp',
    '.ply',
    '.stl',
    '.x3d',
    '.gltf',
    '.glb',
  };

  // ========== 数据库文件扩展名 ==========
  static const Set<String> databaseExtensions = {
    '.db',
    '.sqlite',
    '.sqlite3',
    '.mdb',
    '.accdb',
    '.dbf',
    '.frm',
    '.myd',
    '.myi',
  };

  // ========== 配置文件扩展名 ==========
  static const Set<String> configExtensions = {
    '.ini',
    '.cfg',
    '.conf',
    '.config',
    '.properties',
    '.plist',
    '.toml',
    '.yaml',
    '.yml',
    '.env',
    '.editorconfig',
    '.gitignore',
    '.dockerignore',
  };

  // ========== 所有媒体文件扩展名（图片 + 视频 + 音频）==========
  static const Set<String> allMediaExtensions = {
    ...imageExtensions,
    ...videoExtensions,
    ...audioExtensions,
  };

  // ========== 可视媒体扩展名（图片 + 视频）==========
  static const Set<String> visualMediaExtensions = {
    ...imageExtensions,
    ...videoExtensions,
  };

  // ========== 所有文件扩展名 ==========
  static const Set<String> allExtensions = {
    ...imageExtensions,
    ...videoExtensions,
    ...audioExtensions,
    ...documentExtensions,
    ...archiveExtensions,
    ...codeExtensions,
    ...executableExtensions,
    ...fontExtensions,
    ...modelExtensions,
    ...databaseExtensions,
    ...configExtensions,
  };

  // ========== 判断方法 ==========

  /// 判断文件扩展名是否为图片格式
  static bool isImage(String extension) {
    return imageExtensions.contains(extension.toLowerCase());
  }

  /// 判断文件扩展名是否为视频格式
  static bool isVideo(String extension) {
    return videoExtensions.contains(extension.toLowerCase());
  }

  /// 判断文件扩展名是否为音频格式
  static bool isAudio(String extension) {
    return audioExtensions.contains(extension.toLowerCase());
  }

  /// 判断文件扩展名是否为文档格式
  static bool isDocument(String extension) {
    return documentExtensions.contains(extension.toLowerCase());
  }

  /// 判断文件扩展名是否为压缩格式
  static bool isArchive(String extension) {
    return archiveExtensions.contains(extension.toLowerCase());
  }

  /// 判断文件扩展名是否为代码格式
  static bool isCode(String extension) {
    return codeExtensions.contains(extension.toLowerCase());
  }

  /// 判断文件扩展名是否为可执行程序格式
  static bool isExecutable(String extension) {
    return executableExtensions.contains(extension.toLowerCase());
  }

  /// 判断文件扩展名是否为字体格式
  static bool isFont(String extension) {
    return fontExtensions.contains(extension.toLowerCase());
  }

  /// 判断文件扩展名是否为3D模型格式
  static bool isModel(String extension) {
    return modelExtensions.contains(extension.toLowerCase());
  }

  /// 判断文件扩展名是否为数据库格式
  static bool isDatabase(String extension) {
    return databaseExtensions.contains(extension.toLowerCase());
  }

  /// 判断文件扩展名是否为配置文件格式
  static bool isConfig(String extension) {
    return configExtensions.contains(extension.toLowerCase());
  }

  /// 判断文件扩展名是否为媒体格式
  static bool isMedia(String extension) {
    return allMediaExtensions.contains(extension.toLowerCase());
  }

  /// 获取文件类型
  static FileType getFileType(String extension) {
    final ext = extension.toLowerCase();

    if (isImage(ext)) return FileType.image;
    if (isVideo(ext)) return FileType.video;
    if (isAudio(ext)) return FileType.audio;
    if (isDocument(ext)) return FileType.document;
    if (isArchive(ext)) return FileType.archive;
    if (isCode(ext)) return FileType.code;
    if (isExecutable(ext)) return FileType.executable;
    if (isFont(ext)) return FileType.font;
    if (isModel(ext)) return FileType.model;
    if (isDatabase(ext)) return FileType.database;
    if (isConfig(ext)) return FileType.config;

    return FileType.unknown;
  }

  /// 获取文件类型对应的图标
  static IconData getFileIcon(String fileName) {
    final extension = fileName.contains('.')
        ? '.${fileName.split('.').last.toLowerCase()}'
        : '';

    switch (getFileType(extension)) {
      case FileType.image:
        return Icons.image;
      case FileType.video:
        return Icons.videocam;
      case FileType.audio:
        return Icons.audiotrack;
      case FileType.document:
        return _getDocumentIcon(extension);
      case FileType.archive:
        return Icons.archive;
      case FileType.code:
        return Icons.code;
      case FileType.executable:
        return _getExecutableIcon(extension);
      case FileType.font:
        return Icons.font_download;
      case FileType.model:
        return Icons.view_in_ar;
      case FileType.database:
        return Icons.storage;
      case FileType.config:
        return Icons.settings;
      case FileType.unknown:
        return Icons.insert_drive_file;
    }
  }

  /// 获取文档类型的具体图标
  static IconData _getDocumentIcon(String extension) {
    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
      case '.odt':
      case '.pages':
        return Icons.description;
      case '.xls':
      case '.xlsx':
      case '.ods':
      case '.numbers':
        return Icons.table_chart;
      case '.ppt':
      case '.pptx':
      case '.odp':
      case '.key':
        return Icons.slideshow;
      case '.txt':
      case '.rtf':
        return Icons.text_snippet;
      default:
        return Icons.description;
    }
  }

  /// 获取可执行程序的具体图标
  static IconData _getExecutableIcon(String extension) {
    switch (extension) {
      case '.apk':
        return Icons.android;
      case '.ipa':
        return Icons.phone_iphone;
      case '.exe':
      case '.msi':
        return Icons.computer;
      case '.app':
      case '.dmg':
      case '.pkg':
        return Icons.laptop_mac;
      case '.deb':
      case '.rpm':
      case '.appimage':
      case '.flatpak':
      case '.snap':
        return Icons.memory;
      default:
        return Icons.apps;
    }
  }

  /// 获取文件类型的显示名称
  static String getFileTypeName(String extension) {
    switch (getFileType(extension)) {
      case FileType.image:
        return '图片';
      case FileType.video:
        return '视频';
      case FileType.audio:
        return '音频';
      case FileType.document:
        return '文档';
      case FileType.archive:
        return '压缩包';
      case FileType.code:
        return '代码';
      case FileType.executable:
        return '应用程序';
      case FileType.font:
        return '字体';
      case FileType.model:
        return '3D模型';
      case FileType.database:
        return '数据库';
      case FileType.config:
        return '配置文件';
      case FileType.unknown:
        return '文件';
    }
  }

  /// 获取文件类型的颜色
  static Color getFileTypeColor(String extension) {
    switch (getFileType(extension)) {
      case FileType.image:
        return Colors.green;
      case FileType.video:
        return Colors.red;
      case FileType.audio:
        return Colors.purple;
      case FileType.document:
        return Colors.blue;
      case FileType.archive:
        return Colors.orange;
      case FileType.code:
        return Colors.indigo;
      case FileType.executable:
        return Colors.teal;
      case FileType.font:
        return Colors.pink;
      case FileType.model:
        return Colors.cyan;
      case FileType.database:
        return Colors.brown;
      case FileType.config:
        return Colors.grey;
      case FileType.unknown:
        return Colors.grey;
    }
  }

  // ========== 扩展名列表获取方法（用于文件选择器）==========

  /// 获取图片扩展名列表
  static List<String> get imageExtensionsList => imageExtensions.toList();

  /// 获取视频扩展名列表
  static List<String> get videoExtensionsList => videoExtensions.toList();

  /// 获取音频扩展名列表
  static List<String> get audioExtensionsList => audioExtensions.toList();

  /// 获取文档扩展名列表
  static List<String> get documentExtensionsList => documentExtensions.toList();

  /// 获取压缩文件扩展名列表
  static List<String> get archiveExtensionsList => archiveExtensions.toList();

  /// 获取代码文件扩展名列表
  static List<String> get codeExtensionsList => codeExtensions.toList();

  /// 获取可执行程序扩展名列表
  static List<String> get executableExtensionsList =>
      executableExtensions.toList();

  /// 获取所有媒体扩展名列表
  static List<String> get allMediaExtensionsList => allMediaExtensions.toList();

  /// 获取可视媒体扩展名列表（图片+视频）
  static List<String> get visualMediaExtensionsList =>
      visualMediaExtensions.toList();

  /// 获取所有扩展名列表
  static List<String> get allExtensionsList => allExtensions.toList();
}
