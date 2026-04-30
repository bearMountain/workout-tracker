import LinkPresentation
import SwiftUI
import UIKit

enum YouTubeThumbnailURL {
    static func videoID(from url: URL) -> String? {
        let host = url.host?.lowercased() ?? ""
        if host.contains("youtube.com") {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let id = components.queryItems?.first(where: { $0.name == "v" })?.value,
               !id.isEmpty {
                return id
            }
            let path = url.path
            if path.hasPrefix("/shorts/") {
                let rest = String(path.dropFirst("/shorts/".count))
                return rest.split(separator: "/").first.map(String.init)
            }
            if path.hasPrefix("/embed/") {
                let rest = String(path.dropFirst("/embed/".count))
                return rest.split(separator: "/").first.map(String.init)
            }
        }
        if host == "youtu.be" {
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if !id.isEmpty { return id }
        }
        return nil
    }

    static func thumbnailURL(for url: URL) -> URL? {
        guard let id = videoID(from: url) else { return nil }
        return URL(string: "https://img.youtube.com/vi/\(id)/hqdefault.jpg")
    }
}

struct NoteLinkThumbnailView: View {
    let url: URL

    @State private var metadataImage: UIImage?
    @State private var metadataFailed = false

    var body: some View {
        thumbnailContent
            .frame(width: 96, height: 54)
            .background(AppTheme.cardBorder.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let youTubeThumbnail = YouTubeThumbnailURL.thumbnailURL(for: url) {
            AsyncImage(url: youTubeThumbnail) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    linkIcon
                case .empty:
                    ProgressView()
                        .tint(AppTheme.accent)
                @unknown default:
                    linkIcon
                }
            }
        } else if let metadataImage {
            Image(uiImage: metadataImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if metadataFailed {
            linkIcon
        } else {
            ProgressView()
                .tint(AppTheme.accent)
                .task {
                    await loadLinkMetadataImage()
                }
        }
    }

    private var linkIcon: some View {
        Image(systemName: "link")
            .font(.title2)
            .foregroundStyle(AppTheme.textMuted)
    }

    private func loadLinkMetadataImage() async {
        let provider = LPMetadataProvider()
        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            guard let imageProvider = metadata.imageProvider else {
                await MainActor.run { metadataFailed = true }
                return
            }
            let image: UIImage? = await withCheckedContinuation { continuation in
                imageProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    continuation.resume(returning: object as? UIImage)
                }
            }
            await MainActor.run {
                if let image {
                    metadataImage = image
                } else {
                    metadataFailed = true
                }
            }
        } catch {
            await MainActor.run { metadataFailed = true }
        }
    }
}
