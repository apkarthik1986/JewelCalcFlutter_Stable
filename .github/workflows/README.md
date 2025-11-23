# GitHub Actions Workflows

## Available Workflows

### Build Flutter APK

**File**: `build-apk.yml`

**Purpose**: Automatically builds Android APK file whenever code is pushed or on manual trigger.

**Triggers**:
- Push to `main` or `master` branch
- Pull requests to `main` or `master` branch
- Manual trigger via "Run workflow" button

**Steps**:
1. Checks out code
2. Sets up Java 17
3. Sets up Flutter 3.24.3
4. Gets Flutter dependencies
5. Runs Flutter tests
6. Builds release APK
7. Uploads APK as artifact (retained for 90 days)

**Artifacts**:
- `app-release`: Generic release APK (30-day retention)
- `myflutter-release-apk`: Named release APK with commit SHA (90-day retention)

**Download APK**:
1. Go to Actions tab
2. Click on successful workflow run
3. Scroll to Artifacts section
4. Download the artifact

**Customize**:
- Change Flutter version in `flutter-version` field
- Adjust retention days in `retention-days` field
- Add additional build steps as needed

---

## Manual Workflow Trigger

To manually trigger a build:

1. Go to **Actions** tab in GitHub
2. Click on **Build Flutter APK** workflow
3. Click **Run workflow** button
4. Select branch (default: main)
5. Click **Run workflow**

---

## Workflow Status

View workflow status:
- **Green checkmark ✓**: Build successful
- **Red X ✗**: Build failed (click to see logs)
- **Yellow dot ●**: Build in progress

---

## Adding More Workflows

You can add additional workflows for:
- Automated testing on multiple devices
- Publishing to Google Play Store
- Creating GitHub releases with APK
- Running code analysis and linting
- Building for iOS (requires macOS runner)

Example workflow files can be found in [Flutter documentation](https://flutter.dev/docs/deployment/cd).
