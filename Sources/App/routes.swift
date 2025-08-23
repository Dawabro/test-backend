import Fluent
import Vapor

func routes(_ app: Application) throws {
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
    
    // Structure for receiving POST data
    struct MessageRequest: Content {
        let message: String
    }
    
    // Structure for message response
    struct MessageResponse: Content {
        let id: UUID?
        let message: String
        let timestamp: String
        let status: String
    }
    
    // POST endpoint to save a message to database
    app.post("message") { req async throws -> MessageResponse in
        // Decode the JSON body
        let messageRequest = try req.content.decode(MessageRequest.self)
        
        // Validate message isn't empty
        guard !messageRequest.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Abort(.badRequest, reason: "Message cannot be empty")
        }
        
        // Create new message in database
        let message = Message(content: messageRequest.message)
        try await message.save(on: req.db)
        
        // Format timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        return MessageResponse(
            id: message.id,
            message: message.content,
            timestamp: formatter.string(from: message.createdAt ?? Date()),
            status: "Message saved successfully"
        )
    }
    
    // GET endpoint to retrieve the last message from database
    app.get("message") { req async throws -> MessageResponse in
        // Query the most recent message
        guard let message = try await Message.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .first() else {
            throw Abort(.notFound, reason: "No messages found")
        }
        
        // Format timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        return MessageResponse(
            id: message.id,
            message: message.content,
            timestamp: formatter.string(from: message.createdAt ?? Date()),
            status: "success"
        )
    }
    
    // GET endpoint to retrieve last message as plain text
    app.get("message", "text") { req async throws -> String in
        guard let message = try await Message.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .first() else {
            return "No messages yet"
        }
        
        return message.content
    }
    
    // GET endpoint to retrieve all messages
    app.get("messages") { req async throws -> [MessageResponse] in
        let messages = try await Message.query(on: req.db)
            .sort(\.$createdAt, .descending)
            .all()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        return messages.map { message in
            MessageResponse(
                id: message.id,
                message: message.content,
                timestamp: formatter.string(from: message.createdAt ?? Date()),
                status: "success"
            )
        }
    }
    
    // GET endpoint to retrieve a specific message by ID
    app.get("message", ":messageID") { req async throws -> MessageResponse in
        guard let messageID = req.parameters.get("messageID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid message ID")
        }
        
        guard let message = try await Message.find(messageID, on: req.db) else {
            throw Abort(.notFound, reason: "Message not found")
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        
        return MessageResponse(
            id: message.id,
            message: message.content,
            timestamp: formatter.string(from: message.createdAt ?? Date()),
            status: "success"
        )
    }
    
    // DELETE endpoint to delete all messages
    app.delete("messages") { req async throws -> [String: String] in
        try await Message.query(on: req.db).delete()
        return ["status": "All messages deleted"]
    }
    
    // DELETE endpoint to delete a specific message
    app.delete("message", ":messageID") { req async throws -> [String: String] in
        guard let messageID = req.parameters.get("messageID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid message ID")
        }
        
        guard let message = try await Message.find(messageID, on: req.db) else {
            throw Abort(.notFound, reason: "Message not found")
        }
        
        try await message.delete(on: req.db)
        return ["status": "Message deleted", "id": messageID.uuidString]
    }
    
    // Health check endpoint for database
    app.get("health") { req async throws -> [String: String] in
        // Try to connect to database
        _ = try await Message.query(on: req.db).count()
        return ["status": "healthy", "database": "connected"]
    }
}
