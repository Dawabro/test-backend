import Fluent
import FluentPostgresDriver
import NIOSSL
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
        // Parse DATABASE_URL and handle Railway's SSL requirements
        var postgresConfig = try SQLPostgresConfiguration(url: databaseURL)
        
        // Configure SSL for Railway PostgreSQL
        var tlsConfig = TLSConfiguration.makeClientConfiguration()
        tlsConfig.certificateVerification = .none // Railway uses self-signed certs
        postgresConfig.coreConfiguration.tls = .require(try NIOSSLContext(configuration: tlsConfig))
        
        app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
    } else {
        // Local development fallback - using the new non-deprecated method
        let postgresConfig = SQLPostgresConfiguration(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "vapor",
            password: Environment.get("DATABASE_PASSWORD") ?? "vapor",
            database: Environment.get("DATABASE_NAME") ?? "vapor",
            tls: .disable
        )
        
        app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
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
