import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_ui/shared_ui.dart';

/// [TpGalleryPort] backed by photo_manager.
class PhotoManagerGalleryPort implements TpGalleryPort {
  final Map<String, AssetPathEntity> _albumsById = {};
  final Map<String, AssetEntity> _assetsById = {};

  @override
  Future<List<TpGalleryAlbum>> listAlbums({
    required bool includeVideos,
    required bool includeImages,
  }) async {
    final requestType = _requestType(
      includeVideos: includeVideos,
      includeImages: includeImages,
    );
    if (requestType == null) {
      return const [];
    }

    final albums = await PhotoManager.getAssetPathList(
      type: requestType,
      hasAll: true,
      onlyAll: false,
    );

    _albumsById
      ..clear()
      ..addEntries(albums.map((album) => MapEntry(album.id, album)));

    final albumModels = <TpGalleryAlbum>[];
    for (final album in albums) {
      albumModels.add(
        TpGalleryAlbum(
          id: album.id,
          name: album.name,
          assetCount: await album.assetCountAsync,
        ),
      );
    }

    return albumModels;
  }

  @override
  Future<List<TpGalleryAsset>> listAssets({
    required String albumId,
    required int page,
    required int pageSize,
    required bool includeVideos,
    required bool includeImages,
  }) async {
    final album = _albumsById[albumId];
    if (album == null) {
      return const [];
    }

    final assets = await album.getAssetListPaged(page: page, size: pageSize);
    final filtered = assets.where((asset) {
      if (asset.type == AssetType.video) {
        return includeVideos;
      }
      if (asset.type == AssetType.image) {
        return includeImages;
      }
      return includeImages || includeVideos;
    });

    return filtered.map(_toGalleryAsset).toList();
  }

  @override
  Future<Uint8List?> thumbnail(String assetId, {int size = 200}) async {
    final asset = await _assetForId(assetId);
    if (asset == null) {
      return null;
    }

    return asset.thumbnailDataWithSize(ThumbnailSize(size, size));
  }

  @override
  Future<String?> resolveToPath(String assetId) async {
    final asset = await _assetForId(assetId);
    if (asset == null) {
      return null;
    }

    try {
      final file = await asset.file;
      return file?.path;
    } on PlatformException {
      return null;
    }
  }

  RequestType? _requestType({
    required bool includeVideos,
    required bool includeImages,
  }) {
    if (includeImages && includeVideos) {
      return RequestType.common;
    }
    if (includeVideos) {
      return RequestType.video;
    }
    if (includeImages) {
      return RequestType.image;
    }
    return null;
  }

  TpGalleryAsset _toGalleryAsset(AssetEntity asset) {
    _assetsById[asset.id] = asset;
    return TpGalleryAsset(
      id: asset.id,
      displayName: asset.title,
      isVideo: asset.type == AssetType.video,
      duration: asset.type == AssetType.video
          ? Duration(seconds: asset.duration)
          : null,
      createDateTime: asset.createDateTime,
    );
  }

  Future<AssetEntity?> _assetForId(String assetId) async {
    final cached = _assetsById[assetId];
    if (cached != null) {
      return cached;
    }

    final asset = await AssetEntity.fromId(assetId);
    if (asset != null) {
      _assetsById[assetId] = asset;
    }
    return asset;
  }
}
