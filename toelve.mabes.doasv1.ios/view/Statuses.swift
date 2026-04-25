//
//  Statuses.swift
//  Doas
//
//  Created by Admin on 06/03/26.
//

import UIKit

// MARK: - Statuses ViewController
class Statuses: Boyke, UIScrollViewDelegate {

    private let headerView = UIView()
    private let pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    private let tvJudul = UILabel()
    private let tvIsi = UILabel()

    private let tabMenu = UIStackView()
    private let btAbsen = UIButton(type: .system)
    private let btStatus = UIButton(type: .system)
    private let btBerita = UIButton(type: .system)
    private let btLog = UIButton(type: .system)
    private let btDoas = UIButton(type: .system)

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Status Card Components
    private let cardStatus = UIView()
    private let tvTanggal = UILabel()
    private let tvKet = UILabel()
    private let tvSubdit = UILabel()
    private let tvJam = UILabel()
    private let tvLat = UILabel()

    private let tvLabelR = UILabel()
    private let tvRange = UILabel()

    private let tvLabelKR = UILabel()
    private let tvKetam = UILabel()

    private let tvLabelT = UILabel()
    private let tvTipe = UILabel()

    private let tvLabelN = UILabel()
    private let tvNama = UILabel()

    private let tvLabelJ = UILabel()
    private let tvJabatan = UILabel()

    private let tvLabelP = UILabel()
    private let tvPangkat = UILabel()

    private let imgFoto = UIImageView()
    private let btnPulang = UIButton(type: .system)

    private var beritaItems: [BeritaItem] = []
    private var timer: Timer?
    private var currentIndex = 0
    private var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)
        setupLayout()
        setupActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadStatusData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }

    private func setupLayout() {
        // 1. Header (Hero Section)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .darkGray
        view.addSubview(headerView)

        addChild(pageController)
        headerView.addSubview(pageController.view)
        pageController.view.translatesAutoresizingMaskIntoConstraints = false
        pageController.didMove(toParent: self)

        tvJudul.textColor = .white
        tvJudul.font = .boldSystemFont(ofSize: 18)
        tvJudul.text = "D.O.A.S"

        tvIsi.textColor = .lightGray
        tvIsi.font = .systemFont(ofSize: 13)
        tvIsi.text = "DITTIPIDTER BARESKRIM"
        tvIsi.numberOfLines = 2

        let heroStack = UIStackView(arrangedSubviews: [tvJudul, tvIsi])
        heroStack.axis = .vertical
        heroStack.spacing = 4
        heroStack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(heroStack)

        // 2. Tab Menu (Sticky below header)
        tabMenu.axis = .horizontal
        tabMenu.distribution = .fillEqually
        tabMenu.backgroundColor = .white
        tabMenu.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabMenu)

        configureTabButton(btAbsen, title: "Absen")
        configureTabButton(btStatus, title: "Status", isActive: true)
        configureTabButton(btBerita, title: "Berita")
        configureTabButton(btLog, title: "Log")
        configureTabButton(btDoas, title: "DOAS")

        tabMenu.addArrangedSubview(btAbsen)
        tabMenu.addArrangedSubview(btStatus)
        tabMenu.addArrangedSubview(btBerita)
        tabMenu.addArrangedSubview(btLog)
        tabMenu.addArrangedSubview(btDoas)

        // 3. ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        // 4. Status Card
        setupStatusCard()

        let cg = scrollView.contentLayoutGuide
        let fg = scrollView.frameLayoutGuide

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 300),

            pageController.view.topAnchor.constraint(equalTo: headerView.topAnchor),
            pageController.view.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            pageController.view.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            pageController.view.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),

            heroStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            heroStack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            heroStack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),

            tabMenu.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tabMenu.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabMenu.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabMenu.heightAnchor.constraint(equalToConstant: 52),

            scrollView.topAnchor.constraint(equalTo: tabMenu.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: cg.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: cg.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: cg.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: cg.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: fg.widthAnchor),

            cardStatus.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            cardStatus.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardStatus.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardStatus.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    private func setupStatusCard() {
        cardStatus.translatesAutoresizingMaskIntoConstraints = false
        cardStatus.backgroundColor = .white
        cardStatus.layer.cornerRadius = 16
        cardStatus.layer.shadowColor = UIColor.black.cgColor
        cardStatus.layer.shadowOpacity = 0.1
        cardStatus.layer.shadowRadius = 8
        cardStatus.layer.shadowOffset = CGSize(width: 0, height: 4)
        contentView.addSubview(cardStatus)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        cardStatus.addSubview(stack)

        // Row 1: Tanggal & Keterangan
        let row1 = UIStackView()
        row1.axis = .horizontal
        row1.distribution = .equalSpacing

        tvTanggal.font = .boldSystemFont(ofSize: 14)
        tvTanggal.textColor = UIColor(hex: "#111827")

        tvKet.font = .boldSystemFont(ofSize: 13)
        tvKet.textColor = UIColor(hex: "#16A34A")

        row1.addArrangedSubview(tvTanggal)
        row1.addArrangedSubview(tvKet)
        stack.addArrangedSubview(row1)

        // Subdit
        tvSubdit.font = .boldSystemFont(ofSize: 13)
        tvSubdit.textColor = UIColor(hex: "#16A34A")
        tvSubdit.textAlignment = .right
        stack.addArrangedSubview(tvSubdit)

        // Jam
        tvJam.font = .systemFont(ofSize: 12)
        tvJam.textColor = UIColor(hex: "#475569")
        stack.addArrangedSubview(tvJam)

        // Lat Long
        tvLat.font = .systemFont(ofSize: 12)
        tvLat.textColor = UIColor(hex: "#475569")
        tvLat.numberOfLines = 0
        stack.addArrangedSubview(tvLat)

        // Tanggal Efektif (Range)
        addLabelValue(stack, label: tvLabelR, value: tvRange, labelText: "Tanggal efektif")

        // Keterangan Tambahan
        addLabelValue(stack, label: tvLabelKR, value: tvKetam, labelText: "Keterangan Tambahan")

        // Tipe Izin
        addLabelValue(stack, label: tvLabelT, value: tvTipe, labelText: "Tipe Izin")

        // Nama Pimpinan
        addLabelValue(stack, label: tvLabelN, value: tvNama, labelText: "Nama Pimpinan")

        // Jabatan Pimpinan
        addLabelValue(stack, label: tvLabelJ, value: tvJabatan, labelText: "Jabatan Pimpinan")

        // Pangkat Pimpinan
        addLabelValue(stack, label: tvLabelP, value: tvPangkat, labelText: "Pangkat Pimpinan")

        // Foto
        imgFoto.contentMode = .scaleAspectFit
        imgFoto.clipsToBounds = true
        imgFoto.translatesAutoresizingMaskIntoConstraints = false
        imgFoto.heightAnchor.constraint(lessThanOrEqualToConstant: 400).isActive = true
        stack.addArrangedSubview(imgFoto)

        // Button Pulang
        btnPulang.setTitle("Absen Pulang", for: .normal)
        btnPulang.setTitleColor(.white, for: .normal)
        btnPulang.backgroundColor = UIColor(hex: "#2563EB")
        btnPulang.layer.cornerRadius = 8
        btnPulang.titleLabel?.font = .boldSystemFont(ofSize: 14)
        btnPulang.translatesAutoresizingMaskIntoConstraints = false
        btnPulang.heightAnchor.constraint(equalToConstant: 44).isActive = true
        stack.addArrangedSubview(btnPulang)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cardStatus.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: cardStatus.bottomAnchor, constant: -18),
            stack.leadingAnchor.constraint(equalTo: cardStatus.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: cardStatus.trailingAnchor, constant: -18)
        ])
    }

    private func addLabelValue(_ stack: UIStackView, label: UILabel, value: UILabel, labelText: String) {
        label.text = labelText
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .black

        value.font = .systemFont(ofSize: 12)
        value.textColor = UIColor(hex: "#475569")
        value.numberOfLines = 0

        stack.addArrangedSubview(label)
        stack.addArrangedSubview(value)
    }

    private func configureTabButton(_ button: UIButton, title: String, isActive: Bool = false) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: isActive ? .bold : .regular)
        if isActive {
            button.setTitleColor(UIColor(hex: "#0C1F91"), for: .normal)
            button.backgroundColor = UIColor(hex: "#E2E8F0")
        } else {
            button.setTitleColor(.darkGray, for: .normal)
        }
    }

    private func setupActions() {
        btAbsen.addTarget(self, action: #selector(onTapAbsen), for: .touchUpInside)
        btBerita.addTarget(self, action: #selector(onTapBerita), for: .touchUpInside)
        btLog.addTarget(self, action: #selector(onTapLog), for: .touchUpInside)
        btDoas.addTarget(self, action: #selector(onTapDoas), for: .touchUpInside)
        btnPulang.addTarget(self, action: #selector(onTapPulang), for: .touchUpInside)
    }

    @objc private func onTapAbsen() { openPage(Home()) }
    @objc private func onTapBerita() { openPage(BeritaViewController()) }
    @objc private func onTapLog() { openPage(History()) }
    @objc private func onTapDoas() { openPage(Doas()) }

    @objc private func onTapPulang() {
        AuthManager(purnomo: "api/pulang").checkAuth(
            params: [:],
            onSuccess: { [weak self] json in
                if (json["status"] as? String) == "ok" {
                    DispatchQueue.main.async {
                        self?.loadStatusData()
                    }
                }
            },
            onLogout: { _ in },
            onLoading: { [weak self] loading in
                DispatchQueue.main.async { if loading { self?.showLoading() } else { self?.hideLoading() } }
            }
        )
    }

    private func loadStatusData() {
        AuthManager(purnomo: "api/ambil_absen").checkAuth(
            params: [:],
            onSuccess: { [weak self] json in
                guard let self = self else { return }
                let aesKey = json["aes_key"] as? String ?? ""

                // Handle Berita for Pager
                var items: [BeritaItem] = []
                if let arr = json["berita"] as? [[String: Any]] {
                    for obj in arr {
                        items.append(BeritaItem(
                            id: obj["id"] as? String ?? "",
                            judul: CryptoAES.decrypt(obj["judul"] as? String ?? "", aesKey),
                            isi: CryptoAES.decrypt(obj["isi"] as? String ?? "", aesKey),
                            tanggal: obj["tanggal"] as? String ?? "",
                            foto: CryptoAES.decrypt(obj["foto"] as? String ?? "", aesKey),
                            pdf: CryptoAES.decrypt(obj["pdf"] as? String ?? "", aesKey)
                        ))
                    }
                }

                // Handle Absensi Data
                if let arr = json["dataabsen"] as? [[String: Any]], let obj = arr.first {
                    DispatchQueue.main.async {
                        self.renderAbsensi(obj, aesKey: aesKey)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.openPage(Home()) // Belum absen hari ini
                    }
                }

                DispatchQueue.main.async {
                    self.beritaItems = items
                    self.setupPager()
                    self.startTimer()
                }
            },
            onLogout: { _ in },
            onLoading: { [weak self] loading in
                DispatchQueue.main.async { if loading { self?.showLoading() } else { self?.hideLoading() } }
            }
        )
    }

    private func renderAbsensi(_ obj: [String: Any], aesKey: String) {
        resetView()

        let tanggal = decrypt(obj, "tanggal", aesKey)
        let selesai = decrypt(obj, "selesai", aesKey)
        let masuk = decrypt(obj, "masuk", aesKey)
        let pulang = decrypt(obj, "pulang", aesKey)
        let ket = decrypt(obj, "keterangan", aesKey).uppercased()
        let lat = decrypt(obj, "latitude", aesKey)
        let lng = decrypt(obj, "longitude", aesKey)
        let ketam = decrypt(obj, "ketam", aesKey)
        let tipeizin = decrypt(obj, "tipeizin", aesKey)
        let namaPimpinan = decrypt(obj, "namapimpinan", aesKey)
        let jabatan = decrypt(obj, "jabatan", aesKey)
        let pangkat = decrypt(obj, "pangkat", aesKey)
        let foto = decrypt(obj, "foto", aesKey)
        let subdit = decrypt(obj, "subdit", aesKey)

        tvTanggal.text = tanggal
        tvKet.text = ket

        switch ket {
        case "HADIR", "TERLAMBAT":
            tvJam.text = "Masuk: \(masuk) | Pulang: \(pulang.isEmpty ? "-" : pulang)"
            if !lat.isEmpty && !lng.isEmpty {
                tvLat.isHidden = false
                tvLat.text = "Latitude: \(lat) | Longitude: \(lng)"
            }
            if !foto.isEmpty {
                imgFoto.isHidden = false
                loadFoto(foto)
            }
            if !subdit.isEmpty {
                tvSubdit.isHidden = false
                tvSubdit.text = "(\(subdit))"
            }

            if !pulang.isEmpty {
                tvKet.text = "PULANG"
                tvKet.textColor = UIColor(hex: "#2563EB")
                btnPulang.isHidden = true
            } else {
                tvKet.text = ket
                tvKet.textColor = UIColor(hex: "#16A34A")
                btnPulang.isHidden = false
            }

        case "LD":
            tvJam.text = "Jam Absen: \(masuk)"
            if !ketam.isEmpty {
                tvLabelKR.isHidden = false
                tvKetam.isHidden = false
                tvKetam.text = ketam
            }
            if !subdit.isEmpty {
                tvSubdit.isHidden = false
                tvSubdit.text = "(\(subdit))"
            }
            if !foto.isEmpty {
                imgFoto.isHidden = false
                loadFoto(foto)
            }

        case "CUTI", "SAKIT", "DIK", "DINAS", "BKO":
            tvJam.text = "Jam Absen: \(masuk)"
            tvLabelR.isHidden = false
            tvRange.isHidden = false
            tvRange.text = "Mulai: \(tanggal) | Selesai: \(selesai)"
            if !subdit.isEmpty {
                tvSubdit.isHidden = false
                tvSubdit.text = "(\(subdit))"
            }
            if !ketam.isEmpty {
                tvLabelKR.isHidden = false
                tvKetam.isHidden = false
                tvKetam.text = ketam
            }
            if !foto.isEmpty {
                imgFoto.isHidden = false
                loadFoto(foto)
            }

        case "IZIN":
            tvJam.text = "Jam Absen: \(masuk)"
            if !subdit.isEmpty {
                tvSubdit.isHidden = false
                tvSubdit.text = "(\(subdit))"
            }
            tvLabelT.isHidden = false
            tvTipe.isHidden = false
            tvTipe.text = tipeizin
            if !ketam.isEmpty {
                tvLabelKR.isHidden = false
                tvKetam.isHidden = false
                tvKetam.text = ketam
            }
            if tipeizin == "PIMPINAN" {
                tvKet.text = "IZIN PIMPINAN"
                tvLabelN.isHidden = false; tvNama.isHidden = false; tvNama.text = namaPimpinan
                tvLabelJ.isHidden = false; tvJabatan.isHidden = false; tvJabatan.text = jabatan
                tvLabelP.isHidden = false; tvPangkat.isHidden = false; tvPangkat.text = pangkat
            } else {
                tvKet.text = "IZIN RESMI"
            }
            if !foto.isEmpty {
                imgFoto.isHidden = false
                loadFoto(foto)
            }
        default: break
        }
    }

    private func resetView() {
        tvLat.isHidden = true
        tvLabelR.isHidden = true
        tvRange.isHidden = true
        tvLabelKR.isHidden = true
        tvKetam.isHidden = true
        tvLabelT.isHidden = true
        tvTipe.isHidden = true
        tvLabelN.isHidden = true
        tvNama.isHidden = true
        tvLabelJ.isHidden = true
        tvJabatan.isHidden = true
        tvLabelP.isHidden = true
        tvPangkat.isHidden = true
        imgFoto.isHidden = true
        btnPulang.isHidden = true
        tvSubdit.isHidden = true
    }

    private func loadFoto(_ file: String) {
        let token = SecurePrefs.shared.getAccessToken() ?? ""
        let urlStr = AppConfig2.BASE_URL + "api/media/absensi/" + file
        if let url = URL(string: urlStr) {
            imgFoto.loadImage(url: url, token: token, placeholder: UIImage(named: "logodit"))
        }
    }

    private func decrypt(_ obj: [String: Any], _ field: String, _ key: String) -> String {
        let value = obj[field] as? String ?? ""
        return (value.isEmpty || value == "null") ? "" : CryptoAES.decrypt(value, key)
    }

    private func onBeritaChanged(_ berita: BeritaItem) {
        tvJudul.text = berita.judul
        if let data = berita.isi.data(using: .utf8) {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
                let mutableAttr = NSMutableAttributedString(attributedString: attributed)
                mutableAttr.addAttribute(.foregroundColor, value: UIColor.lightGray, range: NSRange(location: 0, length: mutableAttr.length))
                tvIsi.attributedText = mutableAttr
            } else {
                tvIsi.text = berita.isi.hendry_htmlToPlain2()
            }
        } else {
            tvIsi.text = berita.isi.hendry_htmlToPlain2()
        }
    }

    private func setupPager() {
        pageController.dataSource = self
        pageController.delegate = self
        if let firstVC = viewControllerAtIndex(0) {
            pageController.setViewControllers([firstVC], direction: .forward, animated: true)
            if let first = beritaItems.first { onBeritaChanged(first) }
        }
    }

    private func viewControllerAtIndex(_ index: Int) -> BannerPageViewController? {
        var idx = index
        if idx < 0 { idx = beritaItems.count - 1 }
        if idx >= beritaItems.count { idx = 0 }
        guard !beritaItems.isEmpty else { return nil }
        let vc = BannerPageViewController()
        vc.banner = beritaItems[idx]
        vc.index = idx
        return vc
    }

    private func startTimer() {
        timer?.invalidate()
        guard beritaItems.count > 1 else { return }
        let t = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.slideNext()
        }
        timer = t
        RunLoop.main.add(t, forMode: .common)
    }

    private func slideNext() {
        guard !beritaItems.isEmpty else { return }
        let nextIndex = (currentIndex + 1) % beritaItems.count
        if let nextVC = viewControllerAtIndex(nextIndex) {
            pageController.setViewControllers([nextVC], direction: .forward, animated: true) { [weak self] finished in
                if finished {
                    self?.currentIndex = nextIndex
                    if let item = self?.beritaItems[nextIndex] {
                        self?.onBeritaChanged(item)
                    }
                }
            }
        }
    }
}

extension Statuses: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? BannerPageViewController else { return nil }
        return viewControllerAtIndex(vc.index - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let vc = viewController as? BannerPageViewController else { return nil }
        return viewControllerAtIndex(vc.index + 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let currentVC = pageViewController.viewControllers?.first as? BannerPageViewController {
            currentIndex = currentVC.index
            onBeritaChanged(beritaItems[currentIndex])
            startTimer()
        }
    }
}
