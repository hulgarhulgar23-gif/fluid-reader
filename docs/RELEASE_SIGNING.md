# Release Signing and Notarization

How to ship Fluid Reader releases that open without Gatekeeper warnings,
like commercial apps (Raycast, etc).

## What unsigned users see

Without Developer ID signing, downloaded builds show "Fluid Reader can't be
opened because it is from an unidentified developer." Users must right-click
the app and choose Open the first time. The app still works; it just looks
less official.

## One-time setup

1. Enroll in the [Apple Developer Program](https://developer.apple.com/programs/)
   (USD 99/year, personal or organization).
2. In Xcode (Settings → Accounts → Manage Certificates) or at
   developer.apple.com, create a **Developer ID Application** certificate and
   install it in your login keychain.
3. Find your identity string:

   ```sh
   security find-identity -v -p codesigning
   ```

   It looks like `Developer ID Application: Your Name (TEAMID1234)`.
4. Store notary credentials once (uses an app-specific password from
   appleid.apple.com):

   ```sh
   xcrun notarytool store-credentials fluid-reader-notary \
     --apple-id "you@example.com" --team-id TEAMID1234
   ```

## Per-release flow

```sh
FLUID_READER_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID1234)" \
  zsh scripts/build_app.sh
zsh scripts/notarize_app.sh
zsh scripts/verify_release.sh
```

`build_app.sh` signs with the hardened runtime and a secure timestamp when a
real identity is given (both are notarization requirements). `notarize_app.sh`
submits the app to Apple, waits for the verdict, staples the ticket, and
rewrites `.build/FluidReader.zip` with the notarized bundle.

Upload that zip to the GitHub release. Update the Homebrew cask `sha256`
afterwards.

## Defaults stay free

Without `FLUID_READER_SIGN_IDENTITY`, builds are ad-hoc signed and everything
else (CI, tests, packaging) works the same. Signing is only needed for
distribution polish, never for development.

## Secrets policy

Never commit identities, team IDs, Apple IDs, or app-specific passwords.
Credentials live only in your keychain via `notarytool store-credentials`.
