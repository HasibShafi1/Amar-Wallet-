# Amar Wallet

Amar Wallet is an intelligent, voice-powered personal finance ecosystem built with Flutter. It streamlines the process of tracking expenses by allowing users to simply speak their transactions, while leveraging the power of Google Generative AI (Gemini) to automatically categorize and structure the data.

## 🌟 Key Features

- 🎙️ **Voice-Activated Logging**: Speak naturally (e.g., "I spent $15 on lunch and gave John $20") to log complex, multi-intent transactions.
- 🧠 **AI-Powered Parsing**: Deep integration with Google Gemini to automatically interpret speech, extracting intents, amounts, descriptions, and categories in both English and Bangla.
- 💡 **Smart Insights & Analytics**: Real-time AI-generated financial insights, deep analytics with interactive charts, and category breakdowns.
- 🤝 **Ledger & Debt Tracking**: Keep track of money lent to or borrowed from friends automatically as part of your voice tracking.
- 🎯 **Goals & Budgets**: Set dynamic spending budgets per category, and visual savings goals.
- 📅 **Subscriptions**: Track recurring payments and visualize your monthly fixed costs.
- 🏷️ **Tagging System**: Organize expenses granularly using customizable tags.
- 🔔 **Smart Reminders**: Local notifications for subscription due dates, budget overages, and daily summaries.
- 🔒 **Local Storage & Privacy**: All transactional data is stored 100% locally on your device via SQLite. API keys are encrypted via Secure Storage.

## 🛠️ Technology Stack

- **Framework**: Flutter (Dart)
- **Architecture**: Feature-Based Clean Architecture
- **State Management**: Riverpod (`flutter_riverpod`)
- **AI Integration**: Google Generative AI (`google_generative_ai`)
- **Speech Recognition**: Speech to Text (`speech_to_text`)
- **Local Database**: SQLite (`sqflite`)
- **Background Tasks**: Flutter Local Notifications (`flutter_local_notifications`)
- **Charts**: FL Chart (`fl_chart`)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (version 3.16.0 or higher)
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
   Launch the app and navigate to **Settings > AI Settings**. Enter your Gemini API Key. It will be encrypted and saved locally.

4. **Run the application:**
   ```bash
   flutter run
   ```

## 📂 Architecture Overview

For a detailed technical look at how the app makes decisions, manages the voice-to-structured-data pipeline, and maintains performance, see the [SYSTEM_OVERVIEW.md](SYSTEM_OVERVIEW.md) file.

## 📄 License

This project is licensed under the MIT License.
