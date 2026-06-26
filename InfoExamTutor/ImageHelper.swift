import UIKit

extension UIImage {
    /// 긴 변을 maxDimension 이하로 줄이고 JPEG로 압축한다. (토큰/비용/업로드 크기 절감)
    func downscaledJPEG(maxDimension: CGFloat = 1600, quality: CGFloat = 0.8) -> Data? {
        let longest = max(size.width, size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resized = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
