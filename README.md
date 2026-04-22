# HK Jetso Searcher (香港商舖優惠搜尋器)

A cross-platform Flutter application providing an elegant interface for searching, filtering, and persisting daily discounts, retail coupons, and payment method rewards in Hong Kong.

## Features
- **Recent Deals Feed**: A dedicated tab for upcoming global discounts. Replaces legacy calendar views with a prioritized "Today" and "Tomorrow" list of valid deals across all shops.
- **Smart Discount Engine**: Automatically groups applicable deals based on date (Today, Tomorrow, Future) and calculates minimum spend eligibility and payment method requirements using a 30-day lookahead window.
- **Categorized Rejection Feed**: Transparently shows exactly why certain discounts failed to apply using color-coded feedback (e.g., "Budget Requirement Not Met", "Missing Payment Method" - Red Border).
- **Offline First**: Runs completely on the client using robust JSON-loaded catalogs (`shops.json`, `discounts.json`, `payment_methods.json`). User histories and settings are instantly saved using `shared_preferences`.
- **Intelligent Presets**: Save complex search queries (target shop + specific budget) into a quick-access Preset list. Tapping a preset instantly launches a new search with pre-filled conditions.
- **Deal Reminders & Push Notifications**: Native integration allowing users to attach precise Date & Time alarms to individual deals, triggering local push notifications on mobile devices.
- **Deep Linking**: Seamlessly jumps out of the app directly into payment or booking platforms (PayMe, Alipay, Klook, OpenRice, KKday, etc.) using custom URL schemes and external browser launches.
- **Automated AI Deal Scraping**: Powered by daily GitHub Actions and Gemini AI, unstructured RSS feeds are parsed and filtered against our strict schema, staging them in an internal "Admin Panel" for 1-click commits.
- **Smart AI Chatbot (Web & Telegram)**: A dedicated Telegram Bot ([@IssacTaiJetsoBot](https://t.me/IssacTaiJetsoBot)) and Web Chat Interface powered by **Google Gemini** utilizing a **Native Python Skills Architecture**. It integrates function calling natively skipping strict protocol overhead to provide real-time discount search via natural language.
- **Progressive Web App (PWA)**: Fully optimized for web deployments with custom masking icons and manifest configuration.
- **Multi-Language Support**: Complete localization bridging `English (en)` and `Traditional Chinese (zh)`. Allows dynamically switching UI strings and database descriptions in real-time.
- **Dynamic Theme System**: Modern Material 3 interface supporting Dark Mode and a refined "Deep Light Blue" Light Mode to optimize professional contrast.

## Tech Stack
- **Framework**: Flutter (Web / Mobile ready / PWA)
- **State Management**: Riverpod (`flutter_riverpod` + Notifier Providers)
- **Data Persistence**: `shared_preferences`
- **Native Integrations**: `url_launcher` (Deep Links), `flutter_local_notifications` (Push)
- **Serverless & API**: Python (`fastapi`, `python-telegram-bot`, `google-genai`), Python Skills Architecture
- **Automation & Deployment**: GitHub Actions, Render Webhooks (zero-cost serverless architecture)
- **Date Formatting**: `intl`, `timezone`
- **UI Components**: Native Material 3 & Custom layout builders (e.g., `DiscountTile`, Flexbox grouping)

## Getting Started

### Prerequisites
Make sure you have [Flutter](https://docs.flutter.dev/get-started/install) installed on your machine.
```bash
flutter doctor
```

### Installation
1. Clone this repository:
```bash
git clone https://github.com/YourUsername/jetso-showcase.git
cd jetso-showcase
```

2. Fetch dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
# Run natively on Web
flutter run -d chrome

# Run natively on Desktop
flutter run -d windows
```

### Automated Deployment (GitHub Pages)
This repository includes a pre-configured GitHub Actions workflow (`.github/workflows/flutter_web.yml`) that automatically compiles the Web artifact and deploys the `main` branch directly to GitHub Pages on every push.

To set up:
1. Ensure your repository is named `jetso-showcase` (or update the `--base-href` property in the workflow YAML).
2. Go to your repository `Settings -> Actions -> General`. Under **Workflow permissions**, select **Read and write permissions**.
3. Go to `Settings -> Pages`. Under **Build and deployment -> Source**, select **GitHub Actions**.

### Backend API & Chatbot Setup (Python)
The project ships with a backend server that hosts the Web Admin Panel, exposes the Chat endpoints, and listens for the Telegram bot webhooks. This is now driven by a native pure Python Skills architecture rather than the heavier MCP framework.

1. Ensure you have [`uv`](https://github.com/astral-sh/uv) installed to manage the Python environment.
2. Create a `.env` file inside the root directory and configure the needed keys:
```env
GEMINI_API_KEY=your_gemini_key_here
TELEGRAM_BOT_TOKEN=your_telegram_token_here
```
3. Run the application logic locally:
```bash
uv run --env-file .env python server/app.py
```
This will mount the server locally at `http://localhost:8080`.
- The Web Admin Interface is accessible at `http://localhost:8080/admin`.
- The Chatbot relies on the API binding and can be tested using the widget.
