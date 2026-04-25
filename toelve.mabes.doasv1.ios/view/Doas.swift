//
//  Doas.swift
//  Doas
//
//  Created by Admin on 06/03/26.
//

import UIKit

// MARK: - Doas ViewController
class Doas: Boyke, UIScrollViewDelegate {

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

    // Main Content
    private let tvAtas = UILabel()
    private let scrollView = UIScrollView()
    private let tvDoasContent = UILabel()
    private let btDownload = UIButton(type: .system)

    private var beritaItems: [BeritaItem] = []
    private var timer: Timer?
    private var currentIndex = 0
    private var pdfFileName = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        setupActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDoasData()
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
        configureTabButton(btStatus, title: "Status")
        configureTabButton(btBerita, title: "Berita")
        configureTabButton(btLog, title: "Log")
        configureTabButton(btDoas, title: "DOAS", isActive: true)

        tabMenu.addArrangedSubview(btAbsen)
        tabMenu.addArrangedSubview(btStatus)
        tabMenu.addArrangedSubview(btBerita)
        tabMenu.addArrangedSubview(btLog)
        tabMenu.addArrangedSubview(btDoas)

        // 3. DOAS Content
        tvAtas.translatesAutoresizingMaskIntoConstraints = false
        tvAtas.font = .boldSystemFont(ofSize: 18)
        tvAtas.textAlignment = .center
        tvAtas.textColor = .black
        tvAtas.numberOfLines = 0
        view.addSubview(tvAtas)

        btDownload.translatesAutoresizingMaskIntoConstraints = false
        btDownload.setTitle("Download PDF", for: .normal)
        btDownload.setTitleColor(.white, for: .normal)
        btDownload.backgroundColor = UIColor(hex: "#2563EB")
        btDownload.layer.cornerRadius = 8
        btDownload.titleLabel?.font = .boldSystemFont(ofSize: 16)
        view.addSubview(btDownload)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        tvDoasContent.translatesAutoresizingMaskIntoConstraints = false
        tvDoasContent.font = .systemFont(ofSize: 14)
        tvDoasContent.textColor = .black
        tvDoasContent.numberOfLines = 0
        scrollView.addSubview(tvDoasContent)

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

            tvAtas.topAnchor.constraint(equalTo: tabMenu.bottomAnchor, constant: 16),
            tvAtas.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tvAtas.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            btDownload.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            btDownload.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            btDownload.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            btDownload.heightAnchor.constraint(equalToConstant: 50),

            scrollView.topAnchor.constraint(equalTo: tvAtas.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: btDownload.topAnchor, constant: -8),

            tvDoasContent.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            tvDoasContent.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 8),
            tvDoasContent.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -8),
            tvDoasContent.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -8),
            tvDoasContent.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -16)
        ])
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
        btStatus.addTarget(self, action: #selector(onTapStatus), for: .touchUpInside)
        btBerita.addTarget(self, action: #selector(onTapBerita), for: .touchUpInside)
        btLog.addTarget(self, action: #selector(onTapLog), for: .touchUpInside)
        btDownload.addTarget(self, action: #selector(onTapDownload), for: .touchUpInside)
    }

    @objc private func onTapAbsen() { openPage(Home()) }
    @objc private func onTapStatus() { openPage(Statuses()) }
    @objc private func onTapBerita() { openPage(BeritaViewController()) }
    @objc private func onTapLog() { openPage(History()) }

    @objc private func onTapDownload() {
        guard !pdfFileName.isEmpty else { return }
        let token = SecurePrefs.shared.getAccessToken() ?? ""
        let urlStr = AppConfig2.BASE_URL + "api/media/pdf/" + pdfFileName

        PdfDownloader.download(
            url: urlStr,
            filename: pdfFileName,
            token: token,
            from: self
        ) { _ in }
    }

    private func loadDoasData() {
        AuthManager(purnomo: "api/getdoas").checkAuth(
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

                let judul = CryptoAES.decrypt(json["judul"] as? String ?? "", aesKey)
                let isi = CryptoAES.decrypt(json["isi"] as? String ?? "", aesKey)
                let pdf = CryptoAES.decrypt(json["pdf"] as? String ?? "", aesKey)

                DispatchQueue.main.async {
                    self.beritaItems = items
                    self.pdfFileName = pdf
                    self.tvAtas.text = judul
                    self.tvDoasContent.text = isi.hendry_htmlToPlain2()
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

extension Doas: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
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
