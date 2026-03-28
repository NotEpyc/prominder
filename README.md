<p align="center">
  <img src="assets/icons/app-icon.png" alt="Prominder Logo" width="120" style="border-radius: 50px;" />
</p>

<h1 align="center">Prominder – AI-Driven Productivity & Focus Platform</h1>

A Flutter-based mobile application powered by an AI backend, helping students and professionals manage their schedules, study materials, and productivity through an intelligent chatbot, timetable planner, and flashcard system.

---

## 🌟 Project Overview

**Prominder** is a cross-platform productivity app designed for students who want a smarter way to stay organized. It features an **AI-powered chatbot**, an intelligent **timetable planner** (with OCR support), a **flashcard study system**, and a minimal **Wear OS** companion interface — all wrapped in a premium **neumorphic UI**.

---

## 🎯 Mission & Vision

- **Mission**: To simplify academic planning and study sessions through intelligent automation.
- **Vision**: To be the go-to AI productivity companion for every student.
- **Target Audience**: University students, self-learners, and academic professionals.
- **Design Philosophy**: Neumorphic aesthetics with a focus on calm, distraction-free productivity.

---

## 📱 Mobile App (Flutter)

- **Framework**: Flutter 3.x using Dart
- **UX/UI**: Neumorphic design system with custom themes, parallax backgrounds, and smooth animations
- **Key Screens**:
  - 🏠 Landing / Onboarding
  - 🔐 Login & Registration
  - 🏡 Home Dashboard
  - 🤖 AI Chatbot (with OCR, voice input, image/file upload)
  - 📅 Timetable Planner (AI-generated from images/documents)
  - 🃏 Flashcards Study System (flip card + swipeable deck)
  - 👤 Profile Management
  - ⚙️ Settings

---

## 🤖 AI Features

- **AI Chatbot**: Conversational assistant with context memory, markdown rendering, and multimodal input (text, voice, images, documents)
- **OCR Timetable Parsing**: Upload a photo or document and the AI extracts and structures your timetable
- **Flashcard Generation**: AI-assisted note generation for study sessions
- **Speech-to-Text**: Voice input for hands-free chatbot interaction

---

## ⚙️ Architecture

### Frontend (Flutter)

```
lib/
├── main.dart                   # App entry, responsive screen layer
├── core/
│   ├── services/               # Auth, Chatbot, Timetable, Notes API services
│   └── theme/                  # App-wide neumorphic theme
├── screens/
│   ├── mobile/                 # All mobile screens (home, chat, timetable, flashcards, etc.)
│   └── wearos/                 # Wear OS companion screen
└── widgets/                    # Reusable components (neumorphic buttons, text fields, navbar, etc.)
```

### Backend (API)

- REST API consumed via the `http` package
- Auth tokens stored with `shared_preferences`
- Environment variables managed via `flutter_dotenv`

---

## 📦 Tech Stack Summary

| Layer           | Technology |
|-----------------|------------|
| **Framework**   | Flutter 3.x (Dart) |
| **UI Style**    | Neumorphic Design System |
| **Fonts**       | Google Fonts |
| **AI Chat**     | Custom AI backend + REST API |
| **OCR**         | AI-powered document/image parsing |
| **Voice Input** | `speech_to_text` |
| **Storage**     | `shared_preferences`, `path_provider` |
| **Markdown**    | `flutter_markdown`, `markdown_widget` |
| **Animations**  | `flip_card`, `flutter_card_swiper`, `custom_refresh_indicator` |
| **Wear OS**     | Responsive screen layer via `MediaQuery` |

---

## 🧩 Key Widgets & Components

- `NeumorphicButton` – Tactile, embossed buttons following the app theme
- `NeumorphicTextField` – Styled inputs with consistent depth effects
- `NeumorphicAlert` – Custom in-app alert dialogs (no snackbars)
- `FloatingBottomNavbar` – Custom animated bottom navigation bar
- `ParallaxBackground` – Dynamic scrolling background for depth
- `FadeIndexedStack` – Smooth fade transitions between nav screens
- `GlobalLoader` – Centralized loading indicator

---

## 🗂️ Assets Structure

```
assets/
├── icons/       # App icon + UI element icons (camera, home, chatbot, etc.)
├── images/
│   └── home/    # Home screen visuals
└── videos/      # Onboarding or background video assets
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.4.0 <4.0.0`
- Dart SDK compatible with the above
- A running backend API instance

### Setup

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

---

## 📸 Screenshots

<p float="left">
  <img src="assets/screenshots/ss.png" width="100%" />
</p>

---

## 🙌 Final Note

**Prominder** combines the power of AI with a beautifully crafted, neumorphic mobile experience to redefine how students interact with their study life. From parsing a timetable photo to flipping through AI-generated flashcards — Prominder is not just a planner, it's a smart academic companion.
