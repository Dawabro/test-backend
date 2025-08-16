import Vapor

func routes(_ app: Application) throws {
    // Basic hello world endpoint
    app.get("hello") { req async -> String in
        return "Hello World!"
    }
    
    // Root endpoint
    app.get { req async -> String in
        return "Welcome to the API!"
    }
    
    // JSON response example
    app.get("json") { req async -> [String: String] in
        return ["message": "Hello World!", "status": "success"]
    }
}

