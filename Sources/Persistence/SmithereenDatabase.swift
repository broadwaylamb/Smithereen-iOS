import Foundation
import GRDB
import SmithereenAPI

struct SmithereenDatabase: Sendable {
    let currentUserID: UserID
    private let writer: any DatabaseWriter

    var reader: any DatabaseReader {
        writer
    }

    static func createPersistent(currentUserID: UserID) throws -> SmithereenDatabase {
        let fm = FileManager.default
        let appSupportURL = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directoryURL = appSupportURL
            .appendingPathComponent("Smithereen", isDirectory: true)
        try fm.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let databaseURL = directoryURL.appendingPathComponent("db.sqlite")
        let config = GRDB.Configuration()
        let dbPool = try DatabasePool(path: databaseURL.path, configuration: config)

        let db = SmithereenDatabase(currentUserID: currentUserID, writer: dbPool)
        try db.runMigrations()
        return db
    }

    static func createInMemory(
        currentUserID: UserID = UserID(rawValue: 1),
    ) throws -> SmithereenDatabase {
        let config = GRDB.Configuration()
        let dbPool = try DatabaseQueue(configuration: config)
        let db = SmithereenDatabase(currentUserID: currentUserID, writer: dbPool)
        try db.runMigrations()
        return db
    }

    func runMigrations() throws {
        var migrator = DatabaseMigrator()

        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigrations(
            InitialMigration.self,
        )

        try migrator.migrate(writer)
    }

    func erase() async throws {
        try await writer.erase()
        try runMigrations()
    }

    @MainActor
    func observe<Value: Sendable>(
        _ fetch: @escaping @Sendable (Database) throws -> Value,
        onChange: @escaping @MainActor (Value) -> Void,
    ) -> AnyDatabaseCancellable {
        ValueObservation
            .tracking(fetch)
            .start(in: reader, onError: {
                assertionFailure(String(describing: $0))
            }, onChange: onChange)

    }

    @MainActor
    func observe<Value: Sendable, ViewModel: AnyObject>(
        assignOn viewModel: ViewModel,
        _ keyPath: WritableKeyPath<ViewModel, Value>,
        _ fetch: @escaping @Sendable (Database) throws -> Value
    ) -> AnyDatabaseCancellable {
        ValueObservation
            .tracking(fetch)
            .start(in: reader) {
                assertionFailure(String(describing: $0))
            } onChange: { [weak viewModel] value in
                viewModel?[keyPath: keyPath] = value
            }
    }
}

extension SmithereenDatabase {
    func cacheUsers(_ users: [User]) throws {
        try writer.write { db in
            for user in users {
                try user.prepareForDatabase().upsert(db)
            }
        }
    }

    func getUser(_ id: UserID?) throws -> User? {
        let id = id ?? currentUserID
        return try reader.read { db in
            try User.fetchOne(db, id: id)
        }
    }

    func getUsers(_ ids: [UserID]) throws -> [User] {
        try reader.read { db in
            try User.fetchAll(db, ids: ids)
        }
    }
}
