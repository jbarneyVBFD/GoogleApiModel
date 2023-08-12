# Google Api Model in Swift

**GoogleApiModel.swift** serves as a pivotal module within the **Conversationist** application. This module was designed to seamlessly connect with Google's Translation API. It can be easily integrated into other translation applications or any service looking to harness the power of Google's Translation API.

## Features:

1. **Dynamic URL Construction**: 
    - Utilize the `Api` enum to automatically construct URLs based on the desired API endpoint.

2. **Error Handling**: 
    - Leverage the `ApiError` enum to manage common errors encountered during API interactions.

3. **Language Capabilities**:
    - Retrieve supported languages for translation.
    - Identify the language of a given piece of text.
    - Conduct translations between a specified source and target language.

4. **Response Decoding**:
    - Decode and interpret JSON responses from the Google API with ease using pre-configured data models and the JSONDecoder.

5. **Configurable API Key**: 
    - Fetch your Google API key from a Config.plist file in the main bundle. This approach offers both flexibility and enhanced security.

## How to Use:

1. **Initialization**:
    - Begin by initializing the GoogleApiModel class. Make sure you have securely stored your Google API Key within a Config.plist file.
```swift
let googleApiModel = GoogleApiModel()
```

2. **Text Translation**:
```swift
do {
    let translatedText = try await googleApiModel.translate(for: "Hello", to: Locale(identifier: "fr"), from: Locale(identifier: "en"))
    print(translatedText) // Expected: "Bonjour"
} catch {
    print(error.localizedDescription)
}
```

3. **Retrieve Supported Languages**:
```swift
do {
    let (languages, languagesDict, locales) = try await googleApiModel.fetchLanguagesAsync()
    print(languages) // Will display a list of supported languages.
} catch {
    print(error.localizedDescription)
}
```

4. **Language Detection**:
```swift
do {
    let detectedLanguage = try await googleApiModel.detectLanguage(for: "Bonjour")
    print(detectedLanguage) // Expected: "fr"
} catch {
    print(error.localizedDescription)
}
```

## Dependencies:

- You must import the Foundation framework.
- Your project should contain a Config.plist file within the main bundle, as the Google API Key is fetched from this location.
