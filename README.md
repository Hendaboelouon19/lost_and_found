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
