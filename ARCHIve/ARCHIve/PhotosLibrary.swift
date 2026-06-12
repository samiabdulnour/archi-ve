import Photos
import UIKit

/// Thin wrapper over the Photos framework for the "tag your existing library"
/// flow: authorisation, fetching assets, and loading images by local identifier
/// (so a tagged reference shows its picture without storing a copy).
/// Loads a displayable image for a Photo, whether it owns its pixels or
/// references one in the Photos library.
enum PhotoImage {
    static func full(for photo: Photo) async -> UIImage? {
        if let id = photo.assetLocalID, !id.isEmpty {
            return await PhotosLibrary.image(localID: id, maxPixel: 0)
        }
        return UIImage(data: photo.imageData)
    }
}

enum PhotosLibrary {
    static var status: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    @discardableResult
    static func requestAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { cont in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { cont.resume(returning: $0) }
        }
    }

    /// All photos (images only), newest first.
    static func fetchImages() -> PHFetchResult<PHAsset> {
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        opts.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        return PHAsset.fetchAssets(with: opts)
    }

    static func asset(localID: String) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil).firstObject
    }

    static func image(localID: String, maxPixel: CGFloat) async -> UIImage? {
        guard let asset = asset(localID: localID) else { return nil }
        return await image(asset: asset, maxPixel: maxPixel)
    }

    /// Load a (downsampled) image for an asset. `maxPixel == 0` → full size.
    static func image(asset: PHAsset, maxPixel: CGFloat) async -> UIImage? {
        await withCheckedContinuation { cont in
            var resumed = false
            let opts = PHImageRequestOptions()
            opts.isNetworkAccessAllowed = true        // fetch from iCloud if needed
            opts.deliveryMode = .highQualityFormat    // single callback
            opts.resizeMode = .fast
            let target = maxPixel > 0
                ? CGSize(width: maxPixel, height: maxPixel)
                : PHImageManagerMaximumSize
            let mode: PHImageContentMode = maxPixel > 0 ? .aspectFill : .aspectFit
            PHImageManager.default().requestImage(for: asset, targetSize: target,
                                                  contentMode: mode, options: opts) { img, _ in
                if !resumed { resumed = true; cont.resume(returning: img) }
            }
        }
    }
}
