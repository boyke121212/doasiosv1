import UIKit
import PDFKit
import CoreLocation
import Network

final class Auto {

    // MARK: - AUTO SLIDE
    static func autoSlide(pageControl: UIPageControl, scrollView: UIScrollView, size: Int) {
        guard size > 0 else { return }
        var index = 0
        Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            index = (index + 1) % size
            let x = CGFloat(index) * scrollView.frame.width
            scrollView.setContentOffset(CGPoint(x: x, y: 0), animated: true)
            pageControl.currentPage = index
        }
    }

    // MARK: - DOWNLOAD PDF WITH AUTH
    static func downloadPdfWithAuth(url: String, fileName: String, viewController: UIViewController) {
        guard let token = SecurePrefs.shared.getAccessToken() else {
            showAlert(vc: viewController, message: "Token tidak ditemukan"); return
        }
        guard let requestURL = URL(string: url) else { return }
        var request = URLRequest(url: requestURL)
        request.setValue("Bearer \(token)",                          forHTTPHeaderField: "Authorization")
        request.setValue(DeviceSecurityHelper.getDeviceHash(),       forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(), forHTTPHeaderField: "X-App-Signature")
        URLSession.shared.downloadTask(with: request) { location, _, error in
            if let error = error {
                DispatchQueue.main.async { showAlert(vc: viewController, message: "Download gagal: \(error.localizedDescription)") }
                return
            }
            guard let location = location else { return }
            do {
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let dest = docs.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: dest.path) { try FileManager.default.removeItem(at: dest) }
                try FileManager.default.moveItem(at: location, to: dest)
                DispatchQueue.main.async { showAlert(vc: viewController, message: "PDF tersimpan di Documents") }
            } catch {
                DispatchQueue.main.async { showAlert(vc: viewController, message: "Gagal menyimpan file") }
            }
        }.resume()
    }

    // MARK: - DOWNLOAD PDF VOLLEY
    // Setara downloadPdfVolley di Auto.kt
    static func downloadPdfVolley(url: String, fileName: String, accessToken: String, from vc: UIViewController) {
        guard isInternetAvailable() else {
            DispatchQueue.main.async { showAlert(vc: vc, message: "Tidak ada koneksi internet") }
            return
        }
        guard let requestURL = URL(string: url) else { return }
        var request = URLRequest(url: requestURL)
        request.timeoutInterval = 15
        request.setValue("Bearer \(accessToken)",                    forHTTPHeaderField: "Authorization")
        request.setValue("application/json",                         forHTTPHeaderField: "Accept")
        request.setValue(DeviceSecurityHelper.getDeviceHash(),       forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(), forHTTPHeaderField: "X-App-Signature")
        request.setValue("ios",                                      forHTTPHeaderField: "Platform")
        request.setValue("\(Int(Date().timeIntervalSince1970))",      forHTTPHeaderField: "X-Request-Timestamp")
        request.setValue(UUID().uuidString,                          forHTTPHeaderField: "X-Request-Nonce")
        URLSession.shared.downloadTask(with: request) { location, _, error in
            if let error = error {
                DispatchQueue.main.async { showAlert(vc: vc, message: "Download gagal: \(error.localizedDescription)") }
                return
            }
            guard let location = location else { return }
            do {
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let dest = docs.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: dest.path) { try FileManager.default.removeItem(at: dest) }
                try FileManager.default.moveItem(at: location, to: dest)
                DispatchQueue.main.async {
                    showAlert(vc: vc, message: "PDF berhasil didownload")
                    openPdf(from: dest, in: vc)
                }
            } catch {
                DispatchQueue.main.async { showAlert(vc: vc, message: "Gagal menyimpan file") }
            }
        }.resume()
    }

    // MARK: - OPEN PDF
    static func openPdf(from url: URL, in vc: UIViewController) {
        let pdfVC   = UIViewController()
        let pdfView = PDFView(frame: pdfVC.view.bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.document = PDFDocument(url: url)
        pdfVC.view.addSubview(pdfView)
        vc.present(pdfVC, animated: true)
    }

    // MARK: - CLEAN TEMP PHOTOS
    static func cleanTempPhotos() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DOAS")
        if FileManager.default.fileExists(atPath: dir.path) {
            if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                files.forEach { try? FileManager.default.removeItem(at: $0) }
            }
        }
    }

    // MARK: - INTERNET CHECK
    static func isInternetAvailable() -> Bool {
        let monitor   = NWPathMonitor()
        let queue     = DispatchQueue(label: "InternetMonitor")
        var available = false
        let semaphore = DispatchSemaphore(value: 0)
        monitor.pathUpdateHandler = { path in
            available = path.status == .satisfied
            monitor.cancel()
            semaphore.signal()
        }
        monitor.start(queue: queue)
        semaphore.wait()
        return available
    }

    // MARK: - LOAD FOTO (Statuses helper)
    static func loadFoto(imageView: UIImageView, file: String, tanggal: String, baseURL: String) {
        guard let token = SecurePrefs.shared.getAccessToken() else { return }
        let folderPath  = tanggal.replacingOccurrences(of: "-", with: "/")
        let fullPath    = "\(folderPath)/\(file)"
        let encodedPath = fullPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString   = baseURL + "api/media/absensi?file=" + encodedPath
        guard let url = URL(string: urlString) else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)",                          forHTTPHeaderField: "Authorization")
        request.setValue(DeviceSecurityHelper.getDeviceHash(),       forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(), forHTTPHeaderField: "X-App-Signature")
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async { imageView.image = img }
        }.resume()
    }

    // MARK: - LOADING FOTO
    // Setara loadingFoto() di Auto.kt — URL: BASE_URL/api/media/absensi?file=yyyy/MM/dd/namafile
    static func loadingFoto(
        imageView: UIImageView,
        file: String,
        tanggal: String,
        from vc: UIViewController? = nil   // setara context di Kotlin untuk buka PreviewFotoActivity
    ) {
        guard !file.isEmpty, !tanggal.isEmpty else { return }
        guard let token = SecurePrefs.shared.getAccessToken() else { return }

        let folderPath  = tanggal.replacingOccurrences(of: "-", with: "/")
        let fullPath    = "\(folderPath)/\(file)"
        let encodedPath = fullPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString   = AppConfig2.BASE_URL + "api/media/absensi?file=" + encodedPath

        guard let url = URL(string: urlString) else { return }

        DispatchQueue.main.async { imageView.image = UIImage(named: "doas2") }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)",                          forHTTPHeaderField: "Authorization")
        request.setValue(DeviceSecurityHelper.getDeviceHash(),       forHTTPHeaderField: "X-Device-Hash")
        request.setValue(DeviceSecurityHelper.getAppSignatureHash(), forHTTPHeaderField: "X-App-Signature")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data, !data.isEmpty, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                imageView.image = img
                // Setara: img.setOnClickListener { startActivity(PreviewFotoActivity, foto_uri=url) }
                guard let vc = vc else { return }
                imageView.isUserInteractionEnabled = true
                imageView.gestureRecognizers?.removeAll()
                // UITapGestureRecognizer tidak support closure — pakai objc helper
                let handler = TapHandler(action: {
//                    let preview = PreviewFotoActivity()
//                    preview.fotoUri = urlString
//                    preview.modalPresentationStyle = .fullScreen
//                    vc.present(preview, animated: true)
                })
                let tap = UITapGestureRecognizer(target: handler, action: #selector(TapHandler.invoke))
                imageView.addGestureRecognizer(tap)
                // Simpan handler agar tidak di-deallocate
                objc_setAssociatedObject(imageView, &TapHandler.key, handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }.resume()
    }

//    // MARK: - GET ADDRESS FROM LAT LNG
//    static func getAddressFromLatLng(lat: Double, lon: Double, callback: @escaping (String) -> Void) {
//        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: lat, longitude: lon)) { placemarks, _ in
//            if let p = placemarks?.first {
//                let address = [p.name, p.locality, p.administrativeArea, p.country]
//                    .compactMap { $0 }.joined(separator: ", ")
//                callback(address)
//            } else {
//                callback("Alamat tidak ditemukan")
//            }
//        }
//    }
//
//    // MARK: - ALERT HELPER
    static func showAlert(vc: UIViewController, message: String) {
        let alert = UIAlertController(title: "Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }
//    // MARK: - RENDER ABSENSI (Statuses)
//    // Setara fun Statuses.renderAbsensi() di Android
//    static func renderAbsensi(
//        vc: Statuses,
//        obj: [String: Any],
//        aesKey: String,
//        batpul: String?,
//        jamserver: String?
//    ) {
//        func dec(_ field: String) -> String {
//            let v = obj[field] as? String ?? ""
//            guard !v.isEmpty, v != "null" else { return "" }
//            return CryptoAES.decrypt(v, aesKey)
//        }
//
//        let tanggal     = dec("tanggal")
//        let nip         = dec("nip")
//        let masuk       = dec("masuk")
//        let pulang      = dec("pulang")
//        let ket         = dec("keterangan").uppercased()
//        let lat         = dec("latitude")
//        let lng         = dec("longitude")
//        let ketam       = dec("ketam")
//        let pangkat     = dec("pangkat")
//        let foto        = dec("foto")
//        let foto2       = dec("foto2")
//        let fotopulang  = dec("fotopulang")
//        let fotopulang2 = dec("fotopulang2")
//        let latpulang   = dec("latpulang")
//        let lonpulang   = dec("lonpulang")
//        let statuspulang = dec("statuspulang")
//        let ketpul      = dec("ketpul")
//        let subdit      = dec("subdit")
//        let jabatan     = dec("jabatan")
//        let statusmasuk = dec("statusmasuk")
//        let nama        = dec("nama")
//
//        DispatchQueue.main.async {
//            resetView(vc: vc)
//
//            vc.cardStatusHariIni.isHidden = false
//            vc.tvTanggal.text = tanggal
//            vc.tvKet.text     = ket == "DL" ? "Dinas Luar" : ket
//            vc.tvJam.text     = "\(masuk) (\(statusmasuk))"
//            vc.tvKetam.text   = ketam
//            vc.tvKetam.isHidden   = false
//            vc.tvLabelKR.isHidden = false
//
//            // Lokasi masuk
//            if !lat.isEmpty && !lng.isEmpty {
//                vc.tvLat.isHidden    = false
//                vc.tvLat.text        = "Latitude: \(lat) | Longitude: \(lng)"
//                vc.tvAlamat.isHidden = false
//                vc.tvAlamat.text     = "Mencari alamat..."
//                Auto.getAddressFromLatLng(lat: Double(lat) ?? 0, lon: Double(lng) ?? 0) { alamat in
//                    vc.tvAlamat.text = alamat
//                }
//            }
//
//            // Foto masuk
//            if !foto.isEmpty {
//                vc.imgFoto.isHidden = false
//                Auto.loadingFoto(imageView: vc.imgFoto, file: foto, tanggal: tanggal, from: vc)
//            }
//            if !foto2.isEmpty {
//                vc.imgFoto2.isHidden = false
//                Auto.loadingFoto(imageView: vc.imgFoto2, file: foto2, tanggal: tanggal, from: vc)
//            }
//
//            // Subdit
//            if !subdit.isEmpty {
//                vc.tvSubdit.isHidden = false
//                vc.tvSubdit.text = "Nama : \(nama)\nSubdit : \(subdit)\nNIP : \(nip)\nJabatan : \(jabatan)\nPangkat : \(pangkat)"
//            }
//
//            // Pulang
//            if !pulang.isEmpty {
//                vc.tvPulang.text      = "\(pulang) (\(statuspulang))"
//                vc.tvPulang.isHidden  = false
//                vc.tvLabelR.isHidden  = false
//                vc.btnPulang.isHidden = true
//
//                if !fotopulang.isEmpty {
//                    vc.layoutThumbPulang.isHidden = false
//                    vc.imgFotoPulang.isHidden = false
//                    Auto.loadingFoto(imageView: vc.imgFotoPulang, file: fotopulang, tanggal: tanggal, from: vc)
//                }
//                if !fotopulang2.isEmpty {
//                    vc.layoutThumbPulang.isHidden = false
//                    vc.imgFotoPulang2.isHidden = false
//                    Auto.loadingFoto(imageView: vc.imgFotoPulang2, file: fotopulang2, tanggal: tanggal, from: vc)
//                }
//                if !latpulang.isEmpty && !lonpulang.isEmpty {
//                    vc.tvLatPulang.isHidden    = false
//                    vc.tvLatPulang.text        = "Latitude: \(latpulang) | Longitude: \(lonpulang)"
//                    vc.tvAlamatPulang.isHidden = false
//                    vc.tvAlamatPulang.text     = "Mencari alamat..."
//                    Auto.getAddressFromLatLng(lat: Double(latpulang) ?? 0, lon: Double(lonpulang) ?? 0) { alamat in
//                        vc.tvAlamatPulang.text = alamat
//                    }
//                }
//                vc.tvKepul.isHidden    = false
//                vc.tvKepul.text        = ketpul
//                vc.tvLabelKRP.isHidden = false
//
//            } else {
//                // Belum pulang
//                vc.tvLabelR.isHidden      = true
//                vc.tvLabelKRP.isHidden    = true
//                vc.tvKepul.isHidden       = true
//                vc.tvLatPulang.isHidden   = true
//                vc.tvAlamatPulang.isHidden = true
//                vc.imgFotoPulang.isHidden  = true
//                vc.imgFotoPulang2.isHidden = true
//                vc.btnPulang.isHidden      = false
//                vc.tvPulang.isHidden       = false
//                vc.tvPulang.text           = "Belum Absen"
//            }
//
//            // Tombol pulang
//            vc.btnPulang.removeTarget(nil, action: nil, for: .allEvents)
//            vc.onTapBtnPulang = {
//                guard let bp = batpul, !bp.isEmpty else {
//                    Auto.showAlert(vc: vc, message: "Gagal Ambil Data")
//                    return
//                }
//                let next = AbsenHadir()
//                next.bataspulang = bp
//                next.dari = "PULANG"
//                next.jamserver   = jamserver ?? ""
//                next.ket         = ket
//                next.modalPresentationStyle = .fullScreen
//                vc.present(next, animated: true)
//            }
//            vc.btnPulang.addTarget(vc, action: #selector(Statuses.didTapBtnPulang), for: .touchUpInside)
//        }
//    }
//
//    // MARK: - RESET VIEW (Statuses)
//    // Setara fun resetView() di Android
//    static func resetView(vc: Statuses) {
//        vc.tvLat.isHidden             = true
//        vc.tvLabelR.isHidden          = true
//        vc.tvLabelKR.isHidden         = true
//        vc.tvKetam.isHidden           = true
//        vc.tvPulang.isHidden          = true
//        vc.layoutThumbPulang.isHidden = true
//        vc.tvLatPulang.isHidden       = true
//        vc.imgFoto.isHidden           = true
//        vc.imgFoto2.isHidden          = true
//        vc.btnPulang.isHidden         = true
//        vc.tvSubdit.isHidden          = true
//        vc.tvKepul.isHidden           = true
//        vc.cardStatusHariIni.isHidden = true
//        vc.imgFotoPulang.isHidden     = true
//        vc.imgFotoPulang2.isHidden    = true
//        vc.tvAlamat.isHidden          = true
//        vc.tvAlamatPulang.isHidden    = true
//        vc.tvLabelKRP.isHidden        = true
//    }

}


// MARK: - TapHandler
// Helper untuk UITapGestureRecognizer karena tidak support trailing closure
final class TapHandler: NSObject {
    static var key = "TapHandlerKey"
    private let action: () -> Void
    init(action: @escaping () -> Void) { self.action = action }
    @objc func invoke() { action() }
}
