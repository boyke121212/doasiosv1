//
//  AbsenIzin.swift
//  toelve.mabes.doasv1.ios
//
//  Created by Admin on 25/04/26.
//

import UIKit
import AVFoundation

class AbsenIzin: Boyke {
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private var isCapturing = false

    // Overlay (warna mengikuti Android #94FFEB3B kira-kira)
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.0, green: 0.92, blue: 0.23, alpha: 0.58)
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
        label.text = "Foto Surat Izin Anda"
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .bold)
        return label
    }()

    // Card Camera (Container untuk foto, tanpa rounded corner seperti Android)
    private let cardCameraView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.clipsToBounds = true
        return view
    }()

    private let frameLayout = UIView()
    private let ivFoto = UIView() // PreviewView untuk camera
    private let ivResult: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.backgroundColor = .lightGray
        iv.clipsToBounds = true
        iv.image = UIImage(systemName: "camera.fill")
        iv.tintColor = .gray
        iv.isHidden = true
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

    // Form Card (untuk spinner/segmented + keterangan + field pimpinan + buttons)
    private let layoutKeterangan: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 28 // sesuai Android cardCornerRadius="28dp"
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.15
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.layer.shadowRadius = 12
        view.clipsToBounds = false
        return view
    }()

    private let labelTipe: UILabel = {
        let label = UILabel()
        label.text = "Tipe Izin"
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        return label
    }()
    
    private let labelKeterangan: UILabel = {
        let label = UILabel()
        label.text = "Keterangan Izin"
        label.font = .systemFont(ofSize: 15, weight: .bold)
        label.textColor = .black
        return label
    }()

    private let tipeSegment: UISegmentedControl = {
        let seg = UISegmentedControl(items: ["RESMI", "PIMPINAN"])
        seg.selectedSegmentIndex = 0
        return seg
    }()

    private let etIzin: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 15)
        tv.layer.borderColor = UIColor.lightGray.cgColor
        tv.layer.borderWidth = 1
        tv.layer.cornerRadius = 8
        tv.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return tv
    }()

    private let pimpinanStack = UIStackView()
    private let etNamaPimpinan = UITextField()
    private let etJabatanPimpinan = UITextField()
    private let etPangkatPimpinan = UITextField()

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
        label.text = "Informasi: dengan mengirim, Anda menyetujui pemrosesan data untuk keperluan absensi."
        label.textColor = UIColor(white: 0.98, alpha: 1)
        label.font = .systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Properties
    private var absensiManager: AbsensiManager!
    private var menu = "mulai"
    private var isPimpinan: Bool { tipeSegment.selectedSegmentIndex == 1 }
    
    // Constraints untuk dynamic layout
    private var etIzinBottomConstraint: NSLayoutConstraint?
    private var pimpinanStackBottomConstraint: NSLayoutConstraint?
    
    // Constraints untuk dynamic button layout
    private var btMulaiWidthConstraint: NSLayoutConstraint?

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
        btMulai.isEnabled = true
        btMulai.setTitle("Mulai", for: .normal)

        // Dismiss keyboard on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let h = keyboardFrame.height
        scrollView.contentInset.bottom = h
        scrollView.verticalScrollIndicatorInsets.bottom = h
    }
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .black
        view.addSubview(overlayView)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        headerStatusView.addSubview(headerIconView)
        headerStatusView.addSubview(headerLabel)
        contentView.addSubview(headerStatusView)

        frameLayout.addSubview(ivFoto)
        frameLayout.addSubview(ivResult)
        cardCameraView.addSubview(frameLayout)
        contentView.addSubview(cardCameraView)

        contentView.addSubview(btnSwitch)

        // Form
        contentView.addSubview(layoutKeterangan)
        layoutKeterangan.addSubview(labelTipe)
        layoutKeterangan.addSubview(tipeSegment)
        layoutKeterangan.addSubview(labelKeterangan)
        layoutKeterangan.addSubview(etIzin)

        // Pimpinan stack
        pimpinanStack.axis = .vertical
        pimpinanStack.spacing = 8
        etNamaPimpinan.borderStyle = .roundedRect
        etJabatanPimpinan.borderStyle = .roundedRect
        etPangkatPimpinan.borderStyle = .roundedRect
        etNamaPimpinan.placeholder = "Nama Pimpinan"
        etJabatanPimpinan.placeholder = "Jabatan Pimpinan"
        etPangkatPimpinan.placeholder = "Pangkat Pimpinan"
        pimpinanStack.addArrangedSubview(etNamaPimpinan)
        pimpinanStack.addArrangedSubview(etJabatanPimpinan)
        pimpinanStack.addArrangedSubview(etPangkatPimpinan)
        layoutKeterangan.addSubview(pimpinanStack)

        // Buttons
        layoutButton.axis = .horizontal
        layoutButton.distribution = .fill // bukan fillEqually
        layoutButton.spacing = 16
        layoutButton.addArrangedSubview(btMulai)
        layoutButton.addArrangedSubview(btKirim)
        layoutKeterangan.addSubview(layoutButton) // buttons di dalam layoutKeterangan seperti Android

        view.addSubview(tvDisclaimer)

        // Initial visibility
        ivFoto.isHidden = false
        ivResult.isHidden = true
        pimpinanStack.isHidden = true
        labelKeterangan.isHidden = false // visible di mode RESMI
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
        labelTipe.translatesAutoresizingMaskIntoConstraints = false
        labelKeterangan.translatesAutoresizingMaskIntoConstraints = false
        tipeSegment.translatesAutoresizingMaskIntoConstraints = false
        etIzin.translatesAutoresizingMaskIntoConstraints = false
        pimpinanStack.translatesAutoresizingMaskIntoConstraints = false
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

            // Card Camera (380dp height seperti Android)
            cardCameraView.topAnchor.constraint(equalTo: btnSwitch.bottomAnchor, constant: 12),
            cardCameraView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardCameraView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardCameraView.heightAnchor.constraint(equalToConstant: 380),

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

            // Switch Button (pojok kanan atas seperti Android)
            btnSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            btnSwitch.topAnchor.constraint(equalTo: headerStatusView.bottomAnchor, constant: 12),
            btnSwitch.widthAnchor.constraint(equalToConstant: 60),
            btnSwitch.heightAnchor.constraint(equalToConstant: 60),

            // Form card (overlap ke atas -60dp seperti Android)
            layoutKeterangan.topAnchor.constraint(equalTo: cardCameraView.bottomAnchor, constant: -60),
            layoutKeterangan.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 25),
            layoutKeterangan.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -25),

            labelTipe.topAnchor.constraint(equalTo: layoutKeterangan.topAnchor, constant: 24),
            labelTipe.leadingAnchor.constraint(equalTo: layoutKeterangan.leadingAnchor, constant: 24),
            labelTipe.trailingAnchor.constraint(equalTo: layoutKeterangan.trailingAnchor, constant: -24),

            tipeSegment.topAnchor.constraint(equalTo: labelTipe.bottomAnchor, constant: 12),
            tipeSegment.leadingAnchor.constraint(equalTo: layoutKeterangan.leadingAnchor, constant: 24),
            tipeSegment.trailingAnchor.constraint(equalTo: layoutKeterangan.trailingAnchor, constant: -24),

            labelKeterangan.topAnchor.constraint(equalTo: tipeSegment.bottomAnchor, constant: 16),
            labelKeterangan.leadingAnchor.constraint(equalTo: layoutKeterangan.leadingAnchor, constant: 24),
            labelKeterangan.trailingAnchor.constraint(equalTo: layoutKeterangan.trailingAnchor, constant: -24),

            etIzin.topAnchor.constraint(equalTo: labelKeterangan.bottomAnchor, constant: 8),
            etIzin.leadingAnchor.constraint(equalTo: layoutKeterangan.leadingAnchor, constant: 24),
            etIzin.trailingAnchor.constraint(equalTo: layoutKeterangan.trailingAnchor, constant: -24),
            etIzin.heightAnchor.constraint(equalToConstant: 110),

            pimpinanStack.topAnchor.constraint(equalTo: etIzin.bottomAnchor, constant: 16),
            pimpinanStack.leadingAnchor.constraint(equalTo: layoutKeterangan.leadingAnchor, constant: 24),
            pimpinanStack.trailingAnchor.constraint(equalTo: layoutKeterangan.trailingAnchor, constant: -24),

            // Buttons row (di dalam layoutKeterangan, margin top 32 sesuai Android)
            layoutButton.topAnchor.constraint(equalTo: pimpinanStack.bottomAnchor, constant: 32),
            layoutButton.leadingAnchor.constraint(equalTo: layoutKeterangan.leadingAnchor, constant: 24),
            layoutButton.trailingAnchor.constraint(equalTo: layoutKeterangan.trailingAnchor, constant: -24),
            layoutButton.heightAnchor.constraint(equalToConstant: 52),
            layoutButton.bottomAnchor.constraint(equalTo: layoutKeterangan.bottomAnchor, constant: -24),
            
            // ContentView bottom (ada space setelah layoutKeterangan)
            layoutKeterangan.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16),

            // Disclaimer
            tvDisclaimer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            tvDisclaimer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            tvDisclaimer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
        
        // Store constraints untuk dynamic switching
        // Ketika mode RESMI: etIzin adalah elemen terakhir sebelum buttons
        // Ketika mode PIMPINAN: pimpinanStack adalah elemen terakhir sebelum buttons
        let etIzinToButtons = layoutButton.topAnchor.constraint(equalTo: etIzin.bottomAnchor, constant: 32)
        let pimpinanToButtons = layoutButton.topAnchor.constraint(equalTo: pimpinanStack.bottomAnchor, constant: 32)
        
        etIzinBottomConstraint = etIzinToButtons
        pimpinanStackBottomConstraint = pimpinanToButtons
        
        // Button width constraint (untuk dynamic sizing)
        // Mode RESMI: btMulai visible, equal width dengan btKirim
        // Mode PIMPINAN: btMulai hidden, btKirim full width
        btMulaiWidthConstraint = btMulai.widthAnchor.constraint(equalTo: btKirim.widthAnchor)
        
        // Default: RESMI mode (etIzin → buttons, btMulai visible)
        etIzinBottomConstraint?.isActive = true
        pimpinanStackBottomConstraint?.isActive = false
        btMulaiWidthConstraint?.isActive = true
        btMulai.isHidden = false
    }

    private func setupAbsensiManager() {
        absensiManager = AbsensiManager(viewController: self, previewView: ivFoto)
    }

    private func setupActions() {
        btMulai.addTarget(self, action: #selector(onMulaiTapped), for: .touchUpInside)
        btKirim.addTarget(self, action: #selector(onKirimTapped), for: .touchUpInside)
        btnSwitch.addTarget(self, action: #selector(onSwitchTapped), for: .touchUpInside)
        tipeSegment.addTarget(self, action: #selector(onTipeChanged), for: .valueChanged)

        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.left"), style: .plain, target: self, action: #selector(onBackPressed))
    }

    // MARK: - Actions
    @objc private func onMulaiTapped() {
        switch menu.lowercased() {
        case "mulai": startFlow()
        case "capture": captureFlow()
        case "ulangi": resetFlow()
        default: break
        }
    }

    @objc private func onKirimTapped() { onKirim() }

    @objc private func onSwitchTapped() { absensiManager.switchCamera() }

    @objc private func onBackPressed() {
        absensiManager.stop()
        navigateToHome()
    }

    @objc private func onTipeChanged() {
        let resmi = !isPimpinan
        
        // Reset tampilan foto
        ivResult.image = nil
        ivResult.isHidden = true
        ivFoto.isHidden = true // preview blank dulu
        
        // Reset tombol
        menu = "mulai"
        btMulai.setTitle("Mulai", for: .normal)
        absensiManager.capturedFile = nil
        
        // Update UI berdasarkan tipe
        headerLabel.text = resmi ? "Foto Surat Izin Anda" : "Masukan Data Lengkap Pimpinan"
        
        if resmi {
            // MODE RESMI
            // - Camera preview visible
            // - btnSwitch visible
            // - btMulai visible
            // - labelKeterangan visible
            // - pimpinanStack hidden
            // - btKirim & btMulai equal width
            
            pimpinanStack.isHidden = true
            labelKeterangan.isHidden = false
            btnSwitch.isHidden = false
            btMulai.isHidden = false
            
            // Update constraints
            pimpinanStackBottomConstraint?.isActive = false
            etIzinBottomConstraint?.isActive = true
            btMulaiWidthConstraint?.isActive = true
            
            // Tampilkan kamera
            absensiManager.restartPreview()
            ivFoto.isHidden = false
            ivResult.isHidden = true
            
            moveCardUp(false)
            
        } else {
            // MODE PIMPINAN
            // - Camera preview hidden
            // - btnSwitch hidden
            // - btMulai HIDDEN
            // - labelKeterangan HIDDEN
            // - pimpinanStack visible
            // - btKirim full width (btMulai hidden)
            
            pimpinanStack.isHidden = false
            labelKeterangan.isHidden = true
            btnSwitch.isHidden = true
            btMulai.isHidden = true // HIDE tombol Mulai
            
            // Update constraints
            etIzinBottomConstraint?.isActive = false
            pimpinanStackBottomConstraint?.isActive = true
            btMulaiWidthConstraint?.isActive = false
            
            // Matikan kamera
            absensiManager.stop()
            ivFoto.isHidden = true
            ivResult.isHidden = true
            
            moveCardUp(true)
        }
    }
    
    private func moveCardUp(_ up: Bool) {
        let targetY: CGFloat = up ? -70 : 0 // -70 untuk iOS (sesuaikan dari -60dp Android)
        
        UIView.animate(withDuration: 0.25) {
            self.cardCameraView.transform = CGAffineTransform(translationX: 0, y: targetY)
            self.view.layoutIfNeeded()
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
        if isCapturing { return }
        isCapturing = true
        showCaptureLoading()

        absensiManager.capture { [weak self] fileURL in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.hideCaptureLoading()
                self.isCapturing = false
                self.ivFoto.isHidden = true
                self.ivResult.isHidden = false
                if let image = UIImage(contentsOfFile: fileURL.path) { self.ivResult.image = image }
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
        let selected = isPimpinan ? "PIMPINAN" : "RESMI"
        print("selected: \(selected)")
        
        let ketdin = etIzin.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let namapimpinan = etNamaPimpinan.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let jabatan = etJabatanPimpinan.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let pangkat = etPangkatPimpinan.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if ketdin.isEmpty {
            showToast("Masukan Keterangan Izin dulu")
            return
        }
        
        let file = absensiManager.capturedFile
        
        // VALIDASI FOTO HANYA UNTUK RESMI
        if selected == "RESMI" {
            if file == nil || !FileManager.default.fileExists(atPath: file?.path ?? "") {
                showToast("Ambil foto Surat Keterangan dulu")
                return
            }
        }
        
        // PARAMS (dibuat sekali)
        var params: [String: String] = [
            "menu": "IZIN",
            "izin_tipe": selected,  // penting kirim ke backend
            "nama_pimpinan": namapimpinan,
            "jabatan_pimpinan": jabatan,
            "pangkat_pimpinan": pangkat,
            "ketam": ketdin
        ]
        
        // Anti replay
        params["__ts"] = String(Int(Date().timeIntervalSince1970))
        params["__nonce"] = UUID().uuidString
        
        // Siapkan file untuk upload (hanya jika RESMI dan ada file)
        var files: [URL] = []
        if selected == "RESMI", let file = file {
            // Compress
            if let image = UIImage(contentsOfFile: file.path),
               let data = image.jpegData(compressionQuality: 0.2) {
                let compressedURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + ".jpg")
                try? data.write(to: compressedURL)
                files = [compressedURL]
            }
        }
        // Jika PIMPINAN, files tetap kosong (array kosong)

        let auth = AuthManager(purnomo: "api/absen")
        auth.uploadFoto(
            files: files, // boleh kosong kalau PIMPINAN
            params: params,
            onSuccess: { [weak self] json in
                guard let self = self else { return }
                let status = json["status"] as? String ?? ""
                let message = json["message"] as? String ?? "Berhasil"
                
                self.showToast(message)
                self.absensiManager.stop()
                
                if status == "ok" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.navigateToMainActivity()
                    }
                }
            },
            onError: { [weak self] message in
                guard let self = self else { return }
                self.showToast(message)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.navigateToMainActivity()
                }
            },
            onLogout: { [weak self] message in
                guard let self = self else { return }
                self.showToast(message)
                self.dismiss(animated: true)
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
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(alert, animated: true)
        
        // Auto dismiss setelah 2 detik (seperti Toast di Android)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            alert.dismiss(animated: true)
        }
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
            // Navigate ke MainActivity (equivalent dengan Android)
            let mainVC = MainActivity()
            window.rootViewController = mainVC
            window.makeKeyAndVisible()
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
        }
    }
}
