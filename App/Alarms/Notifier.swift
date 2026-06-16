import Foundation

protocol Notifier {
    func post(title: String, body: String, identifier: String)
    func remove(identifier: String)
}
