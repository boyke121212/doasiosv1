//
//  AbsenDinas.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 25/04/26.
//

import UIKit
import AVFoundation

class AbsenDik: Boyke,UITextFieldDelegate {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var isCapturing = false
    // Overlay
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 255/255, green: 152/255, blue: 0/255, alpha: 0.4) // #67FF9800
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
        label.text = "Ambil Foto Surat Keterangan DIK"
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
    
    private let frameLayout = UIView()
    
    private let ivFoto = UIView() // PreviewView untuk camera
    
    private let ivResult: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .lightGray
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 18
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
    
    // Keterangan Layout
    private let layoutKeterangan: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        return view
    }()
    
    private let labelKeterangan: UILabel = {
        let label = UILabel()
        label.text = "Keterangan DIK"
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    private let etDinas: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 15)
        tv.layer.borderColor = UIColor.lightGray.cgColor
        tv.layer.borderWidth = 1
        tv.layer.cornerRadius = 8
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return tv
    }()
    
    // Tanggal Layout
    private let layoutTanggal = UIStackView()
    
    private let etTanggalMulai: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Mulai"
        tf.borderStyle = .roundedRect
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.layer.borderWidth = 1
        tf.layer.cornerRadius = 8
        
        // Add calendar icon
        let iconView = UIImageView(image: UIImage(systemName: "calendar"))
        iconView.tintColor = .gray
        iconView.contentMode = .scaleAspectFit
        iconView.frame = CGRect(x: 0, y: 0, width: 30, height: 20)
        tf.rightView = iconView
        tf.rightViewMode = .always
        
        return tf
    }()
    
    private let etTanggalSelesai: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Selesai"
        tf.borderStyle = .roundedRect
        tf.layer.borderColor = UIColor.lightGray.cgColor
        tf.layer.borderWidth = 1
        tf.layer.cornerRadius = 8
        
        // Add calendar icon
        let iconView = UIImageView(image: UIImage(systemName: "calendar"))
        iconView.tintColor = .gray
        iconView.contentMode = .scaleAspectFit
        iconView.frame = CGRect(x: 0, y: 0, width: 30, height: 20)
        tf.rightView = iconView
        tf.rightViewMode = .always
        
        return tf
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
    private var tanggalMulaiMillis: Int64 = 0
    private var tanggalSelesaiMillis: Int64 = 0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
        setupAbsensiManager()
        setupActions()
        
        // Default state
        btnSwitch.isHidden = true
        
        // Dismiss keyboard on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        etTanggalMulai.tintColor = .clear
        etTanggalSelesai.tintColor = .clear

        etTanggalMulai.keyboardType = .default
        etTanggalSelesai.keyboardType = .default
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
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
        layoutKeterangan.addSubview(etDinas)
        contentView.addSubview(layoutKeterangan)
        
        // Tanggal
        layoutTanggal.axis = .horizontal
        layoutTanggal.distribution = .fillEqually
        layoutTanggal.spacing = 8
        layoutTanggal.addArrangedSubview(etTanggalMulai)
        layoutTanggal.addArrangedSubview(etTanggalSelesai)
        contentView.addSubview(layoutTanggal)
        
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
        etDinas.translatesAutoresizingMaskIntoConstraints = false
        layoutTanggal.translatesAutoresizingMaskIntoConstraints = false
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
            
            etDinas.topAnchor.constraint(equalTo: labelKeterangan.bottomAnchor, constant: 8),
            etDinas.leadingAnchor.constraint(equalTo: layoutKeterangan.leadingAnchor, constant: 12),
            etDinas.trailingAnchor.constraint(equalTo: layoutKeterangan.trailingAnchor, constant: -12),
            etDinas.heightAnchor.constraint(equalToConstant: 150),
            etDinas.bottomAnchor.constraint(equalTo: layoutKeterangan.bottomAnchor, constant: -12),
            
            // Layout Tanggal
            layoutTanggal.topAnchor.constraint(equalTo: layoutKeterangan.bottomAnchor, constant: 16),
            layoutTanggal.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            layoutTanggal.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            layoutTanggal.heightAnchor.constraint(equalToConstant: 44),
            
            // Layout Button
            layoutButton.topAnchor.constraint(equalTo: layoutTanggal.bottomAnchor, constant: 16),
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
        
        // Date pickers
        etTanggalMulai.addTarget(self, action: #selector(showTanggalMulaiPicker), for: .editingDidBegin)
        etTanggalSelesai.addTarget(self, action: #selector(showTanggalSelesaiPicker), for: .editingDidBegin)
        etTanggalMulai.delegate = self
        etTanggalSelesai.delegate = self
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
        navigateToHome()
    }
    
    @objc private func showTanggalMulaiPicker() {
        DatePickerHelper.show(
            on: self,
            textField: etTanggalMulai,
            defaultDate: Date(),
            minDate: Date()
        ) { [weak self] millis in
            guard let self = self else { return }
            
            self.tanggalMulaiMillis = millis
            
            // Auto fill tanggal selesai
            self.tanggalSelesaiMillis = millis
            self.etTanggalSelesai.text = self.etTanggalMulai.text
        }
    }
    
    @objc private func showTanggalSelesaiPicker() {
        if tanggalMulaiMillis == 0 {
            showToast("Pilih tanggal mulai dulu")
            return
        }
        
        let minDate = DatePickerHelper.millisToDate(tanggalMulaiMillis)
        
        DatePickerHelper.show(
            on: self,
            textField: etTanggalSelesai,
            defaultDate: minDate,
            minDate: minDate
        ) { [weak self] millis in
            guard let self = self else { return }
            self.tanggalSelesaiMillis = millis
        }
    }
    
    // MARK: - Flow State
    
    private func startFlow() {
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
        let ketdin = etDinas.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if ketdin.isEmpty {
            showToast("Masukan Keterangan DIK dulu")
            return
        }
        
        if tanggalMulaiMillis == 0 || tanggalSelesaiMillis == 0 {
            showToast("Pilih tanggal DIK dulu")
            return
        }
        
        guard let file = absensiManager.capturedFile,
              FileManager.default.fileExists(atPath: file.path) else {
            showToast("Ambil foto Surat Keterangan DIK dulu")
            return
        }
        
        // Compress image
        guard let image = UIImage(contentsOfFile: file.path),
              let data = image.jpegData(compressionQuality: 0.2) else {
            showToast("Gagal proses foto")
            return
        }
        
        let compressedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".jpg")
        
        try? data.write(to: compressedURL)
        
        print("🔍 [ABSEN Dinas] Compressed file size: \(data.count) bytes")
        
        var params: [String: String] = [
            "menu": "DIK",
            "tanggal_mulai": String(tanggalMulaiMillis),
            "tanggal_selesai": String(tanggalSelesaiMillis),
            "ketam": ketdin
        ]
        
        // 🔐 ANTI-REPLAY
        params["__ts"] = String(Int(Date().timeIntervalSince1970))
        params["__nonce"] = UUID().uuidString
        
        print("🔍 [ABSEN DIK] Params: \(params)")
        
        let authManager = AuthManager(purnomo: "api/absen")
        
        authManager.uploadFoto(
            files: [compressedURL],
            params: params,
            onSuccess: { [weak self] json in
                guard let self = self else { return }
                
                print("✅ [ABSEN Dinas] Upload SUCCESS!")
                print("✅ [ABSEN Dinas] Response: \(json)")
                
                let status = json["status"] as? String ?? ""
                let message = json["message"] as? String ?? "Berhasil"
                
                self.absensiManager.stop()
                
                if status == "ok" {
                    let alert = UIAlertController(title: "Sukses", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.navigateToMainActivity()
                    })
                    self.present(alert, animated: true)
                } else {
                    self.showToast(message)
                }
            },
            onError: { [weak self] message in
                guard let self = self else { return }
                
                print("❌ [ABSEN DIK] Upload ERROR: \(message)")
                
                self.showToast(message)
                self.navigateToMainActivity()
            },
            onLogout: { [weak self] message in
                guard let self = self else { return }
                
                print("🔐 [ABSEN DIK] Upload LOGOUT: \(message)")
                
                switch message {
                case "Verification failed", "__TIMEOUT__", "__NO_INTERNET__":
                    self.showToast(message)
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
    
    // MARK: - UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == etTanggalMulai || textField == etTanggalSelesai {
            return false
        }
        return true
    }
}
