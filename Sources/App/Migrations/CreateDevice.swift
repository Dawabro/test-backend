import Fluent

struct CreateDevice: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("devices")
            .id()
            .field("token", .string, .required)
            .field("platform", .string, .required)
            .field("user_identifier", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "token") // Prevent duplicate tokens
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("devices").delete()
    }
}
