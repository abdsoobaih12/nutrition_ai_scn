# Smart Ingredient Scanner (nutrition_ai_scn)

An AI-powered Flutter mobile app that scans food ingredient labels and instantly returns a clear health analysis and a simple 1–5 health score. The app captures an ingredient list photo, sends it to a Node.js proxy, uses Gemini AI to perform OCR + nutrition analysis, then displays the result in a modern dark UI and saves it to local history (Hive).

---

## ✨ Key Features

- 📷 **Ingredient Label Scanning** (in-app camera)
- 🧠 **Gemini AI OCR + Nutrition Analysis**
- ⭐ **Health Score (1–5)** with easy-to-understand rating
- 📝 **Markdown-formatted analysis** (Benefits / Risks / Tips)
- 🗂 **History** saved locally using **Hive**
- 🌙 **Modern Dark AI-style UI**

---

## 🎯 Project Goals

- Help users quickly understand the health impact of food products
- Provide instant AI-based ingredient analysis using **Gemini**
- Offer a simplified score for fast decisions
- Keep a searchable and reviewable scan history

---

## 🧩 How It Works (Workflow)

1. User opens the camera screen  
2. User captures an ingredient label photo  
3. App converts image → **Base64**  
4. Flutter sends Base64 → **Node.js Proxy Server**  
5. Proxy sends request to **Gemini** with a structured prompt  
6. Gemini performs **OCR + analysis**  
7. Gemini returns structured **JSON**  
8. Flutter displays analysis + health score  
9. App saves the result to **Hive** (History)

---

## 🏗 System Architecture

### Frontend (Flutter / Dart)
- Flutter SDK (Dart)
- Camera plugin
- HTTP requests
- Hive local database
- Markdown rendering
- Modern dark UI

### Backend (Node.js Proxy Server)
- Express server
- Gemini AI API
- `dotenv` for protecting the API key
- Receives Base64 image, forwards prompt + image to Gemini, returns JSON

---

## ⭐ Health Score Scale

| Score | Meaning |
|------:|---------|
| 1 | Very Unhealthy |
| 2 | Unhealthy |
| 3 | Average |
| 4 | Good |
| 5 | Excellent |

> You can change the labels and scoring logic easily.

---

## 🧠 Prompt Engineering

The proxy server uses a structured prompt to force Gemini to return valid JSON:

```txt
You are an AI nutrition expert. Perform OCR on this image.
Extract ingredient names clearly. Then analyze each ingredient for:
- benefits
- risks
- health impact

Return your result in EXACT JSON format:
{
  "healthScore": number from 1 to 5,
  "analysisText": "Markdown sections with ## headings"
}
````

Expected JSON response:

```json
{
  "healthScore": 4,
  "analysisText": "## Benefits\n...\n\n## Risks\n...\n\n## Tips\n..."
}
```

---

## 🗃 Local Database (Hive Model)

**AnalysisResult**

* `id` (String)
* `timestamp` (DateTime)
* `imagePath` (String)
* `healthScore` (int)
* `analysisText` (String)

---

## 📂 Project Structure (Typical)

```txt
nutrition_ai_scn/
├─ lib/
│  ├─ screens/
│  ├─ models/
│  ├─ services/
│  └─ main.dart
├─ android/
├─ ios/
├─ web/
├─ windows/
├─ linux/
├─ macos/
├─ test/
├─ proxyServer.js
├─ package.json
├─ .env.example
├─ pubspec.yaml
└─ README.md
```

---

## 🚀 Getting Started (Run Locally)

### 1) Requirements

* Flutter SDK installed
* Android Studio / Android SDK (or iOS toolchain on macOS)
* Node.js installed (for proxy server)

### 2) Install Flutter dependencies

```bash
flutter pub get
```

### 3) Setup the Node.js proxy server

Install Node packages:

```bash
npm install
```

Create `.env` file (DO NOT commit it) by copying the example:

```bash
copy .env.example .env
```

### 4) Put your Gemini API key in `.env`

Open `.env` and set:

```env
GEMINI_API_KEY=YOUR_API_KEY_HERE
PORT=3000
```

### 5) Start the proxy server

```bash
node proxyServer.js
```

(or if you have a start script)

```bash
npm start
```

### 6) Run the Flutter app

In a new terminal:

```bash
flutter run
```

---

## 🔧 Configuration Notes

### Proxy Server URL

Make sure your Flutter app points to the correct proxy URL:

* If running locally on your PC and testing on emulator:
  `http://10.0.2.2:3000` (Android Emulator)
* If testing on real phone on same Wi-Fi:
  use your PC local IP, e.g. `http://192.168.1.10:3000`

> If you want, I can help you set the best URL based on your setup (emulator vs real device).

---

## 🔒 Security (Important)

✅ Keep these files out of GitHub:

* `.env` (contains API key)
* `build/`, `.dart_tool/`, `node_modules/`, `.idea/`

Create an example file to share variable names safely:

### `.env.example`

```env
GEMINI_API_KEY=YOUR_API_KEY_HERE
PORT=3000
```

> Make sure `.env` is listed in `.gitignore`.

---

## 🧯 Troubleshooting

### 1) `Permission denied` / cannot connect to server

* Confirm proxy server is running
* Check correct URL:

  * emulator: `10.0.2.2`
  * phone: your PC IP
* Allow firewall access for Node.js if prompted

### 2) Gemini returns invalid JSON

* Tighten the prompt
* Add a “return only JSON” instruction
* Add server-side JSON validation + retry (optional improvement)

### 3) Camera issues on Android

* Ensure camera permissions in `AndroidManifest.xml`
* Run `flutter clean` then `flutter pub get`

---

## 🧭 Future Improvements

* 📦 Barcode scanning
* 🔁 Product comparison
* ☁ Cloud sync + user accounts
* ❤️ Favorite products list
* 📊 Weekly nutrition reports
* 📴 Offline OCR (on-device)

---

## ✅ Conclusion

Smart Ingredient Scanner makes ingredient understanding fast and accessible. It combines Flutter’s camera scanning experience with Gemini AI’s OCR + analysis to deliver instant, user-friendly health insights and a clean scoring system—while keeping history locally for convenience.

---

