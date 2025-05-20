# 🐢 TaskQuest

TaskQuest is a gamified task management mobile app built with **Flutter** and powered by **Firebase**. Users can create, edit, and track tasks by priority, earn points for completing tasks, and earn / unlock their avatars. It also includes a built-in assistant that helps break down tasks using OpenAI.

---

## ✨ Features

- 🔐 **Authentication**: Email/password sign-up and login using Firebase Auth
- 📋 **Task Management**:
    - Add/edit/delete tasks
    - Prioritize tasks by High, Medium, Low
    - Add due dates, times, and notes
    - View completed tasks
- 🎮 **Gamification**:
    - Earn points for completing tasks
    - Unlock avatars with points
- 📅 **Calendar View**: See tasks by date
- 💬 **Task Assistant**: Ask a chatbot to help break down tasks using OpenAI API
- 🌗 **Theming**: Light and dark theme toggle
- 📊 **Leaderboard**: See top-performing users

---

## 🛠️ Tech Stack

### 🔧 Frontend
- **Flutter** (Dart)
- `table_calendar` for calendar interface
- `intl` for date formatting
- `flutter_local_notifications` *(planned)*

### ☁️ Backend
- **Firebase Authentication** for user login/signup
- **Firebase Firestore** for task storage per user
- **OpenAI API** for assistant integration (via `http`)

### 🔐 Environment
- `flutter_dotenv` for secure API key management

---

## 🚀 Getting Started

### ✅ Prerequisites
- Flutter SDK 3.6+
- Android Studio
- Firebase project setup
- OpenAI API key

---

### 🧩 Dependencies

Install all required packages:

```bash
flutter pub get
```
### 📁 File Set Up

Create a .env file in your root directory 

```bash
.env
```
Paste the generate OpenAI api key 
```bash
OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
Ensure you dont leak your secret key by adding .env to your .gitignore.

### ⚙️ Firebase Setup

Make sure you’ve done the following:

- Enable Email/Password authentication in the Firebase console

- Add your Firebase files:

- google-services.json → android/app/

- GoogleService-Info.plist → ios/Runner/

- Confirm Firebase initialization in main.dart using:

 ```bash 
await Firebase.initializeApp();
```
▶️ Run the App

 ```bash 
flutter run
```
Run this command in your terminal 

### 🐛 Troubleshooting

- “.env file not found” → Make sure it’s declared under flutter/assets: in pubspec.yaml

- OpenAI 429 Error → You’ve likely exceeded your quota. Contact @Camillaecalle for more OPenAI funds. 

- Firestore permission denied → Double-check your Firebase Firestore security rules

- Build errors from notifications → Notification functionality is planned and currently disabled due to compatibility issues

### 🎖️ Testing 

Implemented testing for: 

- Authentication Services

- OpenAI Services

- Task Repository (Task Saving per user)

### 🧠 Future Improvements

- 📲 Push notifications for task reminders

- 📅 Calendar syncing

- 🔐 Social authentication (Ex: Google Sign-In)

- 📊 Analytics dashboard for task history

- 👥 Friends & team progress sharing

### 👩‍💻 Author

[Camilla Calle](https://github.com/Camillaecalle)
