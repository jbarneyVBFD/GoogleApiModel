//
//  GoogleApiModel.swift
//  ConversationTranslator
//
//  Created by John Barney on 12/3/21.
//

import Foundation

/// Represents the core model responsible for interacting with Google's translation API.
class GoogleApiModel: ObservableObject {
    
    // Google API key for making requests.
    private let apiKey: String? = GoogleAPIKey
    
    // Enum representing different API endpoints available within the Google Translation service.
    enum Api {
        case supportedLanguages
        case detector
        case translator
        
        /// Construct the appropriate URL based on the API endpoint and provided parameters.
        ///   - Parameters:
        ///   - apiKey: The Google API key.
        ///   - userText: Text input by the user. Default is an empty string.
        ///   - targetLocale: The locale to translate to. Default is an empty locale.
        ///   - sourceLocale: The source locale of the provided text. Default is an empty locale.
        func getURL(apiKey: String, userText: String = "", targetLocale: Locale = Locale(identifier: ""), sourceLocale: Locale = Locale(identifier: "")) -> URL {
            var urlString: String
            var urlParams = [String: String]()
            
            switch self {
            case .supportedLanguages:
                urlString = "https://translation.googleapis.com/language/translate/v2/languages"
                urlParams = [
                    "key": apiKey,
                    "model": "base",
                    "target": Locale.current.languageCode ?? "en"
                ]
                
            case .detector:
                urlString = "https://translation.googleapis.com/language/translate/v2/detect"
                urlParams = [
                    "key": apiKey,
                    "q": userText
                ]
                
            case .translator:
                urlString = "https://translation.googleapis.com/language/translate/v2"
                urlParams = [
                    "key": apiKey,
                    "q": userText,
                    "target": targetLocale.languageCode ?? targetLocale.identifier,
                    "format": "text",
                    "source": sourceLocale.languageCode ?? sourceLocale.identifier
                ]
            }
            
            var urlComponents = URLComponents(string: urlString)!
            urlComponents.queryItems = urlParams.map { URLQueryItem(name: $0, value: $1) }
            return urlComponents.url!
        }
    }
    
    // Enum representing potential errors during API interactions.
    enum ApiError: Error {
        case apiKeyMissing
        case fetchError
    }
    
    /// Fetch the supported languages for translation.
    func fetchLanguagesAsync() async throws -> ([TranslationLanguage], [String: String], [Locale]) {
        guard let apiKeyUnwrapped = apiKey else {
            throw ApiError.apiKeyMissing
        }
        let url = Api.supportedLanguages.getURL(apiKey: apiKeyUnwrapped)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        return parseJsonLanguages(resultsDict: data)
    }
    
    /// Parse the received data to extract supported languages.
    func parseJsonLanguages(resultsDict: Data?) -> ([TranslationLanguage], [String: String], [Locale]) {
        var languages = [TranslationLanguage]()
        var languagesDict = [String: String]()
        var locales = [Locale]()
        let decoder = JSONDecoder()
        do {
            if let results = resultsDict {
                let data = try decoder.decode(SupportedDataStore.self, from: results)
                for language in data.data.languages {
                    languages.append(language)
                    languagesDict[language.code] = language.name
                    locales.append(Locale(identifier: language.code))
                }
            }
        } catch {
            print(error.localizedDescription)
        }
        return (languages, languagesDict, locales)
    }
    
    /// Detect the language of the given text.
    func detectLanguage(for userText: String) async throws -> String {
        guard let apiKeyUnwrapped = apiKey else {
            throw ApiError.apiKeyMissing
        }
        let url = Api.detector.getURL(apiKey: apiKeyUnwrapped, userText: userText)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        return parseJsonDetector(data: data)
    }
    
    /// Translate the given text from source language to target language.
    func translate(for userText: String, to targetLocale: Locale, from sourceLocale: Locale) async throws -> String {
        guard let apiKeyUnwrapped = apiKey else {
            throw ApiError.apiKeyMissing
        }
        let url = Api.translator.getURL(apiKey: apiKeyUnwrapped, userText: userText, targetLocale: targetLocale, sourceLocale: sourceLocale)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, _) = try await URLSession.shared.data(for: request)
        return parseJsonTranslator(data: data)
    }
    
    /// Parse received data to identify detected language.
    private func parseJsonDetector(data: Data?) -> String {
        let decoder = JSONDecoder()
        do {
            if let results = data {
                let data = try decoder.decode(DetectorDataStore.self, from: results)
                return data.data.detections.first?.first?.name ?? ""
            }
        } catch {
            print(error.localizedDescription)
        }
        return ""
    }
    
    /// Parse received data to extract translated text.
    private func parseJsonTranslator(data: Data?) -> String {
        let decoder = JSONDecoder()
        do {
            if let results = data {
                let data = try decoder.decode(TranslatorDataStore.self, from: results)
                return data.data.translations.first?.translatedText ?? ""
            }
        } catch {
            print(error.localizedDescription)
        }
        return ""
    }
}

// MARK: - Data models used for decoding responses from Google's translation API.

extension GoogleApiModel {
    
    struct TranslationLanguage: Codable, Identifiable {
        var id = UUID()
        var code: String
        var name: String
        
        enum CodingKeys: String, CodingKey {
            case code = "language"
            case name
        }
    }
    
    struct TranslatorDataStore: Codable {
        var data: TranslationsStore
    }

    struct DetectorDataStore: Codable {
        var data: DetectionsStore
    }
    
    struct SupportedDataStore: Codable {
        var data: Languages
    }

    struct TranslationsStore: Codable {
        var translations: [Translation]
    }
    
    struct DetectionsStore: Codable {
        var detections: [[DetectedLanguage]]
    }
    
    struct Languages: Codable {
        var languages: [TranslationLanguage]
    }
    
    struct Translation: Codable {
        var translatedText: String
    }
    
    struct DetectedLanguage: Codable {
        var name: String
        
        enum CodingKeys: String, CodingKey {
            case name = "language"
        }
    }
}

// Utility to fetch Google API key from a Config.plist file in the main bundle.
var GoogleAPIKey: String? {
    if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
       let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
        return dict["GoogleAPIKey"] as? String
    }
    return nil
}
