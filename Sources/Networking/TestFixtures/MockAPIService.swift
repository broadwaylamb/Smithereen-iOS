import Foundation
import Hammond
import SmithereenAPI

struct TestResponse: ResponseProtocol {
    var body: Data
    var statusCode: HTTPStatusCode
}

extension TestResponse {
    init(resource: String, statusCode: HTTPStatusCode) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json")
        else {
            fatalError("Resource '\(resource)' is not found in the bundle")
        }

        body = try! Data(contentsOf: url)
        self.statusCode = statusCode
    }
}

protocol TestableAPIRequest: SmithereenAPIRequest {
    func testResponse() async throws -> Result
}

extension Newsfeed.Get: TestableAPIRequest {
    func testResponse() async throws -> Result {
        let testData =
            TestResponse(resource: "testResponse-newsfeed.get", statusCode: 200)
        var result = try extractResult(from: testData)
        let filters = self.filters ?? Filter.allCases
        result.items = result.items.filter { update in
            switch update.item {
            case .post:
                filters.contains(.post)
            case .photo:
                filters.contains(.photo)
            case .photoTag:
                filters.contains(.photoTag)
            case .friend:
                filters.contains(.friend)
            case .groupJoin, .groupCreate:
                filters.contains(.group)
            case .eventJoin, .eventCreate:
                filters.contains(.event)
            case .board:
                filters.contains(.board)
            case .relation:
                filters.contains(.relation)
            }
        }
        return result
    }
}

extension Users.Get: TestableAPIRequest {
    func testResponse() async throws -> [User] {
        return [
            User(
                id: UserID(rawValue: 1),
                firstName: "Boromir",
                activityPubID: URL(string: "https://smithereen.local/users/1")!,
            )
        ]
    }
}

final class MockApi: AuthenticationService, APIService {
    func authenticate<Method: SmithereenOAuthTokenRequest>(
        host: String,
        port: Int?,
        method: Method,
    ) async throws {}

    func logOut() {}

    func invokeMethod<Method: SmithereenAPIRequest>(
        _ method: Method
    ) async throws -> Method.Result {
        if let testableRequest = method as? (any TestableAPIRequest) {
            return try await testableRequest.testResponse() as! Method.Result
        }
        fatalError(
            "\(Method.self) must implement the \((any TestableAPIRequest).self) protocol"
        )
    }
}

