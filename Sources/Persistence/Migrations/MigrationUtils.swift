import GRDB

protocol DatabaseMigration: SendableMetatype {
    static var name: String { get }
    static func migrate(_ db: Database) throws
}

extension DatabaseMigrator {
    mutating func registerMigrations(_ migrations: DatabaseMigration.Type...) {
        self.registerMigrations(migrations)
    }

    mutating func registerMigrations<S: Sequence<DatabaseMigration.Type>>(
        _ migrations: S
    ) {
        for migration in migrations {
            registerMigration(migration.name, migrate: migration.migrate)
        }
    }
}
