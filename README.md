# HK Jetso Searcher (香港商舖優惠搜尋器)

A cross-platform Flutter application providing an elegant interface for searching, filtering, and persisting daily discounts, retail coupons, and payment method rewards in Hong Kong.

## Features
- **Smart Discount Engine**: Automatically groups applicable deals based on date (Today, Tomorrow, Future) and calculates minimum spend eligibility and payment method requirements.
- **Categorized Rejection Feed**: Transparently shows exactly why certain discounts failed to apply (e.g., "Budget Requirement Not Met", "Missing Payment Method", "Not a Member", "Individual Product Deals").
- **Offline First**: Runs completely on the client using robust JSON-loaded catalogs (`shops.json`, `discounts.json`, `payment_methods.json`). User histories and settings are instantly saved using `shared_preferences`.
- **Intelligent Presets**: Save complex search queries (target shop + specific budget) into a quick-access Preset list. Tapping a preset instantly launches a new search with pre-filled conditions.
- **Deal Reminders**: Native integration allowing users to attach precise Date & Time alarms to individual expiring deals.
- **Multi-Language Support**: Complete localization bridging `English (en)` and `Traditional Chinese (zh)`. Allows dynamically switching UI strings and database descriptions in real-time.
- **Light & Dark Theme**: Universal design system supporting dynamic App-wide aesthetic switching.

## Tech Stack
- **Framework**: Flutter (Web / Mobile ready)
- **State Management**: Riverpod (`flutter_riverpod` + Notifier Providers)
- **Data Persistence**: `shared_preferences`
- **Date Formatting**: `intl`
- **UI Components**: Native Material 3, `table_calendar`, & Custom layout builders

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
