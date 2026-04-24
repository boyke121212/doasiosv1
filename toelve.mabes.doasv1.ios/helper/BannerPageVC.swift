import UIKit

final class BannerPageVC: UIViewController {

    let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let gradientLayer = CAGradientLayer()
    let item: BeritaItem

    private func attributedHTML(_ html: String, baseFont: UIFont, color: UIColor) -> NSAttributedString? {
        let wrapped = """
        <span style=\"font-family: -apple-system, HelveticaNeue; font-size: \(Int(baseFont.pointSize))px; color: #F2F2F2\">\n\(html)\n</span>
        """
        guard let data = wrapped.data(using: .utf8) else { return nil }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        return try? NSAttributedString(data: data, options: options, documentAttributes: nil)
    }

    init(item: BeritaItem) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Gradient overlay for readability
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.7).cgColor]
        gradientLayer.locations = [0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        imageView.layer.addSublayer(gradientLayer)

        // ❌ TIDAK DIPAKAI - Text hanya ditampilkan di Home.swift
        /*
        // Title label
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Body label
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = UIColor(white: 0.95, alpha: 1)
        bodyLabel.numberOfLines = 3
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(bodyLabel)

        NSLayoutConstraint.activate([
            bodyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bodyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bodyLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            titleLabel.leadingAnchor.constraint(equalTo: bodyLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: bodyLabel.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bodyLabel.topAnchor, constant: -6)
        ])
        */

        // ❌ TIDAK DIPAKAI - Text sudah di-handle di Home.swift via onBeritaChanged()
        // Bind data from backend model
        //titleLabel.text = item.judul
//        if let rendered = attributedHTML(item.isi, baseFont: .systemFont(ofSize: 14), color: UIColor(white: 0.95, alpha: 1)) {
//            bodyLabel.attributedText = rendered
//        } else {
//            // Fallback: strip HTML to plain text
//            if let data = item.isi.data(using: .utf8),
//               let attributed = try? NSAttributedString(data: data,
//                                                        options: [.documentType: NSAttributedString.DocumentType.html,
//                                                                  .characterEncoding: String.Encoding.utf8.rawValue],
//                                                        documentAttributes: nil) {
//                bodyLabel.text = attributed.string
//            } else {
//                bodyLabel.text = item.isi
//            }
//        }

        // Ensure labels don't block gestures
        // titleLabel.isUserInteractionEnabled = false
        // bodyLabel.isUserInteractionEnabled = false

        loadImage()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = imageView.bounds
    }

    private func loadImage() {
        print("📸 [BANNER] Loading image for: \(item.foto)")
        
        guard let token = SecurePrefs.shared.getAccessToken() else {
            print("❌ [BANNER] No access token found")
            return
        }

        let fileName = item.foto
        let cacheURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // 1️⃣ Coba load dari disk cache dulu
        if let data = try? Data(contentsOf: cacheURL),
           let image = UIImage(data: data) {
            print("✅ [BANNER] Loaded image from cache")
            imageView.image = image
            return
        }

        // 2️⃣ Kalau tidak ada → download dari API
        let urlString = AppConfig.BASE_URL + "api/media/berita/" + fileName
        print("🌐 [BANNER] Downloading from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [BANNER] Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(DeviceSecurityHelper.getDeviceHash(), forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(), forHTTPHeaderField: "X-App-Signature")
        request.setValue("ios", forHTTPHeaderField: "Platform")
        
        print("📸 [BANNER] Sending image request with auth headers...")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ [BANNER] Download error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("❌ [BANNER] No image data received")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📸 [BANNER] Image response status: \(httpResponse.statusCode)")
            }

            // Simpan ke disk cache
            try? data.write(to: cacheURL)
            print("✅ [BANNER] Image cached to: \(cacheURL)")

            DispatchQueue.main.async {
                self.imageView.image = UIImage(data: data)
                print("✅ [BANNER] Image displayed!")
            }
        }.resume()
    }
}
