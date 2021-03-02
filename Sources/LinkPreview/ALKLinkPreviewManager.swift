import Foundation

class ALKLinkPreviewManager: NSObject, URLSessionDelegate {
    enum TextMinimumLength {
        static let title: Int = 15
        static let decription: Int = 100
    }

    private static let urlCache = NSCache<NSString, AnyObject>()
    private let workBckQueue: DispatchQueue
    private let responseMainQueue: DispatchQueue

    init(workBckQueue: DispatchQueue = DispatchQueue.global(qos: .background),
         responseMainQueue: DispatchQueue = DispatchQueue.main)
    {
        self.workBckQueue = workBckQueue
        self.responseMainQueue = responseMainQueue
    }

    func makePreview(from text: String, identifier: String, _ completion: @escaping (Result<LinkPreviewMeta, LinkPreviewFailure>) -> Void) {
        guard let url = ALKLinkPreviewManager.extractURLAndAddInCache(from: text, identifier: identifier) else {
            responseMainQueue.async {
                completion(.failure(.noURLFound))
            }
            return
        }

        workBckQueue.async {
            guard let url = url.scheme == "http" || url.scheme == "https" ? url : URL(string: "http://\(url)") else {
                self.responseMainQueue.async {
                    completion(.failure(.invalidURL))
                }
                return
            }

            let request = URLRequest(url: url)
            let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
            session.dataTask(with: request) { [weak self] data, response, error in
                guard let weakSelf = self, error == nil else {
                    self?.responseMainQueue.async {
                        completion(.failure(.cannotBeOpened))
                    }
                    return
                }

                var linkPreview: LinkPreviewMeta?

                if let data = data, let urlResponse = response,
                   let encoding = urlResponse.textEncodingName,
                   let source = NSString(data: data, encoding: CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(encoding as CFString)))
                {
                    linkPreview = weakSelf.parseHtmlAndUpdateLinkPreviewMeta(text: source as String, baseUrl: url.absoluteString)

                } else {
                    guard let data = data, response != nil else {
                        return
                    }
                    let htmlString = String(data: data, encoding: .utf8)
                    linkPreview = weakSelf.parseHtmlAndUpdateLinkPreviewMeta(text: htmlString, baseUrl: url.absoluteString)
                }
                guard let linkPreviewData = linkPreview else {
                    weakSelf.responseMainQueue.async {
                        completion(.failure(.parseError))
                    }
                    return
                }
                LinkURLCache.addLink(linkPreviewData, for: linkPreviewData.url.absoluteString)
                weakSelf.responseMainQueue.async {
                    completion(.success(linkPreviewData))
                }

            }.resume()
        }
    }

    // MARK: - Private helpers

    private func cleanUnwantedTags(from html: String) -> String {
        return html.deleteTagByPattern(LinkPreviewRegex.Pattern.InLine.style)
            .deleteTagByPattern(LinkPreviewRegex.Pattern.InLine.script)
            .deleteTagByPattern(LinkPreviewRegex.Pattern.Script.tag)
            .deleteTagByPattern(LinkPreviewRegex.Pattern.Comment.tag)
    }

    private func parseHtmlAndUpdateLinkPreviewMeta(text: String?, baseUrl: String) -> LinkPreviewMeta? {
        guard let text = text, let url = URL(string: baseUrl) else { return nil }
        let cleanHtml = cleanUnwantedTags(from: text)

        var result = LinkPreviewMeta(url: url)
        result.icon = parseIcon(in: text, baseUrl: baseUrl)
        var linkFreeHtml = cleanHtml.deleteTagByPattern(LinkPreviewRegex.Pattern.Link.tag)

        parseMetaTags(in: &linkFreeHtml, result: &result)
        parseTitle(&linkFreeHtml, result: &result)
        parseDescription(linkFreeHtml, result: &result)
        return result
    }

    private func parseMetaTags(in text: inout String, result: inout LinkPreviewMeta) {
        let tags = LinkPreviewRegex.pregMatchAll(text, pattern: LinkPreviewRegex.Pattern.Meta.tag, index: 1)

        let possibleTags: [String] = [
            LinkPreviewMeta.Key.title.rawValue,
            LinkPreviewMeta.Key.description.rawValue,
            LinkPreviewMeta.Key.image.rawValue,
        ]
        for metatag in tags {
            for tag in possibleTags {
                if metatag.range(of: "property=\"og:\(tag)") != nil ||
                    metatag.range(of: "property='og:\(tag)") != nil ||
                    metatag.range(of: "name=\"twitter:\(tag)") != nil ||
                    metatag.range(of: "name='twitter:\(tag)") != nil ||
                    metatag.range(of: "name=\"\(tag)") != nil ||
                    metatag.range(of: "name='\(tag)") != nil ||
                    metatag.range(of: "itemprop=\"\(tag)") != nil ||
                    metatag.range(of: "itemprop='\(tag)") != nil
                {
                    if let key = LinkPreviewMeta.Key(rawValue: tag),
                       result.value(for: key) == nil
                    {
                        if let value = LinkPreviewRegex.pregMatchFirst(metatag, pattern: LinkPreviewRegex.Pattern.Meta.content, index: 2) {
                            let value = value.decodedHtml.extendedTrim
                            if tag == "image" {
                                let value = handleImagePrefixAndSuffix(value, baseUrl: result.url.absoluteString)
                                if LinkPreviewRegex.isMatchFound(value, regex: LinkPreviewRegex.Pattern.Image.type) { result.set(value, for: key) }
                            } else {
                                result.set(value, for: key)
                            }
                        }
                    }
                }
            }
        }
    }

    private func parseIcon(in text: String, baseUrl: String) -> String? {
        let links = LinkPreviewRegex.pregMatchAll(text, pattern: LinkPreviewRegex.Pattern.Link.tag, index: 1)
        // swiftlint:disable:next opening_brace
        let filters = [{ (link: String) -> Bool
            in link.range(of: "apple-touch") != nil
        }, { (link: String) -> Bool
            in link.range(of: "shortcut") != nil
        }, { (link: String) -> Bool
            in link.range(of: "icon") != nil
        }]
        for filter in filters {
            guard let link = links.filter(filter).first else { continue }
            if let matches = LinkPreviewRegex.pregMatchFirst(link, pattern: LinkPreviewRegex.Pattern.Image.href, index: 1) {
                return handleImagePrefixAndSuffix(matches, baseUrl: baseUrl)
            }
        }
        return nil
    }

    private func parseTitle(_ htmlCode: inout String, result: inout LinkPreviewMeta) {
        let title = result.title
        if title == nil || title?.isEmpty ?? true {
            if let value = LinkPreviewRegex.pregMatchFirst(htmlCode, pattern: LinkPreviewRegex.Pattern.Title.tag, index: 2) {
                if value.isEmpty {
                    let data: String = getTagData(htmlCode, minimum: TextMinimumLength.title)
                    if !data.isEmpty {
                        result.title = data.decodedHtml.extendedTrim
                        htmlCode = htmlCode.replace(data, with: "")
                    }
                } else {
                    result.title = value.decodedHtml.extendedTrim
                }
            }
        }
    }

    private func parseDescription(_ htmlCode: String, result: inout LinkPreviewMeta) {
        let description = result.description

        if description == nil || description?.isEmpty ?? true {
            let value: String = getTagData(htmlCode, minimum: TextMinimumLength.decription)
            if !value.isEmpty {
                result.description = value.decodedHtml.extendedTrim
            }
        }
    }

    private func handleImagePrefixAndSuffix(_ image: String, baseUrl: String) -> String {
        var url = image
        if let index = image.firstIndex(of: "?") {
            url = String(image[..<index])
        }
        guard !url.starts(with: "http") else { return url }
        if url.starts(with: "//") {
            return "http:" + url
        } else if url.starts(with: "/") {
            if baseUrl.starts(with: "http://") || baseUrl.starts(with: "https://") {
                return baseUrl + url
            }
            return "http://" + baseUrl + url
        } else {
            return url
        }
    }

    /// Returns the very first url encountered in the text.
    /// - Parameter text: text from which url is to be search
    /// - Parameter identifier: Message identifier for cache
    class func extractURLAndAddInCache(from text: String?, identifier: String) -> URL? {
        guard let message = text else {
            return nil
        }

        guard let urlString = urlCache.object(forKey: identifier as NSString), let url = URL(string: urlString as! String) else {
            do {
                let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                let range = NSRange(location: 0, length: message.utf16.count)
                let matches = detector.matches(in: message, options: [], range: range)
                let url = matches.compactMap { $0.url }.first

                guard let urlString = url?.absoluteString, !urlString.starts(with: "mailto:") else {
                    return nil
                }
                urlCache.setObject(urlString as NSString, forKey: identifier as NSString)
                return url
            } catch {
                return nil
            }
        }
        return url
    }

    private func getTagData(_ content: String, minimum: Int) -> String {
        let paragraphTagData = getTagContent("p", content: content, minimum: minimum)

        if !paragraphTagData.isEmpty {
            return paragraphTagData
        } else {
            let devTagData = getTagContent("div", content: content, minimum: minimum)
            if !devTagData.isEmpty {
                return devTagData
            } else {
                let spanTagData = getTagContent("span", content: content, minimum: minimum)
                if !spanTagData.isEmpty {
                    return spanTagData
                }
            }
        }
        return ""
    }

    private func getTagContent(_ tag: String, content: String, minimum: Int) -> String {
        let pattern = LinkPreviewRegex.tagPattern(tag)

        let index = 2
        let rawMatches = LinkPreviewRegex.pregMatchAll(content, pattern: pattern, index: index)

        let matches = rawMatches.filter { $0.extendedTrim.deleteTagByPattern(LinkPreviewRegex.Pattern.Raw.tag).count >= minimum }
        var result = !matches.isEmpty ? matches[0] : ""

        if result.isEmpty {
            if let match = LinkPreviewRegex.pregMatchFirst(content, pattern: pattern, index: 2) {
                result = match.extendedTrim.deleteTagByPattern(LinkPreviewRegex.Pattern.Raw.tag)
            }
        }
        return result
    }
}

extension String {
    func deleteTagByPattern(_ pattern: String) -> String {
        return replacingOccurrences(of: pattern, with: "", options: .regularExpression, range: nil)
    }

    var extendedTrim: String {
        let components = self.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ").trim()
    }

    var decodedHtml: String {
        let encodedData = data(using: String.Encoding.utf8)!
        let attributedOptions: [NSAttributedString.DocumentReadingOptionKey: Any] =
            [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue),
            ]
        do {
            let attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
            return attributedString.string

        } catch _ {
            return self
        }
    }

    func replace(_ search: String, with: String) -> String {
        let replaced: String = replacingOccurrences(of: search, with: with)
        return replaced.isEmpty ? self : replaced
    }
}
