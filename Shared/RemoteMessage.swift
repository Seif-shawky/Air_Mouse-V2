import Foundation

enum RemoteMessage: Codable {
    case move(dx: Double, dy: Double)
    case click(kind: ClickKind)
    case scroll(dx: Double, dy: Double)
    case volume(delta: Double)

    enum ClickKind: String, Codable {
        case start
        case end
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case dx
        case dy
        case kind
        case delta
    }

    private enum MessageType: String, Codable {
        case move
        case click
        case scroll
        case volume
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MessageType.self, forKey: .type)

        switch type {
        case .move:
            self = .move(
                dx: try container.decode(Double.self, forKey: .dx),
                dy: try container.decode(Double.self, forKey: .dy)
            )
        case .click:
            self = .click(kind: try container.decode(ClickKind.self, forKey: .kind))
        case .scroll:
            self = .scroll(
                dx: try container.decode(Double.self, forKey: .dx),
                dy: try container.decode(Double.self, forKey: .dy)
            )
        case .volume:
            self = .volume(delta: try container.decode(Double.self, forKey: .delta))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .move(dx, dy):
            try container.encode(MessageType.move, forKey: .type)
            try container.encode(dx, forKey: .dx)
            try container.encode(dy, forKey: .dy)
        case let .click(kind):
            try container.encode(MessageType.click, forKey: .type)
            try container.encode(kind, forKey: .kind)
        case let .scroll(dx, dy):
            try container.encode(MessageType.scroll, forKey: .type)
            try container.encode(dx, forKey: .dx)
            try container.encode(dy, forKey: .dy)
        case let .volume(delta):
            try container.encode(MessageType.volume, forKey: .type)
            try container.encode(delta, forKey: .delta)
        }
    }
}
