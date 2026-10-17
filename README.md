# Lockroom

Lockroom is an iOS app for the native Camera-close workflow:

1. Take a photo from the iPhone Lock Screen Camera.
2. Close Camera or lock the phone.
3. A Shortcuts automation runs the Lockroom `Develop Latest Photo` app intent.
4. Lockroom sends the newest photo through a development pipeline and returns a rich notification with the finished image.

The app uses GPT Image 2 to produce a polished version of the latest camera capture. App Store distribution should proxy OpenAI requests through a backend so API keys never ship inside the mobile client.

## Build

```bash
ruby scripts/generate_xcode_project.rb
xcodebuild -project Lockroom.xcodeproj -scheme Lockroom -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

## Local GPT testing

For simulator-only testing, either:

- Open Lockroom settings, paste the key, and tap `Save Key`.
- Or launch with a temporary environment variable:

```bash
export OPENAI_API_KEY="sk-..."
xcrun simctl launch --env OPENAI_API_KEY="$OPENAI_API_KEY" booted com.jarvis.lockroom
```

The app checks Keychain first. In Debug builds only, it falls back to `OPENAI_API_KEY` when no Keychain key exists.
