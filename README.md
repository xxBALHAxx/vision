# Vision Quest

This repository contains the Vision Quest website and the Android APK download page for deployment on Vercel.

## Project structure

- `front/` – static landing page and APK asset for the web deployment
- `vision_quest/` – Flutter app source for the Android app

## Vercel deployment

1. Push this repository to GitHub.
2. Import the repo in Vercel.
3. Set the Vercel root directory to `front`.
4. Deploy.

The site includes a downloadable APK at `front/apk/vision-quest.apk`.

## Local preview

Open the `front` folder in a browser or run a static server from it:

```bash
cd front
python -m http.server 8000
```

Then visit `http://localhost:8000`.
