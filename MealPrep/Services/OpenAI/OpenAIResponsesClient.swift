import Foundation

struct OpenAIResponsesClient {
    private let apiKey: String
    private let model: String
    private let session: URLSession

    init(
        apiKey: String = OpenAIConfiguration.apiKey,
        model: String = "gpt-5.6-terra",
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.model = model
        self.session = session
    }

    func structuredResponse(
        instructions: String,
        input: String,
        schema: [String: Any]
    ) async throws -> Data {
        let normalizedAPIKey = apiKey
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(
                of: "^Bearer\\s+",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedAPIKey.isEmpty else {
            throw MealPlanGenerationError.missingOpenAIAPIKey
        }
        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            throw MealPlanGenerationError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("Bearer \(normalizedAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": model,
            "store": false,
            "max_output_tokens": 32_768,
            "instructions": instructions,
            "input": input,
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "weekly_meal_plan",
                    "strict": true,
                    "schema": schema
                ]
            ]
        ])

        guard request.value(forHTTPHeaderField: "Authorization") != nil else {
            throw MealPlanGenerationError.invalidOpenAIAPIKeyConfiguration
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MealPlanGenerationError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            let message = (try? JSONDecoder().decode(OpenAIErrorEnvelope.self, from: data).error.message)
                ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            throw MealPlanGenerationError.api("OpenAI HTTP \(httpResponse.statusCode): \(message)")
        }

        let payload: OpenAIResponse
        do {
            payload = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        } catch let error as DecodingError {
            throw MealPlanGenerationError.responseDecodingFailed(
                "OpenAI envelope: \(error.mealPrepDiagnosticDescription)"
            )
        }

        if let usage = payload.usage {
            let input = usage.inputTokens ?? 0
            let cached = usage.inputTokensDetails?.cachedTokens ?? 0
            let cacheWrite = usage.inputTokensDetails?.cacheWriteTokens ?? 0
            let output = usage.outputTokens ?? 0
            let reasoning = usage.outputTokensDetails?.reasoningTokens ?? 0
            let total = usage.totalTokens ?? (input + output)
            print(
                "[MealPrep][OpenAI] Tokens — input: \(input) "
                    + "(cached: \(cached), cache write: \(cacheWrite)), "
                    + "output: \(output) (reasoning: \(reasoning)), total: \(total)"
            )
        } else {
            print("[MealPrep][OpenAI] Token usage unavailable for this response.")
        }

        if payload.status == "incomplete" {
            throw MealPlanGenerationError.generationIncomplete(
                reason: payload.incompleteDetails?.reason ?? "unknown reason",
                outputTokens: payload.usage?.outputTokens
            )
        }

        let text = payload.output
            .flatMap(\.content)
            .filter { $0.type == "output_text" }
            .compactMap(\.text)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let result = text.data(using: .utf8) else {
            throw MealPlanGenerationError.missingOutput
        }
        return result
    }
}

enum OpenAIConfiguration {
    static var apiKey: String {
        ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
            ?? ProcessInfo.processInfo.environment["OPENAI-API-KEY"]
            ?? Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "OPENAI-API-KEY") as? String
            ?? ""
    }
}

private struct OpenAIResponse: Decodable {
    struct OutputItem: Decodable {
        struct ContentItem: Decodable {
            let type: String
            let text: String?
        }

        let content: [ContentItem]
    }

    struct IncompleteDetails: Decodable {
        let reason: String?
    }

    struct Usage: Decodable {
        struct InputTokensDetails: Decodable {
            let cachedTokens: Int?
            let cacheWriteTokens: Int?

            private enum CodingKeys: String, CodingKey {
                case cachedTokens = "cached_tokens"
                case cacheWriteTokens = "cache_write_tokens"
            }
        }

        struct OutputTokensDetails: Decodable {
            let reasoningTokens: Int?

            private enum CodingKeys: String, CodingKey {
                case reasoningTokens = "reasoning_tokens"
            }
        }

        let inputTokens: Int?
        let inputTokensDetails: InputTokensDetails?
        let outputTokens: Int?
        let outputTokensDetails: OutputTokensDetails?
        let totalTokens: Int?

        private enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case inputTokensDetails = "input_tokens_details"
            case outputTokens = "output_tokens"
            case outputTokensDetails = "output_tokens_details"
            case totalTokens = "total_tokens"
        }
    }

    let status: String?
    let incompleteDetails: IncompleteDetails?
    let output: [OutputItem]
    let usage: Usage?

    private enum CodingKeys: String, CodingKey {
        case status
        case incompleteDetails = "incomplete_details"
        case output
        case usage
    }
}

private struct OpenAIErrorEnvelope: Decodable {
    struct APIError: Decodable { let message: String }
    let error: APIError
}
