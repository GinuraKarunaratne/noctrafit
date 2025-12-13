# NoctraFit - Night Shift Fitness App

A complete offline-first fitness app designed specifically for night shift workers, built with Flutter and Firebase.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green)

## 🌙 Features

### Core Features

- ✅ **Offline-First Architecture** - Works 100% offline from first launch
- ✅ **Night Shift Optimized** - Dark theme with luminous green accents (#C6FF3D)
- ✅ **5 Accessibility Themes** - Default Night, Deuteranopia, Protanopia, Tritanopia, Monochrome
- ✅ **Text-to-Speech Navigation** - Screen summaries and workout milestones
- ✅ **Active Session Persistence** - Workouts survive app restart

### 5 Composite Widgets (Design Pattern)

1. **CW1: AdaptiveBannerCard** - Time-aware workout suggestions
2. **CW2: StatsGrid** - Reusable stat cards with trends
3. **CW3: LuminousChartCard** - Dark charts with luminous green
4. **CW4: ProgressHeatmapCard** - GitHub-style 365-day activity grid
5. **CW5: ActiveSessionMiniBar** - Global floating session bar

### 5 Unique Functional Features

1. **UF1: Offline Workout Catalog + Firestore Sync** - 10 seed workouts, background sync
2. **UF2: Create Custom Workouts** - Publish to community (Firestore)
3. **UF3: Active Session Mode** - Timer, milestones, persistence
4. **UF4: Global Floating Session Bar** - Visible on all screens
5. **UF5: Accessibility System** - 5 themes + TTS navigation

## 📱 Screenshots

| Home Screen | Active Session | Progress Heatmap |
|-------------|----------------|------------------|
| ![Home](docs/screenshot_home.png) | ![Session](docs/screenshot_session.png) | ![Heatmap](docs/screenshot_heatmap.png) |

## 🛠️ Tech Stack

- **Framework**: Flutter 3.0+
- **State Management**: Riverpod 2.5+
- **Local Database**: Drift (SQLite ORM)
- **Backend**: Firebase Firestore (free tier)
- **Navigation**: GoRouter 14.0+
- **Charts**: fl_chart
- **Icons**: Tabler Icons
- **Typography**: Google Fonts (Space Grotesk + Inter)

## 📂 Project Structure

```
noctrafit/
├── lib/
│   ├── app/
│   │   ├── router/          # GoRouter navigation
│   │   ├── theme/           # 5 accessibility themes
│   │   └── widgets/         # Shared widgets
│   ├── core/
│   │   ├── services/        # TTS, Connectivity, Sync
│   │   └── utils/           # Helpers
│   ├── data/
│   │   ├── local/
│   │   │   ├── db/          # Drift tables + DAOs
│   │   │   └── seed/        # Seed data loader
│   │   ├── remote/
│   │   │   └── firestore/   # Firestore client
│   │   └── repositories/    # Data layer
│   └── features/
│       ├── home/            # Home screen
│       ├── plans/           # Browse/create workouts
│       ├── calendar/        # Schedule workouts
│       ├── insights/        # Stats & charts
│       ├── profile/         # User profile + settings
│       └── session/         # Active workout session
├── assets/
│   └── seed/
│       └── workouts_seed.json  # 10 starter workouts
├── firestore.rules          # Firebase security rules
├── FIREBASE_SETUP.md        # Firebase setup guide
└── README.md                # This file
```

## 🚀 Getting Started

### Prerequisites

- Flutter 3.0 or higher
- Dart 3.0 or higher
- Android Studio / Xcode (for mobile development)
- Firebase account (free tier)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/noctrafit.git
   cd noctrafit
   ```

2. **Install dependencies:**
   ```bash
   cd noctrafit
   flutter pub get
   ```

3. **Generate Drift database code:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Set up Firebase:**
   - Follow [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for detailed instructions
   - Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

5. **Run the app:**
   ```bash
   flutter run
   ```

## 🗄️ Database Schema

### 7 Local Tables (Drift/SQLite)

1. **workout_sets** - Main workout content (seed/user/community)
2. **exercises** - Exercise reference library
3. **schedule_entries** - User's scheduled workouts
4. **completion_logs** - Workout history for insights
5. **preferences** - Key-value settings store
6. **active_session** - Single-row active workout state
7. **sync_queue** - Pending Firestore uploads

### Firestore Collections

1. **catalog_sets** - App-provided workouts (read-only)
2. **community_sets** - User-created workouts (read: all, write: own)
3. **metadata** - App metadata (catalog version)

## 🎨 Design System

### Color Palette

```dart
Background: #0B0D10  (Dark navy)
Surface:    #12151B  (Darker cards)
Border:     #1B202A  (Subtle borders)
Text 1:     #E8EDF5  (Primary text)
Text 2:     #9AA4B2  (Secondary text)
Accent:     #C6FF3D  (Luminous green - ONLY accent, NO blues)
```

### Typography

- **Headings**: Space Grotesk (28px, 18px)
- **Body**: Inter (14px, 12px)
- **Weights**: Regular (400), Semibold (600), Bold (700)

### Accessibility Modes

1. **Default Night** - Base dark theme
2. **Deuteranopia** - Red-green color blind (most common)
3. **Protanopia** - Red-green variant
4. **Tritanopia** - Blue-yellow color blind
5. **Monochrome** - High contrast with shapes for clarity

## 🔄 Offline-First Architecture

### Critical Flow

```
1. App Launch
   ↓
2. SeedLoader.loadSeedDataIfNeeded()  (BEFORE runApp!)
   ↓
3. Check preferences: has_seeded = true?
   ├─ Yes → Skip
   └─ No  → Load 10 workouts from assets/seed/workouts_seed.json
   ↓
4. UI Loads (seed data already in SQLite)
   ↓
5. Background Sync (every 30 min when online)
   ├─ Download catalog_sets
   ├─ Download community_sets (paginated, 50/page)
   └─ Upload pending from sync_queue
```

### Why This Works

- ✅ UI always loads from SQLite (never blank)
- ✅ Firestore sync is **optional enhancement**
- ✅ App works forever offline if user never connects
- ✅ Free tier compliant (sync every 30min, not realtime)

## 🧪 Testing

### Run Tests

```bash
# Unit tests
flutter test test/unit/

# Widget tests
flutter test test/widget/

# Integration tests
flutter test test/integration/
```

### Critical Test Cases

- ✅ Seed data loads on first launch
- ✅ App works 100% offline after first launch
- ✅ Active session persists across app restart
- ✅ Theme modes apply correctly (all 5)
- ✅ TTS speaks at correct times (not too much)
- ✅ Firestore sync doesn't overwrite user data

## 📊 Firebase Free Tier Compliance

### Strategy

- **No realtime listeners** - use `get()` instead
- **Sync every 30 minutes** - not on every change
- **Paginate queries** - limit 50 per request
- **Cache everything locally** - minimize redundant fetches
- **No Cloud Functions** - client SDK only

### Expected Usage (1,000 DAU)

- **Reads**: ~3,000/day (well under 50,000 limit)
- **Writes**: ~100/day (well under 20,000 limit)
- **Storage**: ~10 MB (well under 1 GB limit)

**Result**: Stays within free tier! 🎉

## 🔐 Security

### Firestore Rules

```javascript
// Read: everyone
// Write: authenticated users (own sets only)
match /community_sets/{setId} {
  allow read: if true;
  allow create: if request.auth != null && isValidWorkoutSet();
  allow update, delete: if request.auth.uid == resource.data.author_id;
}
```

See [firestore.rules](firestore.rules) for complete rules.

## 🎯 Roadmap

### Phase 1 (Complete ✅)
- [x] Offline-first architecture
- [x] 5 composite widgets
- [x] 9 feature screens
- [x] 5 accessibility themes
- [x] Firestore sync

### Phase 2 (Future)
- [ ] Social features (follow users, like workouts)
- [ ] Workout videos (optional video_url support)
- [ ] Nutrition tracking
- [ ] Wearable integration (Apple Watch, Fitbit)
- [ ] AI workout recommendations

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Run `dart format .` before committing
- Add TODO comments with references to providers when mocking data

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Night shift workers** - This app is for you!
- **Flutter team** - Amazing framework
- **Drift team** - Excellent SQLite ORM
- **Tabler Icons** - Beautiful minimal icons
- **fl_chart** - Great charting library

## 📧 Contact

For questions or feedback:
- Create an issue in this repository
- Email: support@noctrafit.com (placeholder)

## 🌟 Star History

If you find this project useful, please give it a star! ⭐

---

**Built with ❤️ for night shift workers everywhere.**
