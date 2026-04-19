# Amar Wallet - System Documentation & Architecture Overview

Amar Wallet is a "Voice-First" personal finance ecosystem built with Flutter. It combines modern architectural patterns (Clean Architecture + Riverpod) with Generative AI (Google Gemini) to transform natural language into structured financial data.

---

## 🏗 High-Level Architecture

The project follows a **Feature-Based Layered Architecture**. Instead of deep technical splits, code is organized by what it *does* for the user (e.g., Expenses, Goals, AI).

### 1. Core Layer (`lib/core`)
The "Engine Room" of the application.
- **Database**: `DatabaseHelper` (SQLite) manages 10+ tables with automatic migrations.
- **Theme**: `AmarTheme` provides a premium "Stitch"-inspired look with custom tokenization for light/dark modes.
- **Providers**: Global settings (Currency, Username, Goals).
- **Services**: `NotificationService` handles budget alerts and reminders.
- **Utils**: Local processing logic (e.g., `CategoryEngine` which auto-detects categories without needing AI).

### 2. Feature Layer (`lib/features`)
Each feature contains its own **Logic (Providers)**, **Models**, and **UI (Screens/Widgets)**.
- **Voice & AI**: The brain of the app. Integrates `speech_to_text` and `google_generative_ai`.
- **Dashboard**: The central hub that aggregates data from all other features.
- **Ledger**: specialized logic for Person-to-Person debts ("Lent" vs "Borrowed").
- **Goals & Budgets**: Monitoring tools that cross-reference spending data.

---

## 🎙 The Voice-to-Action Pipeline

This is the most critical flow in the project.

1.  **Capture**: User holds the Mic button. `VoiceService` uses the `speech_to_text` plugin to create a live transcription.
2.  **NLP Parsing**: The captured text is sent to the `AIService`.
    *   **AI Path**: If a Gemini API Key is present, it uses a highly-tuned prompt to identify multiple intents (e.g., "I spent 500 on dinner and lent 100 to Rahim").
    *   **Fallback Path**: If offline or no key is found, a regex-based `CategoryEngine` performs basic English/Bangla digit parsing.
3.  **Refinement**: The AI returns a JSON array of actions.
4.  **Confirmation**: The UI displays a `ConfirmationDialog` where the user verifies the AI's "understanding" before the data hits the database.
5.  **Persistence**: The parsed `ExpenseModel`, `IncomeModel`, or `LedgerModel` is saved via its respective Riverpod Notifier.

---

## 📊 Data Specifications

| Feature | Persistence | Logic |
| :--- | :--- | :--- |
| **Expenses** | SQL (`expenses`) | Tracked by item, amount, category, and date. |
| **Income** | SQL (`income`) | Grouped by source (Salary, Freelance, etc.). |
| **Ledger** | SQL (`ledger`) | Tracks `isPaid` status for debts. |
| **AI Insights** | Memory Cache | Real-time analysis of the last 30 days of data. |
| **Settings** | Secure Storage | API Keys and Personal Preferences. |

---

## 🛠 Tech Stack

*   **Framework**: Flutter (Dart)
*   **State Management**: `flutter_riverpod` (Notifiers/AsyncNotifiers)
*   **Database**: `sqflite` (Local SQL)
*   **AI**: `google_generative_ai` (Gemini 1.5 Flash)
*   **Voice**: `speech_to_text`
*   **UI/UX**: Custom Material 3 with Google Fonts (Inter, Plus Jakarta Sans)

---

## 🚀 How It Works (Dev Overview)

1.  **Initialization**: `main.dart` warms up the `NotificationService`.
2.  **Reactive UI**: Every screen "watches" a Riverpod Provider. For example, when you add an expense via voice, the `expenseListProvider` invalidates, and the `DashboardScreen` automatically rebuilds its charts.
3.  **Command Pattern**: The `VoiceCommandParser` intercepts specific voice commands like "Undo" or "Stop" locally, bypassing the expensive AI call for basic navigation.
4.  **Error Handling**: The system uses `AsyncValue` throughout, meaning if a database call fails, the UI displays a clean error state rather than crashing.

---

## 🔒 Security & Privacy

*   **Local Only**: All your financial transactions stay on your phone. They are never uploaded to a custom server.
*   **AI Privacy**: Only the *text* of your voice command is sent to Google's Gemini API for processing. Personal identifiers (like your name) are stripped where possible.
*   **Secure Storage**: Sensitive data like API Keys are encrypted using `flutter_secure_storage`.
