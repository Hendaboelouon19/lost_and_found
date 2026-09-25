# Lost & Found

A Flutter application for reporting and discovering lost and found items.

Users can report an item as lost or found and provide information such as its location, time, category, and description. The project is structured so matching, image comparison, maps, notifications, and other services can be added later.

The current version focuses mainly on Flutter architecture, API integration, and state management rather than UI.

## Current Features

- Login
- Sign up
- Home
- Add lost/found item
- Item details
- User profile

## Architecture

The project uses a feature-based structure with separate data and presentation layers.

```text
lib/
├── core/
│   ├── di/
│   ├── networking/
│   │   └── interceptors/
│   ├── routes/
│   └── utils/
│
├── features/
│   ├── auth/
│   │   ├── login/
│   │   └── register/
│   ├── home/
│   ├── add_item/
│   ├── item_details/
│   └── profile/
│
└── main.dart
```

## Real map setup

The app uses Google Maps and device location for the lost and found map.

1. Create a Google Cloud project and enable **Maps SDK for Android**, **Maps SDK for iOS**, and billing.
2. Add an Android key through the environment when running or building:

```powershell
$env:GOOGLE_MAPS_API_KEY = "your_key"
flutter run
```

The same environment variable is used when building Android:

```powershell
$env:GOOGLE_MAPS_API_KEY = "your_key"
flutter build apk
```

The Android manifest reads `GOOGLE_MAPS_API_KEY`. For iOS, replace
`YOUR_GOOGLE_MAPS_API_KEY` in `ios/Runner/AppDelegate.swift` with the iOS-restricted key.
Restrict keys by package identifier, iOS bundle identifier, and the APIs they use.

The report form opens a real Egypt-centered map. Users can tap any point, use the device
location button, and save the selected latitude and longitude with the report. Location
permissions are requested only when the map is opened.
