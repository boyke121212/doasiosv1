//
//  Network.swift
//  Doas
//
//  Created by Admin on 06/03/26.
//

import Foundation
import UIKit
import Network          // Apple Network framework (iOS 12+) — pengganti ConnectivityManager Android

// MARK: - RenderHtml
// Porting dari: object RenderHtml { fun htmlPreviewClean(...) }
// Dipanggil dari Berita.swift: RenderHtml.htmlPreviewClean(item.isi)

enum RenderHtml {

    /// Membersihkan string HTML menjadi plain text dan memotong sesuai jumlah kata.
    ///
    /// - Parameters:
    ///   - html:      String HTML yang akan dibersihkan (boleh nil).
    ///   - maxWords:  Batas maksimum kata yang ditampilkan (default 20).
    /// - Returns:     Plain text yang sudah bersih dan terpotong.
    static func htmlPreviewClean(_ html: String?, maxWords: Int = 20) -> String {

        guard let html, !html.isEmpty else { return "" }

        // Langkah 1 – Decode HTML entities (&lt; → <, &amp; → &, dsb.)
        // Setara: Html.fromHtml(html, Html.FROM_HTML_MODE_LEGACY).toString()
        let decoded: String = {
            guard let data = html.data(using: .utf8) else { return html }
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
                return attributed.string
            }
            return html
        }()

        // Langkah 2 – Buang semua tag HTML yang tersisa
        // Setara: decoded.replace(Regex("<[^>]*>"), "")
        let noTags = decoded.replacingOccurrences(
            of: "<[^>]*>",
            with: "",
            options: .regularExpression
        )

        // Langkah 3 – Bersihkan &nbsp; dan whitespace berlebih
        // Setara: .replace("&nbsp;", " ").replace("\\s+".toRegex(), " ").trim()
        let cleaned = noTags
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Langkah 4 – Potong berdasarkan jumlah kata
        // Setara: words.take(maxWords).joinToString(" ") + "..."
        let words = cleaned.components(separatedBy: " ").filter { !$0.isEmpty }

        if words.count <= maxWords {
            return cleaned
        } else {
            return words.prefix(maxWords).joined(separator: " ") + "..."
        }
    }
}

// MARK: - NetworkHelper
// Porting dari:
//   fun isInternetAvailable(context: Context): Boolean {
//       val cm = context.getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
//       val network = cm.activeNetwork ?: return false
//       val capabilities = cm.getNetworkCapabilities(network) ?: return false
//       return capabilities.hasCapability(NET_CAPABILITY_INTERNET)
//   }
//
// Di iOS tidak ada Context, sehingga cukup dipanggil secara static/global.
// Apple menyediakan NWPathMonitor (Network framework) sebagai pengganti ConnectivityManager.

enum NetworkHelper {

    /// Monitor singleton — diinisialisasi sekali saat pertama kali diakses.
    /// Setara ConnectivityManager yang selalu ready di background.
    private static let monitor   = NWPathMonitor()
    private static let monitorQ  = DispatchQueue(label: "id.doas.network.monitor")
    private static var _isReachable: Bool = true   // optimistis sampai monitor memberi tahu

    /// Mulai observasi jaringan saat app launch.
    /// Panggil sekali dari AppDelegate / SceneDelegate:
    ///   NetworkHelper.startMonitoring()
    static func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            // NWPath.Status.satisfied  ≈  NET_CAPABILITY_INTERNET tersedia
            _isReachable = (path.status == .satisfied)
        }
        monitor.start(queue: monitorQ)
    }

    /// Setara: isInternetAvailable(context)
    /// Dipanggil dari mana saja — tidak butuh Context seperti Android.
    ///
    /// Contoh pemakaian di Berita.swift:
    ///   guard NetworkHelper.isInternetAvailable() else {
    ///       showAlert("Tidak ada koneksi internet")
    ///       return
    ///   }
    static func isInternetAvailable() -> Bool {
        return _isReachable
    }
}

// MARK: - UIImageView + loadImage
// Setara Coil di Android:
//   holder.ivFoto.load(url) {
//       placeholder(R.drawable.doas2)
//       error(R.drawable.logodit)
//       crossfade(true)
//       addHeader("Authorization", "Bearer $token")
//       addHeader("X-Device-Hash", ...)
//       addHeader("X-App-Signature", ...)
//   }
//
// Cara pakai:
//   ivFoto.loadImage(url: url, token: token, placeholder: UIImage(named: "doas2"))

extension UIImageView {

    /// Cache gambar sederhana in-memory — setara cache bawaan Coil
    private static var imageCache = NSCache<NSURL, UIImage>()

    /// Muat gambar dari URL dengan Bearer token di header Authorization.
    /// - Parameters:
    ///   - url:         URL gambar yang akan dimuat.
    ///   - token:       Access token untuk header `Authorization: Bearer <token>`.
    ///   - placeholder: Gambar yang ditampilkan saat loading / error (opsional).
    func loadImage(url: URL, token: String, placeholder: UIImage? = nil) {

        // Tampilkan placeholder dulu (setara Coil placeholder(...))
        self.image = placeholder

        // Cek cache dulu — hindari request ulang untuk URL yang sama
        if let cached = UIImageView.imageCache.object(forKey: url as NSURL) {
            self.image = cached
            return
        }

        // Buat URLRequest dengan header Authorization
        // Setara: addHeader("Authorization", "Bearer $token")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Tambahkan header device security jika tersedia
        // Setara: addHeader("X-Device-Hash", DeviceSecurityHelper.getDeviceHash(context))
        //         addHeader("X-App-Signature", DeviceSecurityHelper.getAppSignatureHash(context))
        let deviceHash = DeviceSecurityHelper.getDeviceHash()
        if !deviceHash.isEmpty {
            request.setValue(deviceHash, forHTTPHeaderField: "X-Device-Hash")
        }
        let appSignature = DeviceSecurityHelper.getAppSignatureHash()
        if !appSignature.isEmpty {
            request.setValue(appSignature, forHTTPHeaderField: "X-App-Signature")
        }

        // Simpan referensi task agar bisa dibatalkan saat cell di-reuse
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let self else { return }

            // Error atau data kosong → tampilkan placeholder (setara Coil error(...))
            guard error == nil, let data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { self.image = placeholder }
                return
            }

            // Simpan ke cache
            UIImageView.imageCache.object(forKey: url as NSURL)
            UIImageView.imageCache.setObject(image, forKey: url as NSURL)

            // Tampilkan dengan animasi fade (setara Coil crossfade(true))
            DispatchQueue.main.async {
                UIView.transition(
                    with: self,
                    duration: 0.25,
                    options: .transitionCrossDissolve,
                    animations: { self.image = image }
                )
            }
        }

        // Simpan task ke associatedObject agar bisa di-cancel saat cell di-reuse
        objc_setAssociatedObject(self, &AssociatedKeys.taskKey, task, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        task.resume()
    }

    /// Batalkan request yang sedang berjalan — panggil di prepareForReuse() cell
    func cancelImageLoad() {
        (objc_getAssociatedObject(self, &AssociatedKeys.taskKey) as? URLSessionDataTask)?.cancel()
    }
}

private enum AssociatedKeys {
    static var taskKey = "loadImageTask"
}

// MARK: - PdfDownloader
// Porting dari: fun downloadPdfVolley(...) + fun openPdf() di Auto.kt
// Dipanggil dari mana saja — tidak butuh instance ViewController:
//   PdfDownloader.download(url: urlPdf, filename: item.pdf, token: token)

enum PdfDownloader {

    /// Download PDF via URLSession lalu buka share sheet.
    /// Setara: downloadPdfVolley(context, urlPdf, d.pdf, tokenDownload)
    static func download(
        url: String, 
        filename: String, 
        token: String, 
        from sourceVC: UIViewController? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {

        // Setara: if (!Auto.isInternetAvailable(context)) { Toast... return }
        guard NetworkHelper.isInternetAvailable() else {
            Toast.show("Tidak ada koneksi internet")
            completion?(false)
            return
        }

        guard let requestURL = URL(string: url) else {
            Toast.show("URL tidak valid")
            completion?(false)
            return
        }

        // MARK: BUILD REQUEST (setara getHeaders())
        var request = URLRequest(url: requestURL)
        request.httpMethod      = "GET"
        request.timeoutInterval = 15

        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce     = UUID().uuidString

        request.setValue("Bearer \(token)",                          forHTTPHeaderField: "Authorization")
        request.setValue("application/json",                         forHTTPHeaderField: "Accept")
        let deviceHashHeader = DeviceSecurityHelper.getDeviceHash()
        if !deviceHashHeader.isEmpty {
            request.setValue(deviceHashHeader, forHTTPHeaderField: "X-Device-Hash")
        }
        let appSignatureHeader = DeviceSecurityHelper.getAppSignatureHash()
        if !appSignatureHeader.isEmpty {
            request.setValue(appSignatureHeader, forHTTPHeaderField: "X-App-Signature")
        }
        request.setValue("ios",                                      forHTTPHeaderField: "Platform")
        request.setValue(timestamp,                                  forHTTPHeaderField: "X-Request-Timestamp")
        request.setValue(nonce,                                      forHTTPHeaderField: "X-Request-Nonce")

        // MARK: EXECUTE (setara VolleySingleton.addToRequestQueue)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in

            DispatchQueue.main.async {

                // MARK: ERROR HANDLING (setara ErrorListener Volley)
                if let error = error as NSError? {
                    let message: String
                    switch error.code {
                    case NSURLErrorNotConnectedToInternet:     message = "Tidak ada koneksi internet"
                    case NSURLErrorTimedOut:                   message = "Koneksi timeout"
                    case NSURLErrorUserAuthenticationRequired: message = "Akses ditolak"
                    default:                                   message = "Download gagal"
                    }
                    Toast.show(message)
                    completion?(false)
                    return
                }

                guard let data, !data.isEmpty else {
                    Toast.show("File kosong atau gagal diunduh")
                    completion?(false)
                    return
                }

                // MARK: SIMPAN FILE (setara deliverResponse)
                do {
                    let fileURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(filename)
                    try data.write(to: fileURL)

                    // MARK: BUKA PDF (setara openPdf())
                    openPdf(fileURL: fileURL, from: sourceVC)
                    completion?(true)

                } catch {
                    Toast.show("Gagal menyimpan file")
                    completion?(false)
                }
            }
        }

        // MARK: TIMEOUT GUARD (setara DefaultRetryPolicy Volley)
        task.resume()
        DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
            if task.state == .running {
                task.cancel()
                DispatchQueue.main.async { 
                    Toast.show("Koneksi timeout")
                    completion?(false)
                }
            }
        }
    }

    /// Buka file PDF lewat share sheet.
    /// Setara: fun openPdf() di Android
    static func openPdf(fileURL: URL, from sourceVC: UIViewController? = nil) {

        let presenter = sourceVC ?? UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController?
            .topmostViewController()

        guard let presenter else { return }

        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 0, height: 0
            )
            popover.permittedArrowDirections = []
        }

        presenter.present(activityVC, animated: true)
    }
}

// MARK: - Toast
// Setara Toast.makeText(context, message, Toast.LENGTH_SHORT).show() di Android
// Dipanggil dari mana saja — tidak butuh Context:
//   Toast.show("Pesan error")

enum Toast {

    static func show(_ message: String, duration: TimeInterval = 2.0) {

        guard let window = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })
        else { return }

        // Hapus toast lama agar tidak menumpuk
        window.subviews
            .filter { $0.accessibilityIdentifier == "DoasToast" }
            .forEach { $0.removeFromSuperview() }

        let label = UILabel()
        label.accessibilityIdentifier = "DoasToast"
        label.text            = message
        label.textColor       = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        label.textAlignment   = .center
        label.font            = .systemFont(ofSize: 14)
        label.numberOfLines   = 0
        label.layer.cornerRadius = 8
        label.clipsToBounds   = true
        label.alpha           = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        window.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -32),
            label.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -32)
        ])

        // Fade in → tahan → fade out (setara animasi default Toast Android)
        UIView.animate(withDuration: 0.3, animations: {
            label.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: duration, animations: {
                label.alpha = 0
            }) { _ in
                label.removeFromSuperview()
            }
        }
    }
}

// MARK: - UIViewController topmost helper
// Digunakan PdfDownloader.openPdf untuk menemukan VC paling atas secara otomatis
extension UIViewController {
    func topmostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topmostViewController()
        }
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.topmostViewController() ?? self
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topmostViewController() ?? self
        }
        return self
    }
}

