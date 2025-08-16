import Vapor

final class MessageStorage {
    var lastMessage: String = "No messages yet"
    var timestamp: Date = Date()
}

func routes(_ app: Application) throws {
    // Create a shared storage instance
    let storage = MessageStorage()
    
    // Original endpoints
    app.get("hello") { req async -> String in
        return "Hello World!"
    }
    
    app.get { req async -> String in
        return "Welcome to the API!"
    }
    
    app.get("json") { req async -> [String: String] in
        return ["message": "Hello World!", "status": "success"]
    }
    
    // NEW: Structure for receiving POST data
    struct MessageRequest: Content {
        let message: String
    }
    
    // NEW: Structure for message response
    struct MessageResponse: Content {
        let message: String
        let timestamp: String
        let status: String
    }
    
    // NEW: POST endpoint to receive a message
    app.post("message") { req async throws -> MessageResponse in
        // Decode the JSON body
        let messageRequest = try req.content.decode(MessageRequest.self)
        
        // Validate message isn't empty
        guard !messageRequest.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "Message cannot be empty")
        }
        
        // Store the message
        storage.lastMessage = messageRequest.message
        storage.timestamp = Date()
        
        // Return confirmation
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        return MessageResponse(
            message: messageRequest.message,
            timestamp: formatter.string(from: storage.timestamp),
            status: "Message saved successfully"
        )
    }
    
    // NEW: GET endpoint to retrieve the last message
    app.get("message") { req async -> MessageResponse in
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        return MessageResponse(
            message: storage.lastMessage,
            timestamp: formatter.string(from: storage.timestamp),
            status: "success"
        )
    }
    
    // NEW: GET endpoint to retrieve last message as plain text
    app.get("message", "text") { req async -> String in
        return storage.lastMessage
    }
    
    // NEW: DELETE endpoint to clear the message
    app.delete("message") { req async -> [String: String] in
        storage.lastMessage = "No messages yet"
        storage.timestamp = Date()
        return ["status": "Message cleared"]
    }
}
