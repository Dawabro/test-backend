import Fluent
import Vapor

final class Device: Model, Content {
    static let schema = "devices"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "token")
    var token: String
    
    @Field(key: "platform")
    var platform: String // "ios" or "android"
    
    @OptionalField(key: "user_identifier")
    var userIdentifier: String?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, token: String, platform: String = "ios", userIdentifier: String? = nil) {
        self.id = id
        self.token = token
        self.platform = platform
        self.userIdentifier = userIdentifier
    }
}
