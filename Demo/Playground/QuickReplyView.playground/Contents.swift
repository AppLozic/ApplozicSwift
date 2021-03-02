/// Usage of `ALKQuickReplyView`
import ApplozicSwift

func fromJSON(string: String) throws -> [[String: Any]] {
    guard let data = string.data(using: .utf8),
          let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyObject]
    else {
        throw NSError(domain: NSCocoaErrorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON"])
    }
    return jsonObject.map { $0 as! [String: Any] }
}

let payload = "[{\"title\":\"Where is my cashback? \",\"message\":\"Where is my cashback? \"},{\"title\":\"Show me some offers \",\"message\":\"Show me some offers\"},{\"title\":\"Cancel my order \",\"message\":\"Cancel my order \"},{\"title\":\"I want to delete my account \",\"message\":\"I want to delete my account\"},{\"title\":\"Send money \",\"message\":\"Send money \"},{\"title\":\"Accept money \",\"message\":\"Accept money \"}]"

let dict = try! fromJSON(string: payload)

// Using width 300
let view = ALKQuickReplyView(frame: CGRect(x: 0, y: 0, width: 300, height: ALKQuickReplyView.rowHeight(quickReplyArray: dict, maxWidth: 300)))
view.maxWidth = 300
view.update(quickReplyArray: dict)

// Using width 800
let view2 = ALKQuickReplyView(frame: CGRect(x: 0, y: 0, width: 800, height: ALKQuickReplyView.rowHeight(quickReplyArray: dict, maxWidth: 800)))
view2.maxWidth = 800
view2.update(quickReplyArray: dict)

/// Using different payload

let payload2 = "[{\"title\":\"Come up to meet you tell you I'm sorry You don't know how lovely you are \",\"message\":\"Where is my cashback? \"},{\"title\":\"Show me some offers \",\"message\":\"Show me some offers\"},{\"title\":\"Cancel my order \",\"message\":\"Cancel my order \"}, {\"title\":\"Tell me you love me, come back and hold me...\",\"message\":\"Cancel my order \"}]"
let dict2 = try! fromJSON(string: payload2)
let view3 = ALKQuickReplyView(frame: CGRect(x: 0, y: 0, width: 300, height: ALKQuickReplyView.rowHeight(quickReplyArray: dict2, maxWidth: 300)))
view3.maxWidth = 300
view3.update(quickReplyArray: dict2)
