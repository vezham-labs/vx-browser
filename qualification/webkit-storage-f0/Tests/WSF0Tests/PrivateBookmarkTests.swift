import Foundation
import Testing
import BrowserDomain

struct PrivateBookmarkTests {
    @Test func strictURLAndIdentity() throws {
        var library = PrivateBookmarks()
        var item = PrivateBookmarks.Link(title: "Alpha", url: "https://example.test/a?q=x#y")
        let result1 = library.save(item)
        #expect(result1)
        item.title = "Renamed"
        let result2 = library.save(item)
        #expect(result2)
        #expect(library.links == [item])
        for invalid in ["a search query", "file:///tmp/item", "http://example.test", "https://a:b@example.test"] {
            item.url = invalid
            let result3 = !library.save(item)
            #expect(result3)
        }
        #expect(library.links.first?.url == "https://example.test/a?q=x#y")
        library.remove(item.id)
        #expect(library.links.isEmpty)
    }

    @Test func movePreservesPayloadAndRejectsMissingTarget() throws {
        var library = PrivateBookmarks()
        let a = PrivateBookmarks.Link(title: "A", url: "http://127.0.0.1:2345/a")
        let b = PrivateBookmarks.Link(title: "B", url: "https://example.test/b", folder: "Reading")
        let result4 = library.save(a)
        #expect(result4)
        let result5 = library.save(b)
        #expect(result5)
        let result6 = !library.move(a.id, beside: a.id, after: false)
        #expect(result6)
        let result7 = !library.move(a.id, beside: UUID(), after: true)
        #expect(result7)
        #expect(library.links == [a, b])
        let result8 = library.move(a.id, beside: b.id, after: true)
        #expect(result8)
        #expect(library.links.map(\.id) == [b.id, a.id])
        let moved = try #require(library.links.last)
        #expect(moved.url == a.url && moved.title == a.title && moved.folder == "Reading")
        let result9 = library.move(a.id, toFolder: "")
        #expect(result9)
        #expect(library.links.last?.folder == "")
    }

    @Test func favoriteMembershipAndSessionCleanup() throws {
        var library = PrivateBookmarks()
        let favorite = PrivateBookmarks.Link(title: "Favorite", url: "https://example.test/favorite", favorite: true)
        let bookmark = PrivateBookmarks.Link(title: "Bookmark", url: "https://example.test/bookmark", folder: "Reading")
        let savedFavorite = library.save(favorite)
        let savedBookmark = library.save(bookmark)
        #expect(savedFavorite && savedBookmark)
        let moved = library.move(bookmark.id, beside: favorite.id, after: false)
        #expect(moved)
        let first = try #require(library.links.first)
        #expect(first.id == bookmark.id && first.title == bookmark.title && first.url == bookmark.url)
        #expect(first.favorite && first.folder.isEmpty)
        let movedToFolder = library.move(bookmark.id, toFolder: "Reading")
        #expect(movedToFolder)
        #expect(library.links.first?.favorite == false)
        let rejectedFolder = library.move(bookmark.id, toFolder: String(repeating: "x", count: 41))
        #expect(!rejectedFolder)
        #expect(library.links.first?.folder == "Reading")
        library.removeAll()
        #expect(library.links.isEmpty)
    }


    @Test func favoriteDropsMoveInBothDirections() {
        var bookmarks = PrivateBookmarks()
        let first = PrivateBookmarks.Link(title: "First", url: "https://example.test/first", favorite: true)
        let middle = PrivateBookmarks.Link(title: "Middle", url: "https://example.test/middle", favorite: true)
        let last = PrivateBookmarks.Link(title: "Last", url: "https://example.test/last", favorite: true)
        let ordinary = PrivateBookmarks.Link(title: "Ordinary", url: "https://example.test/bookmark")
        for item in [first, ordinary, middle, last] { bookmarks.save(item) }

        let movedEarlier = bookmarks.reorderFavorite(middle.id, onto: first.id)
        #expect(movedEarlier)
        #expect(bookmarks.links.filter(\.favorite) == [middle, first, last])

        let movedLater = bookmarks.reorderFavorite(middle.id, onto: last.id)
        #expect(movedLater)
        #expect(bookmarks.links.filter(\.favorite) == [first, last, middle])
        #expect(bookmarks.links.filter { !$0.favorite } == [ordinary])

        let movedOntoBookmark = bookmarks.reorderFavorite(middle.id, onto: ordinary.id)
        let movedOntoSelf = bookmarks.reorderFavorite(middle.id, onto: middle.id)
        #expect(!movedOntoBookmark && !movedOntoSelf)
        #expect(bookmarks.links.filter(\.favorite) == [first, last, middle])
    }

}
