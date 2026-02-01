# Release Guide for Ledgerify

## Quick Release (Unsigned APK)

### Option 1: GitHub Actions (Recommended)

1. **Create a version tag:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **GitHub Actions will automatically:**
   - Build Android APK and AAB
   - Build iOS (unsigned)
   - Create a GitHub Release with all artifacts

3. **Download from Releases page**

### Option 2: Manual Build

```bash
# Build release APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Output locations:
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
```

---

## Signed Release (Play Store Ready)

### Step 1: Create a Keystore (One-time)

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload

# Answer the prompts:
# - Keystore password
# - Key password  
# - Your name, organization, etc.
```

**IMPORTANT:** Store the keystore and passwords securely! You'll need them for all future updates.

### Step 2: Local Signed Build

1. **Create `android/key.properties`** (DO NOT COMMIT):
   ```properties
   storePassword=your_keystore_password
   keyPassword=your_key_password
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```

2. **Place keystore file** in `android/` directory

3. **Build:**
   ```bash
   flutter build apk --release
   flutter build appbundle --release
   ```

### Step 3: GitHub Actions Signed Build

1. **Encode keystore to base64:**
   ```bash
   base64 -i upload-keystore.jks | pbcopy  # macOS
   base64 upload-keystore.jks | xclip      # Linux
   ```

2. **Add GitHub Secrets** (Settings → Secrets → Actions):
   | Secret Name | Value |
   |-------------|-------|
   | `KEYSTORE_BASE64` | Base64 encoded keystore |
   | `KEYSTORE_PASSWORD` | Keystore password |
   | `KEY_ALIAS` | `upload` (or your alias) |
   | `KEY_PASSWORD` | Key password |

3. **Run workflow:**
   - Go to Actions → "Build Signed Release"
   - Click "Run workflow"
   - Enter version number

---

## iOS Release

### Requirements
- macOS with Xcode installed
- Apple Developer Account ($99/year)
- Valid provisioning profile and certificates

### Build Unsigned (for testing)
```bash
flutter build ios --release --no-codesign
```

### Build for App Store
1. Open `ios/Runner.xcworkspace` in Xcode
2. Configure signing in Xcode (Team, Bundle ID)
3. Product → Archive
4. Distribute via App Store Connect

---

## Version Management

### Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1
#        │     │
#        │     └── Build number (increment for each build)
#        └── Version name (semantic versioning)
```

### Tagging convention:
```bash
# Release version
git tag v1.0.0
git push origin v1.0.0

# Pre-release
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1
```

---

## Checklist Before Release

- [ ] Update version in `pubspec.yaml`
- [ ] Run `flutter analyze` - no errors
- [ ] Run `flutter test` - all tests pass
- [ ] Test on physical device
- [ ] Update README if needed
- [ ] Update CHANGELOG.md
- [ ] Create git tag
- [ ] Verify GitHub Actions build succeeds

---

## Files to NEVER Commit

| File | Contains |
|------|----------|
| `*.jks`, `*.keystore` | Signing keys |
| `key.properties` | Keystore passwords |
| `google-services.json` | Firebase config |
| `*.p12`, `*.mobileprovision` | iOS certificates |
| `.env` | Environment variables |

These are already in `.gitignore`.

---

## Troubleshooting

### Build fails with signing error
- Ensure `key.properties` exists and has correct paths
- Verify keystore file location
- Check passwords are correct

### APK size too large
- Enable minification (already configured)
- Run `flutter build apk --analyze-size`
- Consider splitting APK by ABI:
  ```bash
  flutter build apk --split-per-abi
  ```

### iOS build fails
- Run `cd ios && pod install`
- Clean build: `flutter clean && flutter pub get`
- Check Xcode signing settings
