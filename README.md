# RapidWrite Studio — High-Frequency Stylus Handwriting Evaluator

RapidWrite is a tablet-optimized calligraphy, kinematics, and handwriting speed assessment platform built for Android tablets, iPads (Apple Pencil), and laptops.

---

## 🌐 24/7 Live Deployment on GitHub Pages

This repository is pre-configured for **GitHub Pages** with an automated GitHub Action.

### To Enable Live 24/7 Streaming:
1. Push this repository to GitHub.
2. In your repository on GitHub, go to **Settings** > **Pages**.
3. Under **Build and deployment**:
   - Source: **GitHub Actions** (or select **Deploy from a branch** -> `main` / `root`).
4. Your permanent 24/7 live web link will be:
   ```
   https://<your-github-username>.github.io/<your-repo-name>/
   ```
5. Anyone on an Android Tablet, iPad, iPhone, or laptop can open this link from anywhere in the world on any network (Wi-Fi, 4G/5G, Hotspot) with zero setup required.

---

## ✨ Features & Architecture

### 1. 4-Metric Evaluation Dashboard
- **⚡ WPM (Words Per Minute)**: Grounded motor speed calculation (`WPM = (CPM) / 5.0`).
- **⏱ DURATION (Temporal Gating)**: Highlights total motor delta $T_{\text{last stroke}} - T_{\text{first stroke}}$, with live breakdown of **Contact Time** ($\sum \Delta t_{\text{contact}}$) and **In-Air Pause Time** ($\sum \Delta t_{\text{hover}}$).
- **✔ ACCURACY**: Character-level Levenshtein matching against target prompt.
- **📈 AESTHETIC**: Calligraphy curvature, baseline regularity, and rhythmic stroke score (Grade A–F).

### 2. Zero-Jitter Tablet Layout
- Complete page movement lockdown (`touch-action: none !important; position: fixed; overflow: hidden;`).
- Apple Pencil and Android S-Pen stylus inputs draw freely with palm-rejection.
- Screen fits perfectly on 100svh/100dvh without vertical scrolling or browser bouncing.

### 3. Event-Grounded Temporal Gating Model
1. **$T_0$ Arming State**: Clock stays at 00:00 when `Start` is armed.
2. **$T_{\text{first stroke}}$**: Timer activates on the millisecond of first stylus pen-down.
3. **$\sum \Delta t_{\text{contact}}$**: Active contact time on glass.
4. **$\sum \Delta t_{\text{hover}}$**: In-air pause intervals between words.
5. **$T_{\text{last stroke}}$**: Final stroke completion timestamp.

### 4. Target Prompt Disappearance
- When the allocated practice time ends, the target sentence completely vanishes from view, challenging the student to continue from motor recall.

---

## 💻 Local Testing Environment

To run locally on your laptop:
- Double-click `START_TESTING_ENVIRONMENT.bat` to launch the local server at `http://localhost:8080/`.
- Double-click `START_CLOUDFLARE_TUNNEL.bat` to launch a temporary worldwide tunnel.
