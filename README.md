# Ecosystem Viewer (Flutter Web)

An interactive, responsive 3D and 2D ecosystem and panorama explorer built with **Flutter Web**, replicating a React-based architecture. This application allows users to seamlessly navigate through various global biomes, view 3D `.glb` models, and inspect real-time climate and biodiversity metrics.

---

## Features

- **3D & 2D Biome Navigation:** Switch between immersive environments like Jungle Forests, Ocean Floors, Cloud Forests, and Seagrass Meadows.
- **Interactive 3D Model Rendering:** Powered by `model_viewer_plus` with built-in rotation, zoom, and camera controls.
- **Dynamic Background Gradients:** Smooth, animated color transitions matching the active ecosystem's atmospheric theme.
- **Real-Time Biome Metrics:** Live integration via Dio to fetch weather, solar data (sunrise/sunset), and wildlife tracking data.
- **Cross-Platform Web Ready:** Fully optimized for modern web browsers with responsive overlay controls.

---

## Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (v3.0+)
- **Language:** [Dart](https://dart.dev)
- **3D Rendering:** `model_viewer_plus` (Google Model Viewer wrapper)
- **Networking:** `dio` for HTTP API requests
- **Icons:** `font_awesome_flutter`

---

## Project Structure

```text
animation-panoramas-website/
├── assets/
│   └── models/          # .glb 3D asset files (jungle-forest.glb, ocean-floor.glb, etc.)
├── lib/
│   ├── data/
│   │   └── ecosystems.dart  # Biome definitions and metadata
│   ├── models/
│   │   └── ecosystem.dart   # Core data models and background schemas
│   ├── services/
│   │   └── api_service.dart # Dio-powered API client for live metrics
│   └── main.dart            # Main app entry point and UI layout
├── web/
│   └── index.html       # Web host template containing model-viewer scripts
├── pubspec.yaml         # Project dependencies and asset declarations
└── README.md
```