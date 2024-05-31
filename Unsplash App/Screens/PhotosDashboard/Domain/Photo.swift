import Foundation

struct Photo: Codable {
    struct Urls: Codable {
        let small: URL
        let big: URL
    }
    
    let id: String
    let urls: Urls
    let authorName: String
    let createdAt: String
    let description: String
    let height: CGFloat
    let width: CGFloat
}
