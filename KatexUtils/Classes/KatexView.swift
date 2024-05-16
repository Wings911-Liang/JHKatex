//
//  KatexView.swift
//  UltraMarkDown
//
//  Created by nikesu on 2021/2/19.
//

import UIKit
import WebKit
import Combine

public final class KatexView : UIView {

    public enum KatexViewStatus {
        case loading
        case finished
        case idle
        case error(message: String)
    }
    
//    @Published
    public var status: KatexViewStatus = .idle
    
    public var latex: String = "" {
        didSet {
            reload()
        }
    }
    
    public var maxWidth: CGFloat = 0.0
    
    public var customCss = ".katex { color: #212121; font-size: 16px; }"

    public var takeSnapshotCompletion: ((UIImage?) -> Void)? {
        didSet {
            katexWebView.takeSnapshotCompletion = { [weak self] image in
                guard let self else { return }
                takeSnapshotCompletion?(image)
            }
        }
    }
    
    public var config: KatexViewConfig!

    private lazy var katexWebView: KatexWebView = {
        let katexWebView = KatexWebView()
        return katexWebView
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        self.addSubview(katexWebView)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public convenience init(config: KatexViewConfig, latex: String) {
        self.init(frame: .zero)
        self.config = config
        self.latex = latex
        reload()
    }
    
    public func reload() {
        katexWebView.frame = CGRect(origin: .zero, size: CGSize(width: maxWidth, height: 1))
        katexWebView.loadLatex(latex, options: config.options, customCss: customCss) { [weak self] in
            self?.takeSnapshotCompletion?(nil)
        }
    }
}

public class KatexWebView: WKWebView, WKUIDelegate, WKNavigationDelegate {

    enum KatexWebViewStatus {
        case loading
        case finished
        case idle
        case error(message: String)
    }
    
    var image: UIImage?
    
    var takeSnapshotCompletion: ((UIImage?) -> Void)?

//        @Published
    var status: KatexWebViewStatus = .idle

    private static var templateHtmlPath: String = {
        guard let path = Bundle.katexBundle?.path(forResource: "katex/index", ofType: "html") else {
            fatalError("[KatexUtils] Can not find template HTML file.")
        }
        return path
    }()

    private static var templateHtmlString: String = {
        do {
            let templateHtmlString = try String(contentsOfFile: templateHtmlPath, encoding: .utf8)
            return templateHtmlString
        } catch {
            fatalError("[KatexUtils] Open template HTML file failed.")
        }
    }()
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let script = """
            [document.body.scrollWidth > document.body.clientWidth ? document.body.scrollWidth : document.getElementById('tex').getBoundingClientRect().width,
             document.getElementsByTagName('html')[0].getBoundingClientRect().height]
        """
        webView.evaluateJavaScript(script) { [weak self] (result, error) in
            guard let self else { return }
            if let result = result as? Array<CGFloat> {
                handleWebView(aWebView: webView, frame: CGRect(x: 0, y: 0, width: result[0], height: result[1] + 1))
                self.status = .finished
                let configuration = WKSnapshotConfiguration()
                webView.takeSnapshot(with: configuration) { [weak self] image, error in
                    guard let self else { return }
                    takeSnapshotCompletion?(image)
                }
            }
        }
    }
    
    func handleWebView(aWebView: WKWebView, frame: CGRect) {
        aWebView.frame = frame;       // Set the scrollView contentHeight back to the frame itself.
        guard var selfFrame = self.superview?.frame else {
            return
        }
        selfFrame.size = aWebView.frame.size;
        self.superview?.frame = selfFrame;
    }

    init() {
        super.init(frame: .zero, configuration: WKWebViewConfiguration())

        scrollView.isScrollEnabled = false
        scrollView.isUserInteractionEnabled = false
        scrollView.bounces = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false

        navigationDelegate = self

        isOpaque = false
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadLatex(_ latex: String, options: [Katex.Key : Any]? = nil, customCss: String? = nil, errorBlock: () -> Void) {
        do {
            let htmlString = try getHtmlString(latex: latex, options: options, customCss: customCss)
            status = .loading
            loadHTMLString(htmlString, baseURL: URL(fileURLWithPath: Self.templateHtmlPath))
        } catch Katex.KatexError.parseError(let message, _) {
            status = .error(message: message)
            errorBlock()
        } catch {
            status = .error(message: "Can not load LaTeX formula.")
            errorBlock()
        }
    }

    func getHtmlString(latex: String, options: [Katex.Key : Any]? = nil, customCss: String? = nil) throws -> String {
        var htmlString = Self.templateHtmlString
        let insertHtml = try KatexRenderer.renderToString(latex: latex, options: options)
        htmlString = htmlString.replacingOccurrences(of: "CUSTOM_CSS", with: customCss ?? "")
        htmlString = htmlString.replacingOccurrences(of: "$LATEX$", with: insertHtml)
        return htmlString
    }
}
