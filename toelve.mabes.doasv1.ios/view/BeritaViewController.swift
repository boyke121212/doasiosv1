//
//  Berita.swift
//  Doas
//
//  Created by Admin on 06/03/26.
//

import UIKit

// MARK: - BeritaListItem
struct BeritaListItem {
    let id:      String
    let judul:   String
    let isi:     String
    let tanggal: String
    let foto:    String
    let pdf:     String
}

// MARK: - SelfSizingTableView
class SelfSizingTableView: UITableView {
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
    override func reloadData() {
        super.reloadData()
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }
    override func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        super.insertRows(at: indexPaths, with: animation)
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }
}

// MARK: - BeritaListCell
class BeritaListCell: UITableViewCell {

    static let reuseId = "BeritaListCell"

    let cardView     = UIView()
    let ivFoto       = UIImageView()
    let contentStack = UIStackView()
    let tvJudul      = UILabel()
    let tvIsi        = UILabel()
    let btDownload   = UIButton(type: .system)
    let downloadSpinner: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            return UIActivityIndicatorView(style: .medium)
        } else {
            return UIActivityIndicatorView(style: .white)
        }
    }()

    var onTapCard:     (() -> Void)?
    var onTapDownload: (() -> Void)?
    
    private var isDownloading = false


    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle  = .none
        backgroundColor = .clear
        setupCell()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupCell() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor     = .white
        cardView.layer.cornerRadius  = 12
        cardView.layer.borderWidth   = 1
        cardView.layer.borderColor   = UIColor(hex: "#E5E7EB").cgColor
        cardView.layer.shadowColor   = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowRadius  = 4
        cardView.layer.shadowOffset  = CGSize(width: 0, height: 2)
        cardView.layer.masksToBounds = false

        contentView.addSubview(cardView)
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])

        let pembungkus = UIStackView()
        pembungkus.axis = .horizontal; pembungkus.spacing = 12; pembungkus.alignment = .top
        pembungkus.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(pembungkus)
        NSLayoutConstraint.activate([
            pembungkus.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            pembungkus.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            pembungkus.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            pembungkus.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12)
        ])

        ivFoto.translatesAutoresizingMaskIntoConstraints = false
        ivFoto.contentMode = .scaleAspectFill; ivFoto.clipsToBounds = true
        ivFoto.layer.cornerRadius = 10
        ivFoto.image = UIImage(named: "doas2"); ivFoto.backgroundColor = .systemGray5
        NSLayoutConstraint.activate([
            ivFoto.widthAnchor.constraint(equalToConstant: 90),
            ivFoto.heightAnchor.constraint(equalToConstant: 90)
        ])
        pembungkus.addArrangedSubview(ivFoto)

        contentStack.axis = .vertical; contentStack.spacing = 4; contentStack.alignment = .leading
        pembungkus.addArrangedSubview(contentStack)

        tvJudul.font = .boldSystemFont(ofSize: 14)
        tvJudul.textColor = UIColor(hex: "#111827"); tvJudul.numberOfLines = 0
        contentStack.addArrangedSubview(tvJudul)

        tvIsi.font = .systemFont(ofSize: 12)
        tvIsi.textColor = UIColor(hex: "#4B5563"); tvIsi.numberOfLines = 3
        tvIsi.lineBreakMode = .byTruncatingTail
        contentStack.addArrangedSubview(tvIsi)
        contentStack.setCustomSpacing(4, after: tvJudul)

        btDownload.setTitle("Download PDF", for: .normal)
        btDownload.titleLabel?.font = .boldSystemFont(ofSize: 12)
        btDownload.setTitleColor(.white, for: .normal)
        btDownload.backgroundColor = UIColor(hex: "#2563EB")
        btDownload.layer.cornerRadius = 8
        btDownload.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        contentStack.addArrangedSubview(btDownload)
        contentStack.setCustomSpacing(8, after: tvIsi)
        btDownload.addTarget(self, action: #selector(tapDownload), for: .touchUpInside)
        
        // Setup spinner untuk loading indicator
        downloadSpinner.translatesAutoresizingMaskIntoConstraints = false
        downloadSpinner.color = .white
        downloadSpinner.hidesWhenStopped = true
        btDownload.addSubview(downloadSpinner)
        NSLayoutConstraint.activate([
            downloadSpinner.centerYAnchor.constraint(equalTo: btDownload.centerYAnchor),
            downloadSpinner.trailingAnchor.constraint(equalTo: btDownload.trailingAnchor, constant: -12)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapCard))
        cardView.addGestureRecognizer(tap)
        cardView.isUserInteractionEnabled = true
    }

    @objc private func tapCard()     { onTapCard?() }
    @objc private func tapDownload() { 
        guard !isDownloading else { return } // Prevent multiple taps
        onTapDownload?() 
    }
    
    func setDownloadingState(_ downloading: Bool) {
        isDownloading = downloading
        btDownload.isEnabled = !downloading
        btDownload.alpha = downloading ? 0.6 : 1.0
        
        if downloading {
            downloadSpinner.startAnimating()
            btDownload.setTitle("Downloading...", for: .normal)
        } else {
            downloadSpinner.stopAnimating()
            btDownload.setTitle("Download PDF", for: .normal)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        ivFoto.cancelImageLoad()
        ivFoto.image = UIImage(named: "doas2")
        onTapCard = nil; onTapDownload = nil
        setDownloadingState(false) // Reset loading state
    }

    func bind(_ item: BeritaListItem) {
        tvJudul.text        = item.judul
        tvIsi.text          = RenderHtml.htmlPreviewClean(item.isi)
        btDownload.isHidden = item.pdf.isEmpty
        let token  = SecurePrefs.shared.getAccessToken() ?? ""
        let urlStr = AppConfig2.BASE_URL + "api/media/berita/" + item.foto
        if let url = URL(string: urlStr) {
            ivFoto.loadImage(url: url, token: token, placeholder: UIImage(named: "doas2"))
        }
    }
}

// MARK: - Berita ViewController
class BeritaViewController: Boyke, UIScrollViewDelegate {

    // ✅ RESTORED: Layout yang sudah berjalan sempurna
    let scrollView   = UIScrollView()
    let contentView  = UIView()

    // ✅ NEW: Layout baru (persis seperti Home.swift)
    private let headerView = UIView()
    let tvJudul = UILabel()
    let tvIsi = UILabel()

    // Tab Menu Buttons
    private let btAbsen = UIButton(type: .system)
    private let btStatus = UIButton(type: .system)
    private let btBerita = UIButton(type: .system)
    private let btLog = UIButton(type: .system)
    private let btDoas = UIButton(type: .system)

    // UIPageViewController untuk berita slider
    let pageController: UIPageViewController = {
        let pc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pc.view.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()

    private var listBerita: [BeritaListItem] = []
    private var lastId     = ""
    private var isLoading  = false
    private var isLastPage = false
    
    // Banner slider items (untuk header pager)
    var beritaItems: [BeritaItem] = []
    var currentBannerIndex = 0

    let rvHistory      = SelfSizingTableView()
    let refreshControl = UIRefreshControl()

    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 1.0)

        setupLayout()
        setupActions()
    }

    // MARK: - Actions
    private func setupActions() {
        btAbsen.addTarget(self, action: #selector(onTapAbsen), for: .touchUpInside)
        btStatus.addTarget(self, action: #selector(onTapStatus), for: .touchUpInside)
        btLog.addTarget(self, action: #selector(ontaplog), for: .touchUpInside)
        btDoas.addTarget(self, action: #selector(onTapDoas), for: .touchUpInside)
    }

    @objc private func onTapAbsen() { openPage(Home()) }
    @objc private func onTapStatus() { openPage(Statuses()) }
    @objc private func ontaplog() { openPage(History()) }
    @objc private func onTapDoas() { openPage(Doas()) }

    // ✅ RESTORED: Pagination logic (tanpa collapsing header)
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentH = scrollView.contentSize.height
        let offsetY  = scrollView.contentOffset.y
        let frameH   = scrollView.frame.height
        if !isLoading && !isLastPage && (offsetY + frameH) >= contentH - 200 {
            loadBerita()
        }
    }

    // MARK: - Layout
    private func setupLayout() {
        // 1. Header dengan UIPageViewController (fixed 300pt)
        headerView.backgroundColor = .darkGray
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)

        addChild(pageController)
        headerView.addSubview(pageController.view)
        pageController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            pageController.view.topAnchor.constraint(equalTo: headerView.topAnchor),
            pageController.view.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            pageController.view.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            pageController.view.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])

        tvJudul.text = "D.O.A.S"
        tvJudul.textColor = .white
        tvJudul.font = .boldSystemFont(ofSize: 18)

        tvIsi.text = "DITTIPIDTER BARESKRIM"
        tvIsi.textColor = .lightGray
        tvIsi.font = .systemFont(ofSize: 13)
        tvIsi.numberOfLines = 2

        let heroStack = UIStackView(arrangedSubviews: [tvJudul, tvIsi])
        heroStack.axis = .vertical
        heroStack.spacing = 4
        heroStack.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(heroStack)

        // 2. Tab Menu
        let tabMenu = UIStackView(arrangedSubviews: [btAbsen, btStatus, btBerita, btLog, btDoas])
        tabMenu.axis = .horizontal
        tabMenu.distribution = .fillEqually
        tabMenu.backgroundColor = .white
        tabMenu.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabMenu)

        configureTabButton(btAbsen, title: "Absen")
        configureTabButton(btStatus, title: "Status")
        configureTabButton(btBerita, title: "Berita", isActive: true)
        configureTabButton(btLog, title: "Log")
        configureTabButton(btDoas, title: "DOAS")

        // 3. ScrollView + ContentView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.delegate = self

        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        let cg = scrollView.contentLayoutGuide
        let fg = scrollView.frameLayoutGuide

        setupHistoryList()

        // Constraints
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 300),

            heroStack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
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
            contentView.widthAnchor.constraint(equalTo: fg.widthAnchor)
        ])
    }

    private func setupHistoryList() {
        rvHistory.translatesAutoresizingMaskIntoConstraints = false
        rvHistory.isScrollEnabled    = false
        rvHistory.separatorStyle     = .none
        rvHistory.backgroundColor    = .clear
        rvHistory.rowHeight          = UITableView.automaticDimension
        rvHistory.estimatedRowHeight = 120
        rvHistory.register(BeritaListCell.self, forCellReuseIdentifier: BeritaListCell.reuseId)
        rvHistory.dataSource = self
        rvHistory.delegate   = self

        let footer = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 80))
        rvHistory.tableFooterView = footer

        contentView.addSubview(rvHistory)

        NSLayoutConstraint.activate([
            rvHistory.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            rvHistory.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rvHistory.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rvHistory.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - viewDidAppear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ambilBanner()
        if listBerita.isEmpty { loadBerita() }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopBeritaAutoSlide()
    }

    // MARK: - Refresh
    @objc private func onRefresh() {
        lastId = ""; isLastPage = false; isLoading = false
        listBerita.removeAll()
        rvHistory.reloadData()
        ambilBanner()
        loadBerita()
        refreshControl.endRefreshing()
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func configureTabButton(_ button: UIButton, title: String, isActive: Bool = false) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: isActive ? .bold : .regular)
        button.setTitleColor(isActive ? .systemBlue : .darkGray, for: .normal)
        if isActive { button.backgroundColor = UIColor(white: 0.9, alpha: 1.0) }
    }

    // MARK: - ambilBanner
    func ambilBanner() {
        AuthManager(purnomo: "api/ambil_absen").checkAuth(
            params: [:],
            onSuccess: { [weak self] json in
                guard let self else { return }
                guard (json["status"] as? String) == "ok" else { return }
                let aesKey = json["aes_key"] as? String ?? ""
                var items: [BeritaItem] = []
                if let arr = json["berita"] as? [[String: Any]] {
                    for obj in arr {
                        items.append(BeritaItem(
                            id:      obj["id"]      as? String ?? "",
                            judul:   CryptoAES.decrypt(obj["judul"]   as? String ?? "", aesKey),
                            isi:     CryptoAES.decrypt(obj["isi"]     as? String ?? "", aesKey),
                            tanggal: obj["tanggal"] as? String ?? "",
                            foto:    CryptoAES.decrypt(obj["foto"]    as? String ?? "", aesKey),
                            pdf:     CryptoAES.decrypt(obj["pdf"]     as? String ?? "", aesKey)
                        ))
                    }
                }
                DispatchQueue.main.async {
                    guard !items.isEmpty else { return }

                    // Store items untuk paging
                    self.beritaItems = items
                    self.currentBannerIndex = 0

                    let firstVC = BannerPageVC(item: items[0])
                    
                    // Setup data source dan delegate untuk swipe support
                    self.pageController.dataSource = self.pageHelper
                    self.pageController.delegate = self.pageHelper
                    
                    self.pageController.setViewControllers([firstVC], direction: .forward, animated: false)

                    self.tvJudul.text = items[0].judul

                    if let data = items[0].isi.data(using: .utf8) {
                        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                            .documentType: NSAttributedString.DocumentType.html,
                            .characterEncoding: String.Encoding.utf8.rawValue
                        ]

                        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
                            let mutableAttr = NSMutableAttributedString(attributedString: attributed)
                            mutableAttr.addAttribute(.foregroundColor,
                                                   value: UIColor.lightGray,
                                                   range: NSRange(location: 0, length: mutableAttr.length))
                            self.tvIsi.attributedText = mutableAttr
                        } else {
                            self.tvIsi.text = items[0].isi.hendry_htmlToPlain()
                        }
                    } else {
                        self.tvIsi.text = items[0].isi.hendry_htmlToPlain()
                    }
                    
                    // Start auto-slide
                    self.startBeritaAutoSlide()
                }
            },
            onLogout: { _ in }, onLoading: { _ in }
        )
    }

    // MARK: - loadBerita
    private func loadBerita() {
        guard !isLoading, !isLastPage else { return }
        isLoading = true

        AuthManager(purnomo: "api/berita").checkAuth(
            params: ["lastId": lastId],
            onSuccess: { [weak self] json in
                guard let self else { return }
                let aesKey = json["aes_key"] as? String ?? ""
                let jumlah = json["jumlah"]  as? Int    ?? 0

                guard jumlah > 0, let arr = json["data"] as? [[String: Any]] else {
                    DispatchQueue.main.async {
                        self.isLastPage = true
                        self.isLoading  = false
                    }
                    return
                }

                let startPos = self.listBerita.count
                for obj in arr {
                    self.listBerita.append(BeritaListItem(
                        id:      obj["id"]      as? String ?? "",
                        judul:   CryptoAES.decrypt(obj["judul"]   as? String ?? "", aesKey),
                        isi:     CryptoAES.decrypt(obj["isi"]     as? String ?? "", aesKey),
                        tanggal: obj["tanggal"] as? String ?? "",
                        foto:    CryptoAES.decrypt(obj["foto"]    as? String ?? "", aesKey),
                        pdf:     CryptoAES.decrypt(obj["pdf"]     as? String ?? "", aesKey)
                    ))
                }
                self.lastId = json["last_id"] as? String ?? self.lastId

                DispatchQueue.main.async {
                    let idxs = (startPos ..< self.listBerita.count).map { IndexPath(row: $0, section: 0) }
                    self.rvHistory.insertRows(at: idxs, with: .none)
                    self.isLoading = false
                }
            },
            onLogout: { [weak self] message in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.isLoading = false
                    self.refreshControl.endRefreshing()
                    if message == "__TIMEOUT__" || message == "__NO_INTERNET__" {
                        self.showAlert("Connection Time Out Error")
                    } else if !message.contains("Verification failed") && !message.contains("Checking Device") {
                        let vc = Home(); vc.modalPresentationStyle = .fullScreen; self.present(vc, animated: false)
                    }
                }
            },
            onLoading: { loading in
                DispatchQueue.main.async {
                    if loading { self.showLoading() } else { self.hideLoading() }
                }
            }
        )
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension BeritaViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        listBerita.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: BeritaListCell.reuseId, for: indexPath
        ) as! BeritaListCell

        let item = listBerita[indexPath.row]
        cell.bind(item)

        cell.onTapCard = { [weak self] in
//            guard let self else { return }
//            let vc = BeritaDetailActivity()
//            vc.beritaId      = item.id
//            vc.beritaJudul   = item.judul
//            vc.beritaIsi     = item.isi
//            vc.beritaTanggal = item.tanggal
//            vc.beritaFoto    = item.foto
//            vc.beritaPdf     = item.pdf
//            vc.modalPresentationStyle = .fullScreen
//            self.present(vc, animated: true)
        }

        cell.onTapDownload = { [weak self] in
            guard let self else { return }
            guard NetworkHelper.isInternetAvailable() else {
                self.showAlert("Tidak ada koneksi internet")
                return
            }
            
            // Set loading state
            cell.setDownloadingState(true)
            
            let token  = SecurePrefs.shared.getAccessToken() ?? ""
            let urlPdf = AppConfig2.BASE_URL + "api/media/pdf/" + item.pdf
            
            // Download PDF with completion handler
            PdfDownloader.download(
                url: urlPdf, 
                filename: item.pdf, 
                token: token, 
                from: self
            ) { success in
                // Reset loading state when download completes
                DispatchQueue.main.async {
                    cell.setDownloadingState(false)
                }
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UIColor hex helper
extension UIColor {
    convenience init(hex: String) {
        var h = hex.trimmingCharacters(in: .alphanumerics.inverted)
        if h.count == 6 { h = "FF" + h }
        var val: UInt64 = 0
        Scanner(string: h).scanHexInt64(&val)
        self.init(
            red:   CGFloat((val & 0xFF0000) >> 16) / 255,
            green: CGFloat((val & 0x00FF00) >>  8) / 255,
            blue:  CGFloat( val & 0x0000FF        ) / 255,
            alpha: CGFloat((val & 0xFF000000) >> 24) / 255
        )
    }
}

// MARK: - BERITA PAGER (Auto-slide & Swipe)
extension BeritaViewController {
    
    func onBeritaChanged(_ berita: BeritaItem) {
        print("📰 [BeritaVC] onBeritaChanged: \(berita.judul)")
        
        tvJudul.text = berita.judul
        
        if let data = berita.isi.data(using: .utf8) {
            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]
            
            if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
                let mutableAttr = NSMutableAttributedString(attributedString: attributed)
                mutableAttr.addAttribute(.foregroundColor,
                                        value: UIColor.lightGray,
                                        range: NSRange(location: 0, length: mutableAttr.length))
                tvIsi.attributedText = mutableAttr
            } else {
                tvIsi.text = berita.isi.hendry_htmlToPlain()
            }
        } else {
            tvIsi.text = berita.isi.hendry_htmlToPlain()
        }
    }
    
    func startBeritaAutoSlide(interval: TimeInterval = 4.0) {
        stopBeritaAutoSlide()
        print("🔄 [BeritaVC] Starting auto-slide with interval: \(interval)s")
        
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard self.beritaItems.count > 1 else { return }
            
            let nextIndex = (self.currentBannerIndex + 1) % self.beritaItems.count
            let vc = BannerPageVC(item: self.beritaItems[nextIndex])
            
            self.pageController.setViewControllers([vc], direction: .forward, animated: true) { finished in
                if finished {
                    self.currentBannerIndex = nextIndex
                    self.onBeritaChanged(self.beritaItems[self.currentBannerIndex])
                }
            }
        }
        beritaAutoSlideTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    
    func stopBeritaAutoSlide() {
        beritaAutoSlideTimer?.invalidate()
        beritaAutoSlideTimer = nil
    }
}

// MARK: - PAGE VIEW CONTROLLER DATA SOURCE
private final class BeritaPageDataSourceDelegate: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    weak var owner: BeritaViewController?
    
    init(owner: BeritaViewController) {
        self.owner = owner
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let owner = owner, let vc = viewController as? BannerPageVC else { return nil }
        guard let currentIdx = owner.beritaItems.firstIndex(where: { $0.id == vc.item.id }) else { return nil }
        let prev = currentIdx - 1
        let targetIdx = (prev >= 0) ? prev : (owner.beritaItems.isEmpty ? nil : owner.beritaItems.count - 1)
        guard let idx = targetIdx, owner.beritaItems.indices.contains(idx) else { return nil }
        return BannerPageVC(item: owner.beritaItems[idx])
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let owner = owner, let vc = viewController as? BannerPageVC else { return nil }
        guard let currentIdx = owner.beritaItems.firstIndex(where: { $0.id == vc.item.id }) else { return nil }
        let next = currentIdx + 1
        let targetIdx = (next < owner.beritaItems.count) ? next : (owner.beritaItems.isEmpty ? nil : 0)
        guard let idx = targetIdx, owner.beritaItems.indices.contains(idx) else { return nil }
        return BannerPageVC(item: owner.beritaItems[idx])
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed, let owner = owner, let currentVC = pageViewController.viewControllers?.first as? BannerPageVC else { return }
        if let idx = owner.beritaItems.firstIndex(where: { $0.id == currentVC.item.id }) {
            owner.currentBannerIndex = idx
            owner.onBeritaChanged(owner.beritaItems[idx])
        }
    }
}

extension BeritaViewController {
    private static var _pageHelperKey: UInt8 = 0
    
    fileprivate var pageHelper: BeritaPageDataSourceDelegate {
        if let existing = objc_getAssociatedObject(self, &BeritaViewController._pageHelperKey) as? BeritaPageDataSourceDelegate {
            return existing
        }
        let helper = BeritaPageDataSourceDelegate(owner: self)
        objc_setAssociatedObject(self, &BeritaViewController._pageHelperKey, helper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return helper
    }
}

extension BeritaViewController {
    private static var _beritaTimerKey: UInt8 = 0
    
    fileprivate var beritaAutoSlideTimer: Timer? {
        get { objc_getAssociatedObject(self, &BeritaViewController._beritaTimerKey) as? Timer }
        set { objc_setAssociatedObject(self, &BeritaViewController._beritaTimerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

