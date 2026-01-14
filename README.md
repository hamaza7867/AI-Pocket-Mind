# 🤖 AI Pocket Mind

A powerful multi-modal AI assistant app with hybrid intelligence modes and privacy-first design.

## ✨ Features

- **🧠 Hybrid AI Modes**:
  - Cloud API (OpenAI, Groq, DeepSeek, Mistral, etc.)
  - Local Network (Ollama via Desktop Bridge)
  - RAG Knowledge Base (Python vector DB backend)

- **🎙️ Multi-Modal**:
  - Voice interaction (STT + TTS)
  - Image analysis
  - Document Q&A (PDF/TXT)

- **🔒 Privacy-First**:
  - Local-first SQLite storage
  - Cloud sync with Supabase (optional)
  - Secure environment variable management

- **🎨 Professional UI**:
  - Futuristic glassmorphism theme
  - Dark mode support
  - Smooth animations

## 🚀 Quick Start

### Prerequisites

- Flutter 3.0+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Android Studio / VS Code
- Android SDK (for Android builds)
- Xcode (for iOS builds, macOS only)

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd ai_pocket_mind
   ```

2. **🔑 CRITICAL: Set up environment variables**:
   ```bash
   # Copy the example file
   copy .env.example .env
   
   # Edit .env and add your API keys
   notepad .env
   ```

   Required keys in `.env`:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your_supabase_anon_key
   GOOGLE_WEB_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
   TAVILY_API_KEY=tvly-your-tavily-key
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the app**:
   ```bash
   # Android/iOS
   flutter run
   
   # Windows Desktop
   flutter run -d windows
   
   # Web
   flutter run -d chrome
   ```

## 🔑 Getting API Keys

### Supabase (Required)

1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Go to Settings → API
4. Copy `Project URL` and `anon/public key`

### Google Sign-In (Optional)

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a project
3. Enable Google Sign-In API
4. Create OAuth 2.0 credentials (Web application)
5. Copy the Web Client ID

### Tavily API (Optional - for web search)

1. Go to [tavily.com](https://tavily.com)
2. Sign up and get API key

## 🏗️ Architecture

```

┌──────────────────────────────────┐
│     AI Pocket Mind               │
│  (Multi-Modal AI Assistant)      │
└─────────────┬────────────────────┘
              │
      ┌───────┴───────┐
      ▼               ▼
  Local-First    Cloud Sync
  (SQLite)       (Supabase)
      │               │
      └───────┬───────┘
              ▼
       ┌─────────────┐
       │  AI Modes   │
       ├─────────────┤
       │ Cloud API   │ ← OpenAI, Groq, etc.
       │ Network     │ ← Ollama Desktop Bridge
       │ RAG         │ ← Python Vector DB
       └─────────────┘
```

## 📱 Building for Production

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS (macOS only)

```bash
flutter build ios --release
```

## 🛠️ Development

### Project Structure

```
lib/
├── main.dart              # App entry point
├── providers/             # State management
│   ├── chat_provider.dart
│   └── theme_provider.dart
├── screens/               # UI screens
│   ├── chat_screen.dart
│   ├── login_screen.dart
│   ├── settings_screen.dart
│   └── ...
├── services/              # Business logic
│   ├── ai_service.dart
│   ├── database_helper.dart
│   ├── supabase_service.dart
│   └── app_config.dart    # 🔒 Secure env vars
├── widgets/               # Reusable components
└── utils/                 # Utilities
```

### Running Tests

```bash
flutter test
```

### Code Quality

```bash
# Analyze code
flutter analyze

# Auto-fix issues
flutter fix --apply

# Format code
flutter format lib/
```

## 🔒 Security

**IMPORTANT**: This app uses environment variables for API keys.

✅ **DO**:
- Keep `.env` file LOCAL only
- Use `.env.example` as a template
- Rotate keys if accidentally exposed

❌ **DON'T**:
- Commit `.env` to version control
- Share your `.env` file
- Hardcode API keys in source code

## 🐛 Troubleshooting

### "Missing environment variable" error

**Solution**: Make sure `.env` file exists and contains all required keys.

```bash
# Check if .env exists
dir .env

# If not, copy from example
copy .env.example .env
```

### Build errors

```bash
# Clean build
flutter clean
flutter pub get
flutter build apk
```

### Supabase connection issues

1. Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `.env`
2. Check internet connection
3. Verify Supabase project is active

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Supabase Flutter Guide](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [Provider State Management](https://pub.dev/packages/provider)

## 📄 License

[Add your license here]

## 👥 Contributing

[Add contribution guidelines]

## 🆘 Support

For issues and questions:
- GitHub Issues: [Add link]
- Email: [Add email]

---

**Version**: 1.0.0+22  
**Last Updated**: January 2026

**🔐 Security Notice**: This project uses secure environment variable management. Never commit API keys to version control!
