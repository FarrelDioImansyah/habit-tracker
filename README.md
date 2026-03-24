# Habit Tracker — Flutter + Supabase

Aplikasi pelacak kebiasaan baik (good habit) dan kebiasaan buruk (bad habit) 
dengan timer relapse, streak, statistik, dan notifikasi.

---

## Tech Stack

| Layer | Teknologi |
|---|---|
| Framework | Flutter 3.x |
| Backend | Supabase (PostgreSQL + Auth + Realtime) |
| State Management | Riverpod 2 |
| Navigasi | GoRouter |
| Notifikasi | flutter_local_notifications |
| Cache lokal | Hive |
| Grafik | fl_chart + table_calendar |

---

## Cara Setup

### 1. Clone & install dependencies

```bash
git clone <repo-url>
cd habit_tracker
flutter pub get
```

### 2. Buat project Supabase

1. Buka [supabase.com](https://supabase.com) → New Project
2. Salin **Project URL** dan **anon key** dari Settings > API
3. Jalankan SQL schema:
   - Buka **SQL Editor** di dashboard Supabase
   - Copy-paste isi file `supabase/schema.sql`
   - Klik Run

### 3. Konfigurasi environment

Buat file `.env` di root project (jangan di-commit ke Git!):

```
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
```

Atau langsung edit `lib/main.dart`:
```dart
await Supabase.initialize(
  url: 'https://xxxx.supabase.co',
  anonKey: 'eyJhbGci...',
);
```

### 4. Aktifkan platform desktop (opsional)

```bash
# Windows
flutter config --enable-windows-desktop

# macOS
flutter config --enable-macos-desktop

# Linux
flutter config --enable-linux-desktop
```

### 5. Jalankan app

```bash
# Mobile (Android/iOS)
flutter run

# Windows
flutter run -d windows

# macOS
flutter run -d macos
```

---

## Struktur Folder

```
lib/
├── main.dart
├── core/
│   ├── auth/           # AuthRepository
│   ├── notifications/  # NotificationService
│   ├── router/         # GoRouter + auth guard
│   ├── supabase/       # SupabaseClient provider
│   └── theme/          # Light & dark theme
├── features/
│   ├── auth/
│   │   └── screens/    # LoginScreen, RegisterScreen
│   ├── good_habit/
│   │   ├── repositories/   # GoodHabitRepository (CRUD, streak)
│   │   ├── providers/      # Riverpod providers
│   │   ├── screens/        # HomeScreen tab, AddGoodHabitScreen
│   │   └── widgets/        # HabitCard, CheckInButton
│   ├── bad_habit/
│   │   ├── repositories/   # BadHabitRepository (timer, relapse)
│   │   ├── providers/      # Riverpod providers
│   │   ├── screens/        # BadHabitCard, BadHabitDetailScreen
│   │   └── widgets/        # TimerWidget, RelapseButton
│   ├── home/
│   │   └── screens/        # HomeScreen (gabungan good + bad)
│   └── stats/
│       └── screens/        # StatsScreen (heatmap, grafik)
└── shared/
    ├── models/         # HabitModel, HabitLog, BadHabitSession, Relapse
    ├── screens/        # MainShell (bottom nav)
    └── widgets/        # komponen reusable
```

---

## Fitur

### Good Habit
- [x] Tambah / edit / hapus habit
- [x] Check-in harian + undo
- [x] Streak harian otomatis
- [x] Streak terpanjang
- [x] Reminder notifikasi per habit
- [x] Pengelompokan (habit groups)
- [x] Pause habit tanpa hapus histori

### Bad Habit
- [x] Timer real-time sejak mulai berhenti
- [x] Tombol relapse + konfirmasi dialog
- [x] Histori relapse tersimpan (tidak dihapus)
- [x] Rekor terlama (best record)
- [x] Milestone: 1 / 3 / 7 / 14 / 30 / 90 / 180 / 365 hari
- [x] Notifikasi selamat saat milestone tercapai

### Umum
- [x] Auth (email/password + Google OAuth)
- [x] Dark mode otomatis
- [x] Sync real-time antar device (Supabase Realtime)
- [x] Data terisolasi per user (Row Level Security)

---

## Catatan Keamanan

- Jangan commit `.env` atau API key ke Git
- RLS (Row Level Security) sudah aktif di semua tabel
- `anon key` Supabase aman digunakan di client karena RLS membatasi akses
