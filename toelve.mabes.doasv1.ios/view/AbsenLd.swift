//
//  AbsenLd.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 24/04/26.
//

import UIKit
import AVFoundation

class AbsenLd: Boyke {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var isCapturing = false

    // Overlay
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 11/255, green: 19/255, blue: 64/255, alpha: 0.73)
        return view
    }()
    
    // Header
    private let headerStatusView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.8)
        view.layer.cornerRadius = 4
        return view
    }()
    
    private let headerIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "checkmark.circle.fill")
        iv.tintColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1)
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "Ambil Foto Lokasi Lepas Dinas"
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .bold)
        return label
    }()
    
    // Card Camera
    private let cardCameraView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 18
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        view.layer.shadowRadius = 10
        view.clipsToBounds = false
        return view
    }()
    // Keterangan Layout
    private let layoutKeterangan: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        return view
    }()
    private let labelKeterangan: UILabel = {
        let label = UILabel()
        label.text = "Keterangan LD"
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    private let etLd: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 15)
        tv.layer.borderColor = UIColor.lightGray.cgColor
        tv.layer.borderWidth = 1
        tv.layer.cornerRadius = 8
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return tv
    }()
    private let frameLayout = UIView()
    
    private let ivFoto = UIView() // PreviewView untuk camera
    
    private let ivResult: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .lightGray
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 18
        // Placeholder image
        iv.image = UIImage(systemName: "camera.fill")
        iv.tintColor = .gray
        return iv
    }()
    
    // Switch Camera Button
    private let btnSwitch: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        btn.tintColor = .white
        btn.backgroundColor = .clear
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.5
        btn.layer.shadowOffset = CGSize(width: 0, height: 2)
        btn.layer.shadowRadius = 4
        return btn
    }()
    
    // Buttons
    private let layoutButton = UIStackView()
    
    private let btMulai: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Mulai", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.setTitleColor(.black, for: .normal)
        btn.backgroundColor = UIColor(white: 0.88, alpha: 1)
        btn.layer.cornerRadius = 8
        return btn
    }()
    
    private let btKirim: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Kirim", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 41/255, green: 98/255, blue: 255/255, alpha: 1)
        btn.layer.cornerRadius = 8
        return btn
    }()
    
    // Disclaimer
    private let tvDisclaimer: UILabel = {
        let label = UILabel()
        label.text = "Foto diambil untuk keperluan audit internal, bukan untuk biometrik atau pencocokan wajah."
        label.textColor = UIColor(white: 0.98, alpha: 1)
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Properties
    
    private var absensiManager: AbsensiManager!
    
    private var menu = "mulai"
    private var jam: String?
    
    private var officeLat: Double?
    private var officeLon: Double?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        setupAbsensiManager()
        setupActions()
        setupKeyboardHandling()
        
        // Default state
        btnSwitch.isHidden = true
        btMulai.isEnabled = false
        btMulai.setTitle("Menyiapkan data...", for: .normal)
        
        // Dismiss keyboard on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        
        // Scroll to text view if it's being edited
        if etLd.isFirstResponder {
            let textViewFrame = etLd.convert(etLd.bounds, to: scrollView)
            scrollView.scrollRectToVisible(textViewFrame, animated: true)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchOfficeData()
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Add overlay
        view.addSubview(overlayView)
        
        // Add scrollView
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Header
        headerStatusView.addSubview(headerIconView)
        headerStatusView.addSubview(headerLabel)
        contentView.addSubview(headerStatusView)
        
        // Card Camera
        frameLayout.addSubview(ivFoto)
        frameLayout.addSubview(ivResult)
        cardCameraView.addSubview(frameLayout)
        contentView.addSubview(cardCameraView)
        
        // Switch button
        contentView.addSubview(btnSwitch)
        
        // Keterangan
        layoutKeterangan.addSubview(labelKeterangan)
        layoutKeterangan.addSubview(etLd)
        contentView.addSubview(layoutKeterangan)
        // Buttons
        layoutButton.axis = .horizontal
        layoutButton.distribution = .fillEqually
        layoutButton.spacing = 16
        layoutButton.addArrangedSubview(btMulai)
        layoutButton.addArrangedSubview(btKirim)
        contentView.addSubview(layoutButton)
        
        // Disclaimer
        view.addSubview(tvDisclaimer)
        
        // Initial visibility
        ivFoto.isHidden = true
        ivResult.isHidden = false
    }
    
    private func setupConstraints() {
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        headerStatusView.translatesAutoresizingMaskIntoConstraints = false
        headerIconView.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        cardCameraView.translatesAutoresizingMaskIntoConstraints = false
        frameLayout.translatesAutoresizingMaskIntoConstraints = false
        ivFoto.translatesAutoresizingMaskIntoConstraints = false
        ivResult.translatesAutoresizingMaskIntoConstraints = false
        btnSwitch.translatesAutoresizingMaskIntoConstraints = false
        layoutKeterangan.translatesAutoresizingMaskIntoConstraints = false
        labelKeterangan.translatesAutoresizingMaskIntoConstraints = false
        etLd.translatesAutoresizingMaskIntoConstraints = false
        layoutButton.translatesAutoresizingMaskIntoConstraints = false
        tvDisclaimer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Overlay
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: tvDisclaimer.topAnchor, constant: -12),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            headerStatusView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerStatusView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerStatusView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            headerStatusView.heightAnchor.constraint(equalToConstant: 44),
            
            headerIconView.leadingAnchor.constraint(equalTo: headerStatusView.leadingAnchor, constant: 12),
            headerIconView.centerYAnchor.constraint(equalTo: headerStatusView.centerYAnchor),
            headerIconView.widthAnchor.constraint(equalToConstant: 16),
            headerIconView.heightAnchor.constraint(equalToConstant: 16),
            
            headerLabel.leadingAnchor.constraint(equalTo: headerIconView.trailingAnchor, constant: 8),
            headerLabel.centerYAnchor.constraint(equalTo: headerStatusView.centerYAnchor),
            headerLabel.trailingAnchor.constraint(equalTo: headerStatusView.trailingAnchor, constant: -12),
            
            // Card Camera (4:5 ratio)
            cardCameraView.topAnchor.constraint(equalTo: headerStatusView.bottomAnchor, constant: 16),
            cardCameraView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardCameraView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardCameraView.heightAnchor.constraint(equalTo: cardCameraView.widthAnchor, multiplier: 5.0/4.0),
            
            // Frame Layout
            frameLayout.topAnchor.constraint(equalTo: cardCameraView.topAnchor),
            frameLayout.leadingAnchor.constraint(equalTo: cardCameraView.leadingAnchor),
            frameLayout.trailingAnchor.constraint(equalTo: cardCameraView.trailingAnchor),
            frameLayout.bottomAnchor.constraint(equalTo: cardCameraView.bottomAnchor),
            
            // ivFoto & ivResult
            ivFoto.topAnchor.constraint(equalTo: frameLayout.topAnchor),
            ivFoto.leadingAnchor.constraint(equalTo: frameLayout.leadingAnchor),
            ivFoto.trailingAnchor.constraint(equalTo: frameLayout.trailingAnchor),
            ivFoto.bottomAnchor.constraint(equalTo: frameLayout.bottomAnchor),
            
            ivResult.topAnchor.constraint(equalTo: frameLayout.topAnchor),
            ivResult.leadingAnchor.constraint(equalTo: frameLayout.leadingAnchor),
            ivResult.trailingAnchor.constraint(equalTo: frameLayout.trailingAnchor),
            ivResult.bottomAnchor.constraint(equalTo: frameLayout.bottomAnchor),
            
            // Switch Button
            btnSwitch.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            btnSwitch.topAnchor.constraint(equalTo: cardCameraView.bottomAnchor, constant: 8),
            btnSwitch.widthAnchor.constraint(equalToConstant: 60),
            btnSwitch.heightAnchor.constraint(equalToConstant: 60),
            
            // Layout Keterangan
            layoutKeterangan.topAnchor.constraint(equalTo: btnSwitch.bottomAnchor, constant: 16),
            layoutKeterangan.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            layoutKeterangan.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            labelKeterangan.topAnchor.constraint(equalTo: layoutKeterangan.topAnchor, constant: 12),
            labelKeterangan.leadingAnchor.constraint(equalTo: layoutKeterangan.leadingAnchor, constant: 12),
            labelKeterangan.trailingAnchor.constraint(equalTo: layoutKeterangan.trailingAnchor, constant: -12),
            
            etLd.topAnchor.constraint(equalTo: labelKeterangan.bottomAnchor, constant: 8),
            etLd.leadingAnchor.constraint(equalTo: layoutKeterangan.leadingAnchor, constant: 12),
            etLd.trailingAnchor.constraint(equalTo: layoutKeterangan.trailingAnchor, constant: -12),
            etLd.heightAnchor.constraint(equalToConstant: 120),
            etLd.bottomAnchor.constraint(equalTo: layoutKeterangan.bottomAnchor, constant: -12),
            
            // Layout Button
            layoutButton.topAnchor.constraint(equalTo: layoutKeterangan.bottomAnchor, constant: 16),
            layoutButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            layoutButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            layoutButton.heightAnchor.constraint(equalToConstant: 52),
            layoutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // Disclaimer
            tvDisclaimer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            tvDisclaimer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            tvDisclaimer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
    }
    
    private func setupAbsensiManager() {
        absensiManager = AbsensiManager(
            viewController: self,
            previewView: ivFoto
        )
    }
    
    private func setupActions() {
        btMulai.addTarget(self, action: #selector(onMulaiTapped), for: .touchUpInside)
        btKirim.addTarget(self, action: #selector(onKirimTapped), for: .touchUpInside)
        btnSwitch.addTarget(self, action: #selector(onSwitchTapped), for: .touchUpInside)
        
        // Back button handling
        navigationItem.hidesBackButton = true
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.left"),
            style: .plain,
            target: self,
            action: #selector(onBackPressed)
        )
        navigationItem.leftBarButtonItem = backButton
    }
    
    // MARK: - Actions
    
    @objc private func onMulaiTapped() {
        switch menu.lowercased() {
        case "mulai":
            startFlow()
        case "capture":
            captureFlow()
        case "ulangi":
            resetFlow()
        default:
            break
        }
    }
    
    @objc private func onKirimTapped() {
        onKirim()
    }
    
    @objc private func onSwitchTapped() {
        absensiManager.switchCamera()
    }
    
    @objc private func onBackPressed() {
        absensiManager.stop()
        
        // Navigate to Home
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let homeVC = Home()
            window.rootViewController = homeVC
            window.makeKeyAndVisible()
        }
    }
    
    // MARK: - Flow State
    
    private func startFlow() {
        guard isOfficeReady() else {
            showToast("Data kantor belum siap, tunggu sebentar")
            return
        }
        
        absensiManager.authenticate { [weak self] in
            guard let self = self else { return }
            
            self.ivResult.isHidden = true
            self.ivFoto.isHidden = false
            
            self.absensiManager.prepare(modeAbsensi: .TANPA_LOKASI)
            
            self.menu = "capture"
            self.btMulai.setTitle("Capture", for: .normal)
            self.btnSwitch.isHidden = false
        }
    }
    
    private func captureFlow() {

        if isCapturing {
            return
        }

        isCapturing = true
        showCaptureLoading()

        absensiManager.capture { [weak self] fileURL in
            guard let self = self else { return }

            DispatchQueue.main.async {

                self.hideCaptureLoading()
                self.isCapturing = false

                self.ivFoto.isHidden = true
                self.ivResult.isHidden = false

                if let image = UIImage(contentsOfFile: fileURL.path) {
                    self.ivResult.image = image
                }

                self.menu = "ulangi"
                self.btMulai.setTitle("Ulangi", for: .normal)
                self.btnSwitch.isHidden = true
            }
        }
    }
    
    private func resetFlow() {
        absensiManager.restartPreview()
        
        ivResult.isHidden = true
        ivFoto.isHidden = false
        
        menu = "capture"
        btMulai.setTitle("Capture", for: .normal)
        btnSwitch.isHidden = false
    }
    
    // MARK: - Submit Absensi
    
    private func onKirim() {
        guard isOfficeReady() else {
            showToast("Data kantor belum siap")
            return
        }
        let ketdin = etLd.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if ketdin.isEmpty {
            showToast("Masukan Keterangan Ld dulu")
            return
        }
        guard let file = absensiManager.capturedFile,
              FileManager.default.fileExists(atPath: file.path) else {
            showToast("Ambil foto dulu")
            return
        }
        // 🔥 COMPRESS DI SINI
        guard let image = UIImage(contentsOfFile: file.path),
              let data = image.jpegData(compressionQuality: 0.2) else {
            showToast("Gagal proses foto")
            return
        }
        
        let compressedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".jpg")

        try? data.write(to: compressedURL)
        
        print("🔍 [ABSEN] Compressed file size: \(data.count) bytes")
        // DEBUG (AMAN)
        print("🔍 [ABSEN] ========== KIRIM ABSEN ==========")
        print("🔍 [ABSEN] officeLat=\(officeLat ?? 0) officeLon=\(officeLon ?? 0)")
        print("🔍 [ABSEN] userLat=\(absensiManager.lat ?? 0) userLon=\(absensiManager.lon ?? 0)")
        print("🔍 [ABSEN] File path: \(file.path)")
        print("🔍 [ABSEN] File exists: \(FileManager.default.fileExists(atPath: file.path))")
        
        if let fileSize = try? FileManager.default.attributesOfItem(atPath: file.path)[.size] as? UInt64 {
            print("🔍 [ABSEN] File size: \(fileSize) bytes")
        }
        
        var params: [String: String] = [
            "menu": "LD",
            "ketam":ketdin,
            "jam": jam ?? ""
        ]
        
        // 🔐 ANTI-REPLAY (WAJIB BARU SETIAP REQUEST)
        params["__ts"] = String(Int(Date().timeIntervalSince1970))
        params["__nonce"] = UUID().uuidString
        
        print("🔍 [ABSEN] Params to send: \(params)")
        
        let authManager = AuthManager(purnomo: "api/absen")
        
        authManager.uploadFoto(
            files: [compressedURL],
            params: params,
            onSuccess: { [weak self] json in
                guard let self = self else { return }
                
                print("✅ [ABSEN] Upload SUCCESS!")
                print("✅ [ABSEN] Response JSON: \(json)")
                
                let status = json["status"] as? String ?? ""
                let message = json["message"] as? String ?? "Berhasil"
                
                print("✅ [ABSEN] Status: \(status)")
                print("✅ [ABSEN] Message: \(message)")
                
                self.absensiManager.stop()
                
                if status == "ok" {
                    // Show success message dengan callback ke home
                    let alert = UIAlertController(title: "Sukses", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.navigateToHome()
                    })
                    self.present(alert, animated: true)
                } else {
                    print("⚠️ [ABSEN] Status bukan 'ok', tapi: \(status)")
                    self.showToast(message)
                }
            },
            onError: { [weak self] message in
                guard let self = self else { return }
                
                print("❌ [ABSEN] Upload ERROR!")
                print("❌ [ABSEN] Error message: \(message)")
                
                // 🔥 MESSAGE BACKEND AKHIRNYA SAMPAI
                self.showToast(message)
                //self.navigateToMainActivity()
            },
            onLogout: { [weak self] message in
                guard let self = self else { return }
                
                print("🔐 [ABSEN] Upload LOGOUT!")
                print("🔐 [ABSEN] Logout message: \(message)")
                
                switch message {
                case "Verification failed", "__TIMEOUT__", "__NO_INTERNET__":
                    self.showToast(message)
                    // 🔴 tutup aplikasi
                    exit(0)
                    
                default:
                    self.showToast(message)
                    self.dismiss(animated: true)
                }
            },
            onLoading: { [weak self] loading in
                if loading {
                    self?.showLoading()
                } else {
                    self?.hideLoading()
                }
            }
        )
    }
    
    // MARK: - Office Data Ready
    
    private func isOfficeReady() -> Bool {
        return officeLat != nil && officeLon != nil && jam != nil && !jam!.isEmpty
    }
    
    // MARK: - Fetch Office Data
    
    private func fetchOfficeData() {
        let authManager = AuthManager(purnomo: "api/ceka")
        
        authManager.checkAuth(
            onSuccess: { [weak self] json in
                guard let self = self else { return }
                
                guard let aesKey = json["aes_key"] as? String,
                      let latitudeEncrypted = json["latitude"] as? String,
                      let longitudeEncrypted = json["longitude"] as? String,
                      let jamEncrypted = json["jam"] as? String else {
                    self.showToast("Data tidak valid")
                    return
                }
                
                // Decrypt data
                let latitude = CryptoAES.decrypt(latitudeEncrypted, aesKey)
                let longitude = CryptoAES.decrypt(longitudeEncrypted, aesKey)
                let jamDecrypt = CryptoAES.decrypt(jamEncrypted, aesKey)
                
                guard !latitude.isEmpty, !longitude.isEmpty, !jamDecrypt.isEmpty else {
                    self.showToast("Gagal decrypt data")
                    return
                }
                
                self.officeLat = Double(latitude)
                self.officeLon = Double(longitude)
                self.jam = jamDecrypt
                
                if let lat = self.officeLat, let lon = self.officeLon {
                    self.absensiManager.setLokasiKantor(lat: lat, lon: lon)
                }
                
                // AKTIFKAN FLOW
                self.btMulai.isEnabled = true
                self.btMulai.setTitle("Mulai", for: .normal)
            },
            onLogout: { [weak self] message in
                self?.showToast(message)
            },
            onLoading: { [weak self] loading in
                if loading {
                    self?.showLoading()
                } else {
                    self?.hideLoading()
                }
            }
        )
    }
    
    // MARK: - Helper
    
    private func showToast(_ message: String) {
        let alert = UIAlertController(title: "Informasi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func navigateToHome() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let homeVC = Home()
            window.rootViewController = homeVC
            window.makeKeyAndVisible()
            
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
        }
    }
    
    private func navigateToMainActivity() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let mainVC = MainActivity()
            window.rootViewController = mainVC
            window.makeKeyAndVisible()
        }
    }
}
