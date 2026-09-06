import Foundation

extension DecodingError {
    var mealPrepDiagnosticDescription: String {
        switch self {
        case .keyNotFound(let key, let context):
            "Missing key '\(key.stringValue)' at \(context.codingPath.mealPrepPath)."
        case .typeMismatch(let type, let context):
            "Expected \(type) at \(context.codingPath.mealPrepPath): \(context.debugDescription)"
        case .valueNotFound(let type, let context):
            "Missing \(type) value at \(context.codingPath.mealPrepPath)."
        case .dataCorrupted(let context):
            "Corrupted data at \(context.codingPath.mealPrepPath): \(context.debugDescription)"
        @unknown default:
            localizedDescription
        }
    }
}

private extension Array where Element == CodingKey {
    var mealPrepPath: String {
        isEmpty ? "root" : map(\.stringValue).joined(separator: ".")
    }
}
