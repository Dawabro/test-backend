import Fluent
import FluentPostgresDriver
import Vapor
import VaporAPNS

public func configure(_ app: Application) throws {
    configureRailwayPort(app)
    
    // Configure hostname
    app.http.server.configuration.hostname = "0.0.0.0"
    
    try configureDatabase(app)
    try registerMigrations(app)
    
    // Register routes
    try routes(app)
}

private func configureRailwayPort(_ app: Application) {
    if let portString = Environment.get("PORT"), let port = Int(portString) {
        app.http.server.configuration.port = port
    } else {
        app.http.server.configuration.port = 8080
    }
}

private func configureDatabase(_ app: Application) throws {
    if let databaseURL = Environment.get("DATABASE_URL") {
        // Parse DATABASE_URL for Railway PostgreSQL
        try app.databases.use(.postgres(url: databaseURL), as: .psql)
    } else {
        // Local development fallback
        app.databases.use(.postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor",
            database: Environment.get("DATABASE_NAME") ?? "vapor"
        ), as: .psql)
    }
}

private func registerMigrations(_ app: Application) throws {
    app.migrations.add(CreateMessage())
    
    // Run migrations automatically (for development)
    // In production, you might want to run migrations manually
    try app.autoMigrate().wait()
}

// TODO: Implement APNS
private func configureAPNS(_ app: Application) throws {
    let privateKey = Environment.get("APNS_PRIVATE_KEY") ?? ""
    let keyIdentifier = Environment.get("APNS_KEY_ID") ?? ""
    let teamIdentifier = Environment.get("APNS_TEAM_ID") ?? ""
    
    app.apns.configure(.jwt(privateKey: try .loadFrom(string: privateKey), keyIdentifier: keyIdentifier, teamIdentifier: teamIdentifier))
}
