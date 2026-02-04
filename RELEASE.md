# Release Guide for Ledgerify

## Quick Release (GitHub Release with APK/AAB)

### Option 1: GitHub Actions (Recommended)

1. **Go to Actions tab** on GitHub
2. **Select "Release (APK/AAB)"** workflow
3. **Click "Run workflow"**
4. **Enter version (semver)** (e.g., `1.3.2`) — must match `pubspec.yaml`'s semver
5. **(First time only)** Add Android signing secrets (see “Signed Release” below)
   - Optional: protect releases via GitHub **Environments** by adding required reviewers to the `release` environment
6. The workflow creates a **GitHub Release** (tagged `vX.Y.Z`) and uploads the APK/AAB assets automatically

Release assets will include:
- `ledgerify-vX.Y.Z.apk` - Android APK
- `ledgerify-vX.Y.Z.aab` - Android App Bundle (for Play Store)
- `ledgerify-vX.Y.Z-sha256sums.txt` - Checksums

### Option 2: Local Build

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
   - Go to Actions → "Release (APK/AAB)"
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

---

## Checklist Before Release

- [ ] Update version in `pubspec.yaml`
- [ ] Run `flutter analyze` - no errors
- [ ] Run `flutter test` - all tests pass
- [ ] Test on physical device
- [ ] Update README if needed
- [ ] Run "Build Release" workflow on GitHub Actions
- [ ] Create GitHub Release and upload artifacts

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
