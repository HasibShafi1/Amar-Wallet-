# Amar Wallet

Amar Wallet is an intelligent, voice-powered personal finance application built with Flutter. It streamlines the process of tracking expenses by allowing users to simply speak their transactions, while leveraging the power of Google Generative AI (Gemini) to automatically categorize and structure the data.

## Features

- 🎙️ **Voice-Activated Logging**: Simply tap the microphone and speak (e.g., "I spent $15 on lunch at Subway") to log expenses quickly.
- 🧠 **AI-Powered Parsing**: Google Gemini automatically interprets your speech, extracting the amount, description, and category.
- 💡 **Smart Insights**: Get AI-generated financial insights and recommendations based on your recent spending habits.
- 🔒 **Local Storage & Security**: Your financial data is securely stored locally on your device using `sqflite` and `flutter_secure_storage`.
- ⚡ **Reactive State Management**: Built with Riverpod for robust and efficient state management.
- ✨ **Modern Material 3 UI**: Clean, beautiful, and intuitive user interface optimized for a pleasant user experience.

## Technology Stack

- **Framework**: Flutter
- **State Management**: Riverpod (`flutter_riverpod`)
- **AI Integration**: Google Generative AI (`google_generative_ai`)
- **Speech Recognition**: Speech to Text (`speech_to_text`)
- **Local Database**: SQLite (`sqflite`)
- **Secure Storage**: Flutter Secure Storage (`flutter_secure_storage`)

## Getting Started

### Prerequisites
- Flutter SDK (version 3.11.4 or higher)
- A Google Gemini API Key

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/HasibShafi1/Amar-Wallet-.git
   cd "Amar Wallet"
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Set up your API Key:**
   When you first run the app, you will be prompted to enter your Gemini API Key in the settings dialog. It will be securely stored on your device.

4. **Run the application:**
   ```bash
   flutter run
   ```

## Folder Structure

- `lib/core/`: Contains core constants, themes, and database setup.
- `lib/features/`: Contains feature-specific logic, organized by domain:
  - `ai/`: Services and logic for Google Generative AI integration.
  - `dashboard/`: The main UI screen for viewing totals and transactions.
  - `expenses/`: Data models, providers, and widgets for expense management.
  - `voice/`: Logic and widgets for speech-to-text functionality.

## License

This project is licensed under the MIT License.
