import 'dart:io';

import 'package:flutter/material.dart';
import 'package:huji_app/constants/file_extensions.dart';
import 'package:huji_app/l10n/l10n_extensions.dart';
import 'package:huji_app/widgets/file_picker/huji_file_selection_deps.dart';
import 'package:shared_ui/shared_ui.dart';

enum TabType { fileSystem, photoGallery }

enum SelectionMode { files, directories, both }

/// Thin facade over [showTpFileSelection] preserving the huji public API.
class FileSelection {
  FileSelection._();

  static Future<List<FileSystemEntity>?> show({
    required BuildContext context,
    bool allowMultiple = false,
    List<String>? allowedExtensions,
    String? title,
    int? maxSelectionCount,
    TabType? initialTab = TabType.fileSystem,
    String? initialPath,
    SelectionMode selectionMode = SelectionMode.files,
    bool showHiddenFiles = false,
  }) {
    return _pick(
      context: context,
      allowMultiple: allowMultiple,
      allowedExtensions: allowedExtensions,
      title: title,
      maxSelectionCount: maxSelectionCount,
      initialTab: initialTab,
      initialPath: initialPath,
      selectionMode: selectionMode,
      showHiddenFiles: showHiddenFiles,
    );
  }

  static Future<List<FileSystemEntity>?> selectVideos({
    required BuildContext context,
    bool allowMultiple = true,
    int? maxSelectionCount,
    TabType? initialTab = TabType.photoGallery,
    String? initialPath,
  }) {
    return show(
      context: context,
      allowMultiple: allowMultiple,
      allowedExtensions: FileExtensions.videoExtensionsList,
      title: context.hujiL10n.selectVideosTitle,
      maxSelectionCount: maxSelectionCount,
      initialTab: initialTab,
      initialPath: initialPath,
    );
  }

  static Future<List<FileSystemEntity>?> selectImages({
    required BuildContext context,
    bool allowMultiple = true,
    int? maxSelectionCount,
    TabType? initialTab = TabType.photoGallery,
    String? initialPath,
  }) {
    return show(
      context: context,
      allowMultiple: allowMultiple,
      allowedExtensions: FileExtensions.imageExtensionsList,
      title: context.hujiL10n.selectImagesTitle,
      maxSelectionCount: maxSelectionCount,
      initialTab: initialTab,
      initialPath: initialPath,
    );
  }

  static Future<List<FileSystemEntity>?> selectMedia({
    required BuildContext context,
    bool allowMultiple = true,
    int? maxSelectionCount,
    TabType? initialTab = TabType.photoGallery,
    String? initialPath,
  }) {
    return show(
      context: context,
      allowMultiple: allowMultiple,
      allowedExtensions: FileExtensions.visualMediaExtensionsList,
      title: context.hujiL10n.selectMediaTitle,
      maxSelectionCount: maxSelectionCount,
      initialTab: initialTab,
      initialPath: initialPath,
    );
  }

  static Future<List<FileSystemEntity>?> selectDirectories({
    required BuildContext context,
    bool allowMultiple = false,
    int? maxSelectionCount,
    TabType? initialTab = TabType.fileSystem,
    String? initialPath,
    bool showHiddenFiles = false,
  }) {
    return _pick(
      context: context,
      allowMultiple: allowMultiple,
      title: context.hujiL10n.selectDirectoryTitle,
      maxSelectionCount: maxSelectionCount,
      initialTab: initialTab,
      initialPath: initialPath,
      selectionMode: SelectionMode.directories,
      showHiddenFiles: showHiddenFiles,
    );
  }

  static Future<List<FileSystemEntity>?> selectFilesAndDirectories({
    required BuildContext context,
    bool allowMultiple = true,
    List<String>? allowedExtensions,
    String? title,
    int? maxSelectionCount,
    TabType? initialTab = TabType.fileSystem,
    String? initialPath,
    bool showHiddenFiles = false,
  }) {
    return show(
      context: context,
      allowMultiple: allowMultiple,
      allowedExtensions: allowedExtensions,
      title: title ?? context.hujiL10n.selectFilesAndDirectoriesTitle,
      maxSelectionCount: maxSelectionCount,
      initialTab: initialTab,
      initialPath: initialPath,
      selectionMode: SelectionMode.both,
      showHiddenFiles: showHiddenFiles,
    );
  }

  static Future<List<FileSystemEntity>?> _pick({
    required BuildContext context,
    bool allowMultiple = false,
    List<String>? allowedExtensions,
    String? title,
    int? maxSelectionCount,
    TabType? initialTab,
    String? initialPath,
    SelectionMode selectionMode = SelectionMode.files,
    bool showHiddenFiles = false,
  }) async {
    final entries = await showTpFileSelection(
      context: context,
      deps: hujiFileSelectionDeps(context),
      options: TpFileSelectionOptions(
        allowMultiple: allowMultiple,
        allowedExtensions: allowedExtensions,
        title: title,
        maxSelectionCount: maxSelectionCount,
        initialTab: _mapTab(initialTab),
        initialPath: initialPath,
        selectionMode: _mapSelectionMode(selectionMode),
        showHiddenFiles: showHiddenFiles,
      ),
    );
    return _mapEntries(entries);
  }
}

TpFileSelectionTab? _mapTab(TabType? tab) {
  return switch (tab) {
    TabType.fileSystem => TpFileSelectionTab.filesystem,
    TabType.photoGallery => TpFileSelectionTab.gallery,
    null => null,
  };
}

TpSelectionMode _mapSelectionMode(SelectionMode mode) {
  return switch (mode) {
    SelectionMode.files => TpSelectionMode.files,
    SelectionMode.directories => TpSelectionMode.directories,
    SelectionMode.both => TpSelectionMode.both,
  };
}

List<FileSystemEntity>? _mapEntries(List<TpPickedEntry>? entries) {
  if (entries == null) return null;
  return [
    for (final e in entries)
      if (e.kind == TpPickedKind.directory) Directory(e.path) else File(e.path),
  ];
}
