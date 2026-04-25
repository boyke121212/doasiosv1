//
//  History.swift
//  Doas
//
//  Created by Admin on 06/03/26.
//

import UIKit

// MARK: - Extensions


extension String {
    func hendry_htmlToPlain2() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attr = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attr.string
        }
        return self
    }
}

// MARK: - SelfSizingTableView
class SelfSizingTableView2: UITableView {
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}

// MARK: - BannerPageViewController
class BannerPageViewController: UIViewController {
    let imageView = UIImageView()
    var banner: BeritaItem?
    var index: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
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

        if let banner = banner {
            let token = SecurePrefs.shared.getAccessToken() ?? ""
            let urlStr = AppConfig2.BASE_URL + "api/media/berita/" + banner.foto
            if let url = URL(string: urlStr) {
                imageView.loadImage(url: url, token: token, placeholder: UIImage(named: "doas2"))
            }
        }
    }
}

// MARK: - HistoryModel
struct HistoryModel {
    let id: String
    let masuk: String
    let pulang: String
    let selesai: String
    let keterangan: String
    let latitude: String
    let longitude: String
    let ketam: String
    let tipeizin: String
    let namaPimpinan: String
    let jabatan: String
    let pangkat: String
    let foto: String
    let subdit: String
    let tanggal: String
}

// MARK: - HistoryCell
class HistoryCell: UITableViewCell {
    static let reuseId = "HistoryCell"

    private let cardView = UIView()
    private let tvTanggal = UILabel()
    private let tvStatus = UILabel()
    private let tvJam = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupCell()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupCell() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 10
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowRadius = 3
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        contentView.addSubview(cardView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(stack)

        tvTanggal.font = .boldSystemFont(ofSize: 15)
        tvStatus.font = .boldSystemFont(ofSize: 14)
        tvJam.font = .systemFont(ofSize: 13)
        tvJam.numberOfLines = 0

        stack.addArrangedSubview(tvTanggal)
        stack.addArrangedSubview(tvStatus)
        stack.addArrangedSubview(tvJam)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),

            stack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12)
        ])
    }

    func bind(_ d: HistoryModel) {
        tvTanggal.text = d.tanggal
        tvStatus.text = d.keterangan

        if d.keterangan == "HADIR" || d.keterangan == "TERLAMBAT" {
            let masuk = d.masuk.isEmpty ? "-" : d.masuk
            let pulang = d.pulang.isEmpty ? "-" : d.pulang
            tvJam.text = "Masuk \(masuk)   Pulang \(pulang)"
        } else {
            tvJam.text = d.ketam.isEmpty ? "-" : d.ketam
        }
    }
}

// MARK: - History ViewController
class History: Boyke, UIScrollViewDelegate {

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
    private let filterBar = UIView()
    private let btFilter = UIButton(type: .system)

    private let rvHistory = SelfSizingTableView2()
    private let refreshControl = UIRefreshControl()

    private var listHistory: [HistoryModel] = []
    private var lastId = ""
    private var isLoading = false
    private var currentFilter = [String: String]()
    private var beritaItems: [BeritaItem] = []
    private var timer: Timer?
    private var currentIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)
        setupLayout()
        setupActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadBannerViaAuthCheck()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if listHistory.isEmpty { loadHistory() }
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
        configureTabButton(btLog, title: "Log", isActive: true)
        configureTabButton(btDoas, title: "DOAS")

        tabMenu.addArrangedSubview(btAbsen)
        tabMenu.addArrangedSubview(btStatus)
        tabMenu.addArrangedSubview(btBerita)
        tabMenu.addArrangedSubview(btLog)
        tabMenu.addArrangedSubview(btDoas)

        // 3. ScrollView (Starts below tab menu)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        // 4. Content (Filter Bar & TableView)
        filterBar.backgroundColor = .white
        filterBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(filterBar)

        btFilter.setImage(UIImage(named: "ic_filter") ?? UIImage(systemName: "line.3.horizontal.decrease.circle"), for: .normal)
        btFilter.translatesAutoresizingMaskIntoConstraints = false
        filterBar.addSubview(btFilter)

        rvHistory.translatesAutoresizingMaskIntoConstraints = false
        rvHistory.isScrollEnabled = false
        rvHistory.separatorStyle = .none
        rvHistory.backgroundColor = .clear
        rvHistory.register(HistoryCell.self, forCellReuseIdentifier: HistoryCell.reuseId)
        rvHistory.dataSource = self
        rvHistory.delegate = self
        contentView.addSubview(rvHistory)

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

            filterBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            filterBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            filterBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            filterBar.heightAnchor.constraint(equalToConstant: 48),

            btFilter.leadingAnchor.constraint(equalTo: filterBar.leadingAnchor, constant: 8),
            btFilter.centerYAnchor.constraint(equalTo: filterBar.centerYAnchor),
            btFilter.widthAnchor.constraint(equalToConstant: 40),
            btFilter.heightAnchor.constraint(equalToConstant: 40),

            rvHistory.topAnchor.constraint(equalTo: filterBar.bottomAnchor),
            rvHistory.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rvHistory.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rvHistory.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
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
        btDoas.addTarget(self, action: #selector(onTapDoas), for: .touchUpInside)
        btFilter.addTarget(self, action: #selector(onTapFilter), for: .touchUpInside)
    }

    @objc private func onTapAbsen() { openPage(Home()) }
    @objc private func onTapStatus() { openPage(Statuses()) }
    @objc private func onTapBerita() { openPage(BeritaViewController()) }
    @objc private func onTapDoas() { openPage(Doas()) }

    @objc private func onRefresh() {
        guard !isLoading else { refreshControl.endRefreshing(); return }
        lastId = ""
        listHistory.removeAll()
        rvHistory.reloadData()
        loadHistory()
        refreshControl.endRefreshing()
    }

    @objc private func onTapFilter() {
        let sheet = UIAlertController(title: "Filter", message: nil, preferredStyle: .actionSheet)
        let statuses: [(String, String)] = [
            ("Semua", ""), ("Hadir", "HADIR"), ("Terlambat", "TERLAMBAT"),
            ("TK", "TK"), ("LD", "LD"), ("Cuti", "CUTI"), ("DIK", "DIK"),
            ("BKO", "BKO"), ("Dinas", "DINAS"), ("Sakit", "SAKIT"), ("Izin", "IZIN")
        ]

        for (label, value) in statuses {
            sheet.addAction(UIAlertAction(title: label, style: .default) { _ in
                self.applyFilter(status: value, tanggal: nil)
            })
        }

        sheet.addAction(UIAlertAction(title: "Pilih Tanggal...", style: .default) { _ in
            self.showDatePicker()
        })

        sheet.addAction(UIAlertAction(title: "Batal", style: .cancel))
        present(sheet, animated: true)
    }

    private func showDatePicker() {
        let alert = UIAlertController(title: "Pilih Tanggal", message: "\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .wheels
        picker.translatesAutoresizingMaskIntoConstraints = false
        alert.view.addSubview(picker)
        NSLayoutConstraint.activate([
            picker.topAnchor.constraint(equalTo: alert.view.topAnchor, constant: 50),
            picker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor)
        ])
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
            self.applyFilter(status: nil, tanggal: fmt.string(from: picker.date))
        })
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel))
        present(alert, animated: true)
    }

    private func applyFilter(status: String?, tanggal: String?) {
        guard !isLoading else { return }
        if let s = status { currentFilter["status"] = s }
        if let t = tanggal { currentFilter["tanggal"] = t }

        lastId = ""
        listHistory.removeAll()
        rvHistory.reloadData()
        loadHistory(filterParams: currentFilter)
    }

    private func loadHistory(filterParams: [String: String]? = nil) {
        guard !isLoading else { return }
        isLoading = true

        var params = ["lastId": lastId]
        filterParams?.forEach { params[$0.key] = $0.value }

        AuthManager(purnomo: "api/sejarah").checkAuth(
            params: params,
            onSuccess: { [weak self] json in
                guard let self = self else { return }
                let aesKey = json["aes_key"] as? String ?? ""
                guard let arr = json["data"] as? [[String: Any]], !arr.isEmpty else {
                    self.isLoading = false
                    return
                }

                for obj in arr {
                    let id = obj["id"] as? String ?? ""
                    self.listHistory.append(HistoryModel(
                        id: id,
                        masuk: self.decryptField(obj, "masuk", aesKey),
                        pulang: self.decryptField(obj, "pulang", aesKey),
                        selesai: self.decryptField(obj, "selesai", aesKey),
                        keterangan: self.decryptField(obj, "keterangan", aesKey),
                        latitude: self.decryptField(obj, "latitude", aesKey),
                        longitude: self.decryptField(obj, "longitude", aesKey),
                        ketam: self.decryptField(obj, "ketam", aesKey),
                        tipeizin: self.decryptField(obj, "tipeizin", aesKey),
                        namaPimpinan: self.decryptField(obj, "namapimpinan", aesKey),
                        jabatan: self.decryptField(obj, "jabatan", aesKey),
                        pangkat: self.decryptField(obj, "pangkat", aesKey),
                        foto: self.decryptField(obj, "foto", aesKey),
                        subdit: self.decryptField(obj, "subdit", aesKey),
                        tanggal: self.decryptField(obj, "tanggal", aesKey)
                    ))
                    self.lastId = id
                }

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.rvHistory.reloadData()
                }
            },
            onLogout: { [weak self] _ in self?.isLoading = false },
            onLoading: { _ in }
        )
    }

    private func decryptField(_ obj: [String: Any], _ field: String, _ key: String) -> String {
        let value = obj[field] as? String ?? ""
        return (value.isEmpty || value == "null") ? "" : CryptoAES.decrypt(value, key)
    }

    private func loadBannerViaAuthCheck() {
        AuthManager(purnomo: "api/auth-check").checkAuth(
            params: [:],
            onSuccess: { [weak self] json in
                guard let self = self, (json["status"] as? String) == "ok" else { return }
                let aesKey = json["aes_key"] as? String ?? ""
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
                DispatchQueue.main.async {
                    self.beritaItems = items
                    self.setupPager()
                    self.startTimer()
                }
            },
            onLogout: { _ in },
            onLoading: { _ in }
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentH = scrollView.contentSize.height
        let offsetY = scrollView.contentOffset.y
        let frameH = scrollView.frame.height
        if !isLoading && contentH > 0 && (offsetY + frameH) >= (contentH - 200) {
            loadHistory(filterParams: currentFilter)
        }
    }
}

extension History: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listHistory.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HistoryCell.reuseId, for: indexPath) as! HistoryCell
        cell.bind(listHistory[indexPath.row])
        return cell
    }
}

extension History: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
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
