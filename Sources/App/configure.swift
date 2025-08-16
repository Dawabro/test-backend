import Vapor

public func configure(_ app: Application) throws {
    // Configure port for Railway
    if let portString = Environment.get("PORT"),
       let port = Int(portString) {
        app.http.server.configuration.port = port
    } else {
        app.http.server.configuration.port = 8080
    }
    
    // Configure hostname
    app.http.server.configuration.hostname = "0.0.0.0"
    
    // Register routes
    try routes(app)
}
