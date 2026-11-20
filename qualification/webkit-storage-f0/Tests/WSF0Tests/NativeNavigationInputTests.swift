import Foundation
import Testing
import BrowserDomain

@Suite("Native address entry") struct NativeNavigationInputTests {
    @Test func searchChoiceAndLiteralPlus() {
        for provider in NativeNavigationInput.SearchProvider.allCases {
            #expect(NativeNavigationInput.destination("example.org/docs", provider: provider)?.host == "example.org")
        }
        #expect(NativeNavigationInput.destination("find this", provider: .addressesOnly) == nil)
        #expect(NativeNavigationInput.destination("C++ & Swift", provider: .google)?.absoluteString ==
            "https://www.google.com/search?q=C%2B%2B%20%26%20Swift")
        #expect(NativeNavigationInput.destination("C++")?.absoluteString == "https://duckduckgo.com/?q=C%2B%2B")
    }

    @Test func hostAndSearch() {
        #expect(NativeNavigationInput.destination("example.org/path")?.absoluteString == "https://example.org/path")
        #expect(NativeNavigationInput.destination("hello world")?.host == "duckduckgo.com")
        #expect(NativeNavigationInput.destination("localhost:8080/a")?.absoluteString == "https://localhost:8080/a")
    }
    @Test func explicitSchemesAndCredentials() {
        for value in ["file:///etc/passwd", "javascript:alert(1)", "data:text/html,x", "https://user:pass@example.com", "http://example.com", "https://example.com/\\bad", "https://example.com/\u{0001}", ""] {
            #expect(NativeNavigationInput.destination(value) == nil, "Unexpected admission")
        }
        #expect(NativeNavigationInput.destination("http://127.0.0.1:8080/path") != nil)
    }
    @Test func userInfoCannotFallBackToSearch() {
        for provider in NativeNavigationInput.SearchProvider.allCases {
            for input in ["fixture@sample.invalid/private", "//fixture:token@sample.invalid/private",
                          "https://fixture@sample.invalid/private", "fixture@sample.invalid/a b"] {
                #expect(NativeNavigationInput.destination(input, provider: provider) == nil)
            }
            #expect(NativeNavigationInput.destination("sample.invalid/people/@fixture", provider: provider)?.host == "sample.invalid")
        }
        #expect(NativeNavigationInput.destination("@fixture")?.host == "duckduckgo.com")
        #expect(NativeNavigationInput.destination("look up @fixture")?.host == "duckduckgo.com")
    }

    @Test func queryAndFragmentPreserved() {
        let url = NativeNavigationInput.destination("https://example.com/a?q=one%20two#section")
        #expect(url?.query == "q=one%20two")
        #expect(url?.fragment == "section")
        let input = String(repeating: "a", count: 2049)
        #expect(NativeNavigationInput.destination(input) == nil)
    }
}
