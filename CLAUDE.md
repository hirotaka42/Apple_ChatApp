# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI-based iOS application demonstrating integration with Apple's FoundationModels framework for on-device AI chat functionality. The app provides a chat interface with model availability detection and Japanese localization.

## Technology Stack

- Swift 5.0
- SwiftUI
- Apple FoundationModels framework
- Xcode 26.0.1
- iOS 26.0 minimum deployment target

## Build Commands

Open and build the project in Xcode:
```bash
open SampleFoundationModels.xcodeproj
```

Build from command line:
```bash
xcodebuild -project SampleFoundationModels.xcodeproj -scheme SampleFoundationModels -configuration Debug
```

Build and run in simulator:
```bash
xcodebuild -project SampleFoundationModels.xcodeproj -scheme SampleFoundationModels -destination 'platform=iOS Simulator,name=iPhone 16' -configuration Debug
```

## Architecture

### Core Components

**SampleFoundationModelsApp.swift**: Application entry point using SwiftUI's `@main` attribute.

**ContentView.swift**: Contains the entire chat UI implementation with three main structures:
- `ChatMessage`: Message model with role (user/assistant/system), text, and timestamp
- `ContentView`: Navigation wrapper around GenerativeView
- `GenerativeView`: Main chat interface with model availability handling

### Model Integration Pattern

The app uses `SystemLanguageModel.default` from FoundationModels framework. Key integration points:

1. **Model Availability States** (ContentView.swift:45-64):
   - `.available`: Model ready to use
   - `.unavailable(.deviceNotEligible)`: Device doesn't support Apple Intelligence
   - `.unavailable(.appleIntelligenceNotEnabled)`: Feature disabled in settings
   - `.unavailable(.modelNotReady)`: Model still downloading/initializing

2. **Session Management** (ContentView.swift:42, 168-176):
   - Optional session object for stateful API usage
   - Uncomment `prepareSessionIfNeeded()` if session required
   - Example: `let session = try await model.makeSession()`

3. **Response Generation** (ContentView.swift:178-215):
   - Currently uses echo implementation (`echoReply`)
   - Replace with actual API call based on your FoundationModels version:
     - Direct: `let replyText = try await model.respond(to: prompt)`
     - With response wrapper: `let replyText = (try await model.respond(to: prompt)).content`
     - Session-based: `let replyText = try await session.respond(to: prompt)`

### UI Architecture

- **State Management**: Uses SwiftUI `@State` for messages array, input text, sending status
- **Auto-scrolling**: ScrollViewReader ensures latest message visible (ContentView.swift:77-96)
- **Error Handling**: Alert-based error display with `lastError` state (ContentView.swift:110-117)
- **Input Validation**: Disables send button when text empty or sending in progress

## Development Notes

### Active TODOs in Code

The implementation includes placeholder code marked with Japanese comments. To complete the integration:

1. Determine which FoundationModels API pattern your iOS 26 SDK uses
2. Uncomment the appropriate API call in `send()` method (ContentView.swift:194-205)
3. If session-based, uncomment session initialization in `.task` modifier (ContentView.swift:50)
4. Remove the `echoReply` temporary implementation (ContentView.swift:218-220)

### Localization

UI text is in Japanese:
- "メッセージを入力" (Enter message)
- "クリア" (Clear)
- Error messages about model availability

Consider extracting to localizable strings if adding multi-language support.

### Testing on Device

This app requires:
- Physical iOS device or simulator running iOS 26+
- Apple Intelligence enabled in Settings (for actual model usage)
- Device eligible for on-device AI (A17 Pro / M-series chips or newer)

The app will show appropriate unavailability messages if requirements not met.

## File Structure

```
SampleFoundationModels/
├── SampleFoundationModels.xcodeproj/    # Xcode project configuration
└── SampleFoundationModels/              # Source code directory
    ├── SampleFoundationModelsApp.swift  # App entry point
    ├── ContentView.swift                # Chat UI and model integration
    └── Assets.xcassets/                 # App assets and images
```
