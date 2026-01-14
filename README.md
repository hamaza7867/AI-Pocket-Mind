# 🤖 AI Pocket Mind

A powerful multi-modal AI assistant app featuring a **Dual AI Core** (BYOAPI & Desktop Client) and privacy-first design.

## ✨ Features

- **🧠 Dual AI Modes**:
  - **☁️ Cloud (BYOAPI)**: Direct connection to OpenAI, Groq, DeepSeek, Mistral, and compatible APIs with your own keys.
  - **🖥️ Desktop Client**: Connects to the **PocketMind Desktop Bridge** for local, private AI processing (Ollama/Local LLM).

- **🎙️ Multi-Modal**:
  - Voice interaction (STT + TTS)
  - Image analysis (Vision Models)
  - PDF/Document Context (RAG via Desktop Bridge)

- **🔒 Privacy-First**:
  - Local-first History (SQLite)
  - **Supabase Integration** for syncing API configurations (Optional)
  - Bio-Lock Security (Fingerprint/FaceID)

- **🎨 Professional UI**:
  - Futuristic Glassmorphism aesthetics
  - Dynamic Dark/Light themes
  - Smooth animations & transitions

## 🚀 Quick Start

### Prerequisites

- Flutter 3.0+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Android Studio / VS Code
- A running instance of **PocketMind Desktop Bridge** (for Local Mode)
- Supabase Project (for Config Sync)

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd ai_pocket_mind/mobile
   ```

2. **🔑 CRITICAL: Set up environment variables**:
   ```bash
   # Copy the example file
   cp .env.example .env
   
   # Edit .env and add your keys
   ```

   Required keys in `.env`:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the app**:
   ```bash
   # Android
   flutter run

   # Release Build
   flutter build apk --release
   ```

## 🏗️ Architecture

```
┌──────────────────────────────────┐
│     AI Pocket Mind (Mobile)      │
│     (Dual Mode Controller)       │
└─────────────┬────────────────────┘
              │
      ┌───────┴───────┐
      ▼               ▼
  Cloud Mode      Desktop Mode
   (BYOAPI)        (Client)
      │               │
      │        ┌──────▼───────┐
      │        │ Desktop      │
      │        │ Bridge       │
      │        └──────┬───────┘
      │               ▼
  ┌───▼───┐       ┌───────┐
  │ APIs  │       │ Local │
  └───────┘       │ LLM   │
                  └───────┘
```

## 🛠️ Project Structure

```
lib/
├── main.dart                 # App Entry
├── providers/                # State Management (Provider)
│   ├── chat_provider.dart    # Core Chat Logic
│   └── theme_provider.dart
├── screens/                  # UI Layers
│   ├── chat_screen.dart
│   ├── settings_screen.dart  # Dual Mode Configuration
│   ├── wizard_screen.dart    # Onboarding
│   └── ...
├── services/                 # Business Logic
│   ├── ai_service.dart       # Abstract AI Interface
│   ├── supabase_service.dart # Config persistence
│   ├── tools_service.dart    # Function Calling Logic
│   ├── knowledge_service.dart# RAG/Memory Logic
│   └── auth_service.dart     # Bio-Lock & Auth
└── utils/                    # Shared Utilities
```

## 🔒 Security

**IMPORTANT**: This app uses environment variables for Supabase keys.
- **DO NOT** commit `.env` to version control.
- **DO NOT** hardcode API keys in the source.

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.

## 🆘 Support

For issues and questions:
- GitHub Issues: [https://github.com/hamaza7867/AI-Pocket-Mind/issues](https://github.com/hamaza7867/AI-Pocket-Mind/issues)
- Email: hamaza7867@gmail.com
