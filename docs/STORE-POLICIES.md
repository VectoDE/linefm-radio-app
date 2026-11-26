# Store policies: checklist for LINEFM Radio

German version: [STORE-RICHTLINIEN.md](STORE-RICHTLINIEN.md). Both files carry the same content.

This list is for the client and the operator. It works as a template for every submission and as a re-check list before each release. Every point summarises an official policy in our own words. It does not replace the policy text: before a submission, open the linked source and read the current wording. Short quotes stay under 15 words.

**How to read an entry**

- `[x]` means the point is met today, `[ ]` means something is still to do.
- **Status:** `OK` (met and checked in the repository), `open` (work in the repository is still missing) or `owner` (the client or the operator decides or acts in a store console).
- **Where:** the place where the point is handled: a path in this repository, a field in a store console or a page on the website.
- **Source:** link to the official page and the date it was retrieved. "not verified" means the page was not read in full on that date (for example because it only renders with JavaScript). Read it before relying on the entry.

**Decisions already taken (2026-11-26)**

- Age rating 13+ in every store, target audience 13+, OARS `language-profanity` moderate. No children's audience.
- Telemetry in store builds: Sentry, Firebase and Umami, each only after consent. All privacy forms declare these three as optional data collection.
- The self-updater ships only in the direct downloads (Windows setup, macOS DMG). A build flag removes it from every store build and a CI check enforces this.
- Flathub gets an offline build from source, no prebuilt archive.
- iOS alarm: AlarmKit on iOS 26 and later, notification fallback below that, with a clear hint in the app and in the store text.
- The Mac App Store submission goes out together with iOS. Export uses a save dialog instead of the downloads entitlement.
- License page: `/lizenz/` (German and English) on the web app.
- `USE_FULL_SCREEN_INTENT` is a secondary feature: declared in the Play Console, requested at runtime, with a notification fallback.
- Every store uses the client's own organisation account.
- Apple (iOS and Mac App Store) is not part of the first release; both follow later, together.
- Support contact in every store: support@linefm.de and a `/support/` page (German and English) on the web app.
- The updater signing key is the secret `UPDATER_ED25519_PRIVATE_KEY` in the environment `release`.
- The client holds the agreement with laut.fm and keeps it. Where a store asks for content rights, the entry below says so.
- The client places the Flathub domain verification file at go-live.

<a id="aktualitaet"></a>**Freshness:** the workflow `.github/workflows/store-policy-watch.yml` checks every linked page once a month (reachable, text changed) and opens one ticket when something changed. After reviewing a change, refresh the baseline with `python3 tool/check_store_policy_links.py --update-baseline` and update the affected entries and dates here.

---

## Google Play

Sources (all retrieved 2026-11-26):

- Developer Program Policy centre: <https://play.google/developer-content-policy/>
- Data safety: <https://support.google.com/googleplay/android-developer/answer/10787469>
- User data: <https://support.google.com/googleplay/android-developer/answer/10144311>
- Permissions and sensitive APIs (incl. exact alarm): <https://support.google.com/googleplay/android-developer/answer/9888170>
- Foreground service and full-screen intent: <https://support.google.com/googleplay/android-developer/answer/13392821>
- Foreground service types: <https://developer.android.com/develop/background-work/services/fgs/service-types>
- Target API level: <https://developer.android.com/google/play/requirements/target-sdk>
- Target audience and app content: <https://support.google.com/googleplay/android-developer/answer/9867159>
- Content ratings (IARC): <https://support.google.com/googleplay/android-developer/answer/9898843>
- Metadata: <https://support.google.com/googleplay/android-developer/answer/9898842>
- Car app quality: <https://developer.android.com/docs/quality-guidelines/car-app-quality>
- 16 KB page sizes: <https://developer.android.com/guide/practices/page-sizes>
- Play App Signing: <https://support.google.com/googleplay/android-developer/answer/9842756>

### Developer Program Policies (one entry per section of the policy centre)

- [x] <a id="g-01"></a>**G-01 Restricted content.** No sexual content, hate, violence, illegal goods or gambling in the app itself. Streams are radio programmes; the rating covers occasional explicit lyrics. Status: OK. Where: content of the station list `assets/config/`, rating in the Play Console. Source: [Policy centre](https://play.google/developer-content-policy/), 2026-11-26.
- [x] <a id="g-02"></a>**G-02 Impersonation.** The app must not pretend to be another brand or claim an official link it does not have. Store texts name "LineFM is an offer of RadioGruppe Deutschland on behalf of the LINEFM group" and call Radio3FM and FobFM partner stations. Status: OK. Where: `docs/STORE-TEXTE.md`. Source: [Policy centre](https://play.google/developer-content-policy/), 2026-11-26.
- [ ] <a id="g-03"></a>**G-03 Intellectual property.** Streams, station names and logos need the right to use them. The client holds the laut.fm agreement; keep it ready if Google asks. Status: owner. Where: client's records, Play Console > App content (if asked). Source: [Policy centre](https://play.google/developer-content-policy/), 2026-11-26.
- [ ] <a id="g-04"></a>**G-04 Privacy, deception and device abuse.** Collect only what is disclosed, ask before collecting, no hidden behaviour. Telemetry starts only after consent. The privacy policy still contains placeholders. Status: open. Where: `lib/features/consent/`, `web/datenschutz/index.html`, `docs/STORE-DATENSCHUTZANGABEN.md`. Source: [User data](https://support.google.com/googleplay/android-developer/answer/10144311), 2026-11-26.
- [x] <a id="g-05"></a>**G-05 Monetisation and ads.** No in-app purchases, no ads, no advertising ID. Status: OK. Where: `pubspec.yaml` (no billing or ads plugin), `android/app/src/main/AndroidManifest.xml` (advertising ID removed). Source: [Policy centre](https://play.google/developer-content-policy/), 2026-11-26.
- [ ] <a id="g-06"></a>**G-06 Store listing and promotion.** Title, descriptions and graphics must be accurate, no keyword stuffing, no misleading claims. Title, short and full description exist; screenshots and the feature graphic are missing. Status: open. Where: `docs/STORE-TEXTE.md`, `fastlane/metadata/android/`. Source: [Metadata](https://support.google.com/googleplay/android-developer/answer/9898842), 2026-11-26.
- [x] <a id="g-07"></a>**G-07 Spam, functionality and user experience.** The app must work, not crash, and offer more than a website wrapper. Native playback, widget, alarm, Android Auto and Chromecast are present. Status: OK. Where: `lib/`, test suite under `test/` and `integration_test/`. Source: [Policy centre](https://play.google/developer-content-policy/), 2026-11-26.
- [x] <a id="g-08"></a>**G-08 Malware and mobile unwanted software.** No hidden code download, no unexpected behaviour. The self-updater is not part of Play builds. Status: OK (CI check for the updater flag still open, see D-01). Where: build flags in `tool/bauen.sh`, `.github/workflows/store-google.yml`. Source: [Policy centre](https://play.google/developer-content-policy/), 2026-11-26.
- [x] <a id="g-09"></a>**G-09 Families.** Only apps aimed at children must follow the Families rules. LINEFM targets 13+ and does not appeal to children. Status: OK (decision taken). Where: Play Console > Target audience and content. Source: [Target audience](https://support.google.com/googleplay/android-developer/answer/9867159), 2026-11-26.
- [ ] <a id="g-10"></a>**G-10 Play Console requirements and enforcement.** Developer account with verified identity, contact details and policy compliance; violations can lead to removal. Status: owner (client's own organisation account). Where: Play Console > Account. Source: [Policy centre](https://play.google/developer-content-policy/), 2026-11-26.

### Technical and form requirements

- [x] <a id="g-11"></a>**G-11 Target API level.** New apps and updates must target Android 16 (API 36) or higher. Status: OK. Where: `android/app/build.gradle.kts` (Flutter default 36). Source: [Target API](https://developer.android.com/google/play/requirements/target-sdk), 2026-11-26.
- [ ] <a id="g-12"></a>**G-12 Data safety form.** Declare every data type collected, including optional collection after consent: crash data (Sentry), app interactions (Firebase, Umami), plus what the Cast SDK sends. Status: owner. Where: Play Console > Data safety, prepared answers in `docs/STORE-DATENSCHUTZANGABEN.md`. Source: [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469), 2026-11-26.
- [ ] <a id="g-13"></a>**G-13 Privacy policy URL.** A public, reachable privacy policy, linked in the listing and inside the app, without placeholders. Status: open (placeholders). Where: `web/datenschutz/`, `fastlane/metadata/*/privacy_url.txt`. Source: [User data](https://support.google.com/googleplay/android-developer/answer/10144311), 2026-11-26.
- [x] <a id="g-14"></a>**G-14 Foreground service type.** Playback runs as `mediaPlayback` with the matching permission. Status: OK. Where: `android/app/src/main/AndroidManifest.xml`. Source: [FGS types](https://developer.android.com/develop/background-work/services/fgs/service-types), 2026-11-26.
- [ ] <a id="g-15"></a>**G-15 Foreground service declaration.** The Play Console asks for a description and a short video of the foreground service. Status: owner (client records the video). Where: Play Console > App content > Foreground service permissions; texts in `docs/STORE-TEXTE.md`. Source: [FGS and full-screen intent](https://support.google.com/googleplay/android-developer/answer/13392821), 2026-11-26.
- [x] <a id="g-16"></a>**G-16 Exact alarms.** The alarm uses `SCHEDULE_EXACT_ALARM`, which the user grants, not `USE_EXACT_ALARM`, which is reserved for core alarm and calendar apps. Status: OK. Where: `android/app/src/main/AndroidManifest.xml`, `lib/features/alarm/`. Source: [Permissions and APIs](https://support.google.com/googleplay/android-developer/answer/9888170), 2026-11-26.
- [ ] <a id="g-17"></a>**G-17 Full-screen intent.** Only alarm-clock and calling apps get it automatically. LINEFM declares it as a secondary feature, asks at runtime and falls back to a normal notification. Status: owner (declaration in the console). Where: Play Console > App content; `lib/services/alarm/alarm_permissions.dart`. Source: [FGS and full-screen intent](https://support.google.com/googleplay/android-developer/answer/13392821), 2026-11-26.
- [x] <a id="g-18"></a>**G-18 Notification permission.** Asked at runtime on Android 13 and later; refusing it must not break playback. Status: OK (device test still open). Where: `lib/services/alarm/alarm_permissions.dart`. Source: [Permissions and APIs](https://support.google.com/googleplay/android-developer/answer/9888170), 2026-11-26.
- [ ] <a id="g-19"></a>**G-19 Content rating (IARC).** Fill in the questionnaire honestly: music streams with occasional strong language, no chat, no purchases. Target 13+ (decision taken). Status: owner. Where: Play Console > Content rating. Source: [Content ratings](https://support.google.com/googleplay/android-developer/answer/9898843), 2026-11-26.
- [ ] <a id="g-20"></a>**G-20 Target audience.** Select 13 and older only. Status: owner. Where: Play Console > Target audience and content. Source: [Target audience](https://support.google.com/googleplay/android-developer/answer/9867159), 2026-11-26.
- [ ] <a id="g-21"></a>**G-21 Android for Cars, media quality.** Browse and playback must follow the car app quality checklist (no video, safe driver interaction, working media session). Code is in place; a test on the desktop head unit is still missing. Status: open. Where: `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/xml/automotive_app_desc.xml`; Play Console > Advanced settings > Form factors. Source: [Car app quality](https://developer.android.com/docs/quality-guidelines/car-app-quality), 2026-11-26.
- [ ] <a id="g-22"></a>**G-22 16 KB page sizes.** Native libraries must work on devices with 16 KB memory pages. Flutter itself is compatible; plugin libraries are unchecked. Status: open. Where: release build, check with `zipalign -c -P 16`. Source: [16 KB page sizes](https://developer.android.com/guide/practices/page-sizes), 2026-11-26.
- [ ] <a id="g-23"></a>**G-23 Play App Signing.** Google holds the app signing key, we sign uploads with the upload key. Status: owner (activate in console). Where: Play Console > App integrity; `android/app/build.gradle.kts`, `.github/workflows/store-google.yml`. Source: [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756), 2026-11-26.
- [x] <a id="g-24"></a>**G-24 App access and account deletion.** No login, so no test account and no deletion flow are needed. Status: OK. Where: Play Console > App access ("all functionality available"). Source: [User data](https://support.google.com/googleplay/android-developer/answer/10144311), 2026-11-26.

### Account, fees, review and recurring duties

- [ ] <a id="g-25"></a>**G-25 Account type and identity.** Organisation account with D-U-N-S number, verified identity, contact email and phone, and a public developer address. Personal accounts created after 13 November 2023 need a closed test with at least 12 testers opted in for 14 days before production access; an organisation account does not. Status: owner. Where: Play Console > Account details. Source: [Testing requirements for personal accounts](https://support.google.com/googleplay/android-developer/answer/14151465), 2026-11-26; [Required account information](https://support.google.com/googleplay/android-developer/answer/13628312), 2026-11-26; [Identity verification](https://support.google.com/googleplay/android-developer/answer/10841920), 2026-11-26.
- [ ] <a id="g-26"></a>**G-26 EU trader status (Digital Services Act).** Declare whether the account is a trader; traders show address, email and phone publicly on the listing in the EU. As a company the client is a trader. Status: owner. Where: Play Console > Account details. Source: [Required account information](https://support.google.com/googleplay/android-developer/answer/13628312), 2026-11-26 (trader wording not checked in detail).
- [ ] <a id="g-27"></a>**G-27 Fee.** One-time registration fee of 25 US dollars. Status: owner. Where: account sign-up. Source: [Get started with Play Console](https://support.google.com/googleplay/android-developer/answer/6112435), 2026-11-26.
- [x] <a id="g-28"></a>**G-28 Payments profile and tax forms.** Only needed for paid apps or purchases; LINEFM sells nothing. Status: OK (no merchant account). Where: Play Console > Payments profile. Source: [Get started with Play Console](https://support.google.com/googleplay/android-developer/answer/6112435), 2026-11-26.
- [ ] <a id="g-29"></a>**G-29 Support contact.** A support email is mandatory in the listing, a website is recommended: support@linefm.de and the `/support/` page. Status: owner. Where: Play Console > Store settings > Contact details; `docs/STORE-TEXTE.md`. Source: [Metadata](https://support.google.com/googleplay/android-developer/answer/9898842), 2026-11-26.
- [ ] <a id="g-30"></a>**G-30 Review notes and app access.** State that no login is needed and describe alarm, Android Auto and Chromecast so the reviewer finds them. Status: owner. Where: Play Console > App content > App access. Source: [User data](https://support.google.com/googleplay/android-developer/answer/10144311), 2026-11-26.
- [x] <a id="g-31"></a>**G-31 Data deletion requests.** Without accounts no deletion link is required; requests about telemetry data go to the contact in the privacy policy. Status: OK. Where: `web/datenschutz/`. Source: [Account deletion](https://support.google.com/googleplay/android-developer/answer/13327111), 2026-11-26.
- [ ] <a id="g-32"></a>**G-32 Content rights evidence.** If Google raises an intellectual property or impersonation complaint, upload the laut.fm agreement and the LINEFM brand permission from the Policy status page. Status: owner (client). Where: Play Console > Policy status. Source: [Policy centre](https://play.google/developer-content-policy/), 2026-11-26.
- [ ] <a id="g-33"></a>**G-33 Responding to rejections.** Fix the cause, then resubmit or appeal from the Policy status page; repeated violations put the account at risk. Status: owner. Where: Play Console > Policy status. Source: [Policy centre](https://play.google/developer-content-policy/), 2026-11-26.
- [ ] <a id="g-34"></a>**G-34 Recurring deadlines.** The target API level rises every year (usually by 31 August); Data safety, foreground service, full-screen intent and exact alarm declarations must be confirmed again when Google asks. Status: owner (calendar entry each July). Source: [Target API](https://developer.android.com/google/play/requirements/target-sdk), 2026-11-26.

- [ ] <a id="g-35"></a>**G-35 Health apps declaration.** Every app on Google Play completes it, even without health features. Answer: no health features. Status: owner. Where: Play Console > App content. Source: [Health apps](https://support.google.com/googleplay/android-developer/answer/14738291), 2026-11-26
- [ ] <a id="g-36"></a>**G-36 Financial features declaration.** Answer: the app offers no financial features. Status: owner. Where: Play Console > App content. Source: [Financial features](https://support.google.com/googleplay/android-developer/answer/13849271), 2026-11-26
- [ ] <a id="g-37"></a>**G-37 Government apps declaration.** Answer: not a government app and not developed on behalf of a government body. Status: owner. Where: Play Console > App content. Source: [Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455), not verified
- [ ] <a id="g-38"></a>**G-38 News apps declaration.** Answer: no. Google lists media streaming apps as out of scope of the news and magazine policy, even when they carry news programmes. LINEFM is a radio streaming app and is not listed in the "News and Magazines" category. Status: owner. Where: Play Console > App content; category in Store settings. Source: [News and magazine apps](https://support.google.com/googleplay/android-developer/answer/10523915), 2026-11-26
- [ ] <a id="g-39"></a>**G-39 Ads declaration.** Answer: no ads. The app integrates no ad SDK; ad breaks inside third-party streams come from the stations. Google may still set the "Contains ads" label itself after its own review. Status: owner. Where: Play Console > App content > Ads. Source: [Prepare your app for review](https://support.google.com/googleplay/android-developer/answer/9859455), 2026-11-26
- [ ] <a id="g-40"></a>**G-40 Advertising ID declaration.** Apps targeting Android 13 or later declare whether they use the advertising ID. Answer: no; the `AD_ID` permission is removed from the merged manifest. Check the release build with `aapt dump permissions`. Status: owner. Where: Play Console > App content > Advertising ID; `android/app/src/main/AndroidManifest.xml`. Source: [Advertising ID](https://support.google.com/googleplay/android-developer/answer/6048248), 2026-11-26
- [ ] <a id="g-41"></a>**G-41 Developer verification for the direct APK.** Certified Android devices only install apps whose package and signing key are registered to a verified developer. Start 30 September 2026 in Brazil, Indonesia, Singapore and Thailand, worldwide in 2027. The APK on GitHub Releases stays (decision), so the client registers the package name and the key that signs the direct APK in the Play Console. Status: owner. Where: Play Console > developer verification; `.github/workflows/release.yml`. Source: [Android developer verification](https://developer.android.com/developer-verification), 2026-11-26

### Overview by topic

#### Privacy

Items: [G-04](#g-04), [G-12](#g-12), [G-13](#g-13), [G-31](#g-31)

#### Intellectual property

Items: [G-02](#g-02), [G-03](#g-03), [G-32](#g-32)

#### Updates

Items: [G-08](#g-08), [G-11](#g-11), [G-34](#g-34), [D-01](#d-01)

#### Contact and support

Items: [G-29](#g-29), [G-30](#g-30)

---

## Apple App Store

Scope: iOS, iPadOS, CarPlay and Mac App Store. Not part of the first release; iOS and Mac follow later, together.

Sources (all retrieved 2026-11-26):

- App Review Guidelines: <https://developer.apple.com/app-store/review/guidelines/>
- Privacy manifest files: <https://developer.apple.com/documentation/bundleresources/privacy-manifest-files>
- Required reason APIs: <https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api>
- Third-party SDK requirements: <https://developer.apple.com/support/third-party-SDK-requirements/>
- App privacy details (labels): <https://developer.apple.com/app-store/app-privacy-details/>
- Encryption export regulations: <https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations>
- Age rating: <https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating>
- CarPlay: <https://developer.apple.com/carplay/>
- App Sandbox: <https://developer.apple.com/documentation/security/app-sandbox>
- Upcoming requirements: <https://developer.apple.com/news/upcoming-requirements/>
- AlarmKit: <https://developer.apple.com/documentation/alarmkit>

### App Review Guidelines (one entry per section)

- [ ] <a id="a-01"></a>**A-01 Before you submit.** The build must be complete, tested on a device, with working links, demo notes and contact details for review. Status: open. Where: App Store Connect > App Review Information; `fastlane/metadata/{de-DE,en-US}/` (no `review_information` yet). Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.
- [x] <a id="a-02"></a>**A-02 Section 1, Safety.** No objectionable content created by the app, no user-generated content, contact details reachable, no harm to the device. Status: OK. Where: `lib/`, imprint in the app. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.
- [ ] <a id="a-03"></a>**A-03 Section 2.1 to 2.3, completeness and accurate metadata.** Screenshots must show the real app, metadata must match it. iPhone, iPad and Mac screenshots are missing. Status: open. Where: `fastlane/metadata/`, App Store Connect > Product page. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.
- [ ] <a id="a-04"></a>**A-04 Section 2.4.5 and 2.5.2, no own updater and no downloaded code.** Mac App Store apps update only through the store. The updater is removed by a build flag; the CI check is still missing. Status: open. Where: `.github/workflows/store-apple.yml`, build flags. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.
- [x] <a id="a-05"></a>**A-05 Section 2.5.4, background modes.** Only the `audio` mode, used for audible playback. Status: OK. Where: `ios/Runner/Info.plist`. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.
- [x] <a id="a-06"></a>**A-06 Section 3, Business.** No purchases, no subscriptions, no ads, no external payment links. Status: OK. Where: `pubspec.yaml`. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.
- [x] <a id="a-07"></a>**A-07 Section 4.2, minimum functionality.** More than a stream wrapper: widget, alarm, AirPlay, favourites, history. List these in the review notes. Status: OK. Where: `ios/LinefmWidget/`, `ios/Runner/`. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.
- [x] <a id="a-08"></a>**A-08 Section 4, Design (rest).** Native look, iPad with all orientations, launch screen present. Status: OK. Where: `ios/Runner/Info.plist`. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.
- [ ] <a id="a-09"></a>**A-09 Section 5.1, privacy.** Privacy policy in the app and in App Store Connect, consent before collecting, no account so no deletion flow. Placeholders in the privacy policy remain. Status: open. Where: `web/datenschutz/`, `lib/features/legal/`. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.
- [ ] <a id="a-10"></a>**A-10 Section 5.2, intellectual property.** Streaming third-party content needs permission. The client holds the laut.fm agreement and states it in App Store Connect under content rights. Status: owner. Where: App Store Connect > App Information > Content Rights; client's records. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.
- [x] <a id="a-11"></a>**A-11 Section 5.3 to 5.6, gaming, VPN, MDM, developer code of conduct.** Not relevant beyond honest conduct towards users and review. Status: OK. Where: none. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.

### Technical and form requirements

- [x] <a id="a-12"></a>**A-12 Privacy manifest.** `PrivacyInfo.xcprivacy` for app, widget and Mac app, with tracking off and the accessed API reasons. Status: OK (check that each target copies the file into its bundle). Where: `ios/Runner/PrivacyInfo.xcprivacy`, `ios/LinefmWidget/PrivacyInfo.xcprivacy`, `macos/Runner/PrivacyInfo.xcprivacy`. Source: [Privacy manifest](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files), 2026-11-26.
- [ ] <a id="a-13"></a>**A-13 Required reason APIs in plugins.** Every listed API, including inside plugins, needs an approved reason or the upload fails. Run Xcode's privacy report on an archive. Status: open. Where: Mac build, plugins from `pubspec.yaml`. Source: [Required reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api), 2026-11-26.
- [ ] <a id="a-14"></a>**A-14 Third-party SDKs.** Listed SDKs need their own manifest and signature (Firebase and others). Status: open. Where: `ios/Podfile.lock` after the first Mac build. Source: [Third-party SDK requirements](https://developer.apple.com/support/third-party-SDK-requirements/), 2026-11-26.
- [ ] <a id="a-15"></a>**A-15 Privacy labels.** Declare crash data and product interaction (Sentry, Firebase, Umami), not linked to identity, no tracking. Optional collection after consent still counts as collection. Check whether Firebase sends a device ID. Status: owner. Where: App Store Connect > App Privacy; `docs/STORE-DATENSCHUTZANGABEN.md`. Source: [App privacy details](https://developer.apple.com/app-store/app-privacy-details/), 2026-11-26.
- [x] <a id="a-16"></a>**A-16 Export compliance.** Only system TLS, so `ITSAppUsesNonExemptEncryption` is false. Status: OK. Where: `ios/Runner/Info.plist`, `macos/Runner/Info.plist`. Source: [Export regulations](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations), 2026-11-26.
- [ ] <a id="a-17"></a>**A-17 Age rating.** Answer the current questionnaire (new age levels since 2026); target 13+ because of occasional strong language in songs. Status: owner. Where: App Store Connect > App Information > Age Rating. Source: [Age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating), 2026-11-26.
- [ ] <a id="a-18"></a>**A-18 Upload SDK minimum.** Since 28 April 2026 uploads must be built with Xcode 26 and the iOS 26 SDK. The workflow does not pin an Xcode version yet. Status: open. Where: `.github/workflows/store-apple.yml`. Source: [Upcoming requirements](https://developer.apple.com/news/upcoming-requirements/), 2026-11-26.
- [x] <a id="a-19"></a>**A-19 Minimum deployment target.** Since 9 September 2026 iOS uploads must target iOS 13 or later; the app targets 13.0, the widget 14.0. Status: OK. Where: `ios/Runner.xcodeproj/project.pbxproj`. Source: [Upcoming requirements](https://developer.apple.com/news/upcoming-requirements/), 2026-11-26.
- [ ] <a id="a-20"></a>**A-20 AlarmKit.** On iOS 26 and later, alarms go through AlarmKit with a usage description; below that a notification with a clear hint that the radio starts after a tap. Status: open (decision taken, code missing). Where: `ios/Runner/AlarmNotifications.swift`, `ios/Runner/Info.plist`, `docs/STORE-TEXTE.md`. Source: [AlarmKit](https://developer.apple.com/documentation/alarmkit), 2026-11-26.
- [ ] <a id="a-21"></a>**A-21 CarPlay audio.** CarPlay needs an entitlement that Apple grants on request for audio apps, and template-based UI only. The entitlement file is ready and disabled. Status: owner (request with the client's account). Where: `ios/Runner/Runner-CarPlay.entitlements`, Apple developer account > CarPlay request. Source: [CarPlay](https://developer.apple.com/carplay/), 2026-11-26.
- [ ] <a id="a-22"></a>**A-22 Mac App Store sandbox.** Sandbox is required, entitlements as few as possible. Replace the downloads entitlement with a save dialog (decision taken). Status: open. Where: `macos/Runner/Release.entitlements`. Source: [App Sandbox](https://developer.apple.com/documentation/security/app-sandbox), 2026-11-26.
- [ ] <a id="a-23"></a>**A-23 Mac App Store submission with iOS.** Same release, own screenshots and category. Status: open. Where: `.github/workflows/store-apple.yml`, App Store Connect > macOS. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.
- [ ] <a id="a-24"></a>**A-24 Developer account.** Organisation account of the client (D-U-N-S number), the agency gets a role. Status: owner. Where: Apple Developer Program. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.

### Account, fees, review and recurring duties

- [ ] <a id="a-25"></a>**A-25 EU trader status (Digital Services Act).** Every account declares its trader status, even without EU distribution; App Store Connect asks at the next submission. For organisations the address comes from the D-U-N-S record; traders add phone and email (shown on the product page in the EU), payment account details if not yet entered, and certify that their offer follows EU law. Non-traders get a notice to EU consumers that consumer rights do not apply. Status: owner. Where: App Store Connect > Business > Compliance. Source: [DSA trader requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements), 2026-11-26.
- [ ] <a id="a-26"></a>**A-26 Membership fee.** The Apple Developer Program costs 99 US dollars per membership year, charged in local currency; renew it in time, or the apps leave the store. Status: owner. Source: [Enroll](https://developer.apple.com/programs/enroll/), 2026-11-26.
- [ ] <a id="a-27"></a>**A-27 Agreements, tax and banking.** For a free app the free apps agreement is enough and tax forms are only needed for sales; as a DSA trader, however, Apple asks for payment account details (see A-25). Accept updated agreements when App Store Connect asks, otherwise uploads stop. Status: owner. Where: App Store Connect > Business. Source: [Sign and update agreements](https://developer.apple.com/help/app-store-connect/manage-agreements/sign-and-update-agreements), 2026-11-26.
- [ ] <a id="a-28"></a>**A-28 Support URL.** A support URL with real contact information is mandatory, a marketing URL is optional: the `/support/` page. Status: owner. Where: `fastlane/metadata/*/support_url.txt`, App Store Connect > Product page. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.
- [ ] <a id="a-29"></a>**A-29 Review notes.** Say that no login is needed, how to try the alarm, AirPlay and CarPlay, and where the content rights come from. Status: owner. Where: App Store Connect > App Review Information. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.
- [ ] <a id="a-30"></a>**A-30 Responding to review.** Answer in App Store Connect, fix and resubmit, or appeal to the App Review Board. Status: owner. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/) (part "After You Submit"), 2026-11-26.
- [x] <a id="a-31"></a>**A-31 Data deletion.** No accounts, so no in-app deletion is required; telemetry requests go through the privacy contact. Status: OK. Where: `web/datenschutz/`. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.
- [ ] <a id="a-32"></a>**A-32 Recurring deadlines.** Each spring Apple raises the Xcode and SDK minimum; age rating answers and privacy labels must be updated when Apple changes the questions. Status: owner (calendar entry each March). Source: [Upcoming requirements](https://developer.apple.com/news/upcoming-requirements/), 2026-11-26.

- [x] <a id="a-33"></a>**A-33 Rule 4.3, spam and duplicates.** One app per purpose; no copies of the same app under different names or per station. Status: OK by design (one app for all stations), keep it that way. Where: `assets/config/`. Source: [Guidelines](https://developer.apple.com/app-store/review/guidelines/), 2026-11-26.

- [ ] <a id="a-34"></a>**A-34 Ads in App Store Connect.** Where the age rating questions ask about advertising, answer no: the app shows no ads of its own; spots in the streams come from the stations. Status: owner. Where: App Store Connect > Age Rating. Source: [Age rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating), not verified

### Overview by topic

#### Privacy

Items: [A-09](#a-09), [A-12](#a-12), [A-15](#a-15), [A-31](#a-31)

#### Intellectual property

Items: [A-10](#a-10), [D-03](#d-03)

#### Updates

Items: [A-04](#a-04), [A-18](#a-18), [A-32](#a-32), [D-01](#d-01)

#### Contact and support

Items: [A-28](#a-28), [A-29](#a-29)

---

## Microsoft Store

Policy version 7.20.

Source: <https://learn.microsoft.com/en-us/windows/apps/publish/store-policies>, retrieved 2026-11-26 (page title confirms version 7.20). All entries in this section use this source.

### Product policies

- [x] <a id="m-01"></a>**M-01 10.1 Distinct function and accurate representation.** Clear purpose, unique title without keywords, metadata that matches the app. Status: OK. Where: `pubspec.yaml` (`msix_config`), `docs/STORE-TEXTE.md`.
- [ ] <a id="m-02"></a>**M-02 10.2 Security.** No code downloaded at runtime; a store package updates only through the store. The updater is excluded by a build flag; the CI check is open. Status: open. Where: `.github/workflows/store-microsoft.yml`, build flags.
- [x] <a id="m-03"></a>**M-03 10.3 Product is testable.** No login, all features reachable by the tester. Status: OK. Where: Partner Center > Notes for certification.
- [x] <a id="m-04"></a>**M-04 10.4 Usability.** Starts fast, works on supported Windows versions, does not crash. Status: OK (test on a clean machine before submission). Where: `.github/workflows/itest-windows.yml`.
- [ ] <a id="m-05"></a>**M-05 10.5 Personal information.** A privacy policy is required when personal data is sent; consent before telemetry. Placeholders remain. Status: open. Where: `web/datenschutz/`, Partner Center > Properties > Privacy policy URL.
- [x] <a id="m-06"></a>**M-06 10.6 Capabilities.** Declare only what is used: `internetClient`. Status: OK. Where: `pubspec.yaml` (`msix_config`).
- [x] <a id="m-07"></a>**M-07 10.7 Localisation.** Listing in every language the app supports: German and English. Status: OK. Where: `docs/STORE-TEXTE.md`.
- [x] <a id="m-08"></a>**M-08 10.8 Financial transactions.** None. Status: OK. Where: none.
- [x] <a id="m-09"></a>**M-09 10.9 Notifications.** Notifications only with user control, no ads in notifications. Status: OK. Where: `lib/services/alarm/`.
- [x] <a id="m-10"></a>**M-10 10.10 Advertising.** No ads. Status: OK. Where: none.
- [x] <a id="m-11"></a>**M-11 10.13 Gaming and Xbox.** Not relevant. Status: OK.
- [ ] <a id="m-12"></a>**M-12 10.14 Account type.** Publish from a company account of the client. Status: owner. Where: Partner Center > Account settings.

### Content policies

- [x] <a id="m-13"></a>**M-13 11.1 General content.** Content suitable for the declared rating. Status: OK.
- [ ] <a id="m-14"></a>**M-14 11.2 Names, logos, original and third-party content.** Right to use station names, logos and streams. The client holds the laut.fm agreement and the LINEFM brand rights. Status: owner. Where: client's records, Partner Center notes.
- [x] <a id="m-15"></a>**M-15 11.3 to 11.8 Harm, defamation, offensive, alcohol/tobacco/weapons/drugs, adult, illegal.** Not part of the app's own content. Status: OK.
- [x] <a id="m-16"></a>**M-16 11.9 Excessive profanity.** Occasional explicit lyrics in songs; declared through the rating. Status: OK (covered by M-17).
- [x] <a id="m-17"></a>**M-17 11.10 Country-specific requirements.** Imprint and privacy policy follow German law. Status: OK (legal review by a lawyer recommended). Where: `web/impressum/`, `web/datenschutz/`.
- [ ] <a id="m-18"></a>**M-18 11.11 Age ratings.** IARC questionnaire in Partner Center; target 13+. Status: owner. Where: Partner Center > Age ratings.
- [x] <a id="m-19"></a>**M-19 11.12 to 11.16 UGC, third-party storefronts, gambling, child safety, live generative AI.** Not present. Status: OK.

### Account, fees and review

- [ ] <a id="m-20"></a>**M-20 Account and fee.** Company account of the client in Partner Center with company verification and a work email on the company domain; with the current onboarding there is no registration fee. Status: owner. Source: [Account types and fees](https://learn.microsoft.com/en-us/windows/apps/publish/partner-center/account-types-locations-and-fees), 2026-11-26.
- [x] <a id="m-21"></a>**M-21 Payout and tax forms.** Only for paid apps; not needed. Status: OK. Where: Partner Center > Payout and tax.
- [ ] <a id="m-22"></a>**M-22 Support contact and certification notes.** Support contact in the listing (support@linefm.de, `/support/` page); notes for testers (no login, alarm). Status: owner. Where: Partner Center > Properties and Submission options.
- [ ] <a id="m-23"></a>**M-23 Certification failures.** Fix and resubmit, or use the appeal process described at the end of the policy. Status: owner.

- [x] <a id="m-24"></a>**M-24 10.11 and 10.12.** Both marked "Policy removed" in version 7.20. Version 7.20 has no sections 10.15 or 11.17. Status: OK. Source: [Store policies](https://learn.microsoft.com/en-us/windows/apps/publish/store-policies), 2026-11-26
- [ ] <a id="m-25"></a>**M-25 EU trader status (Digital Services Act).** If Partner Center asks for the trader status, declare the client as a trader with the same address, phone and email as in Google and Apple. Status: owner. Where: Partner Center > Account settings. Source: [Open a developer account](https://learn.microsoft.com/en-us/windows/apps/publish/partner-center/open-a-developer-account), not verified (no Microsoft page on the trader status found on 2026-11-26; checked Microsoft Learn search and the account pages)
- [ ] <a id="m-26"></a>**M-26 Ads question.** Answer no in the product properties: no ad SDK; spots in streams come from the stations. Status: owner. Where: Partner Center > Properties. Source: [Store policies](https://learn.microsoft.com/en-us/windows/apps/publish/store-policies) 10.10, 2026-11-26

### Overview by topic

#### Privacy

Items: [M-05](#m-05)

#### Intellectual property

Items: [M-14](#m-14), [D-03](#d-03)

#### Updates

Items: [M-02](#m-02), [D-01](#d-01)

#### Contact and support

Items: [M-22](#m-22)

---

## Snap Store

Sources:

- Snap Store terms of service: <https://ubuntu.com/legal/terms-and-policies/snap-store-terms>, retrieved 2026-11-26.
- Store requests (aliases, auto-connections, tracks): <https://forum.snapcraft.io/t/process-for-aliases-auto-connections-and-tracks/455>, retrieved 2026-11-26.
- Permission requests: <https://snapcraft.io/docs/permission-requests>, not verified (page returned no readable title on 2026-11-26).

- [x] <a id="s-01"></a>**S-01 Strict confinement.** Store snaps run confined; interfaces only as needed. Status: OK. Where: `packaging/snap/snapcraft.yaml`. Source: [Terms](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 2026-11-26.
- [x] <a id="s-02"></a>**S-02 Interfaces without manual review.** `audio-playback`, `network` and the MPRIS slot connect automatically; anything else needs a request in the forum. Status: OK (tray still to test). Where: `packaging/snap/snapcraft.yaml`. Source: [Store requests](https://forum.snapcraft.io/t/process-for-aliases-auto-connections-and-tracks/455), 2026-11-26.
- [ ] <a id="s-03"></a>**S-03 Name and brand.** Register `linefm-radio` with the account of the brand owner. Status: owner. Where: snapcraft.io dashboard. Source: [Terms](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 2026-11-26.
- [ ] <a id="s-04"></a>**S-04 Rights to publish.** The publisher must hold the rights to the content and code distributed. Status: owner (laut.fm agreement and LINEFM rights with the client). Source: [Terms](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 2026-11-26.
- [x] <a id="s-05"></a>**S-05 No self-update.** Snaps update through the store; the updater is excluded. Status: OK (CI check D-01 open). Where: build flags. Source: [Terms](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 2026-11-26.
- [ ] <a id="s-06"></a>**S-06 Build tested.** The snap build has never run in CI. Status: open. Where: `.github/workflows/store-snap.yml`. Source: [Terms](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 2026-11-26.

- [ ] <a id="s-07"></a>**S-07 Account and fees.** Ubuntu One account of the client, no fee, no tax forms for free snaps. Status: owner. Source: [Terms](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 2026-11-26.

- [ ] <a id="s-08"></a>**S-08 Contact and support.** Contact address and website in the snap metadata: support@linefm.de and the `/support/` page. Status: open. Where: `packaging/snap/snapcraft.yaml` (`contact`, `website`), `web/support/` (to create). Source: [Terms](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 2026-11-26.

- [ ] <a id="s-09"></a>**S-09 Privacy policy and contact in the listing.** Enter the privacy policy URL, support@linefm.de and the `/support/` page in the snapcraft.io listing. Status: owner. Where: snapcraft.io > Listing. Source: [Terms](https://ubuntu.com/legal/terms-and-policies/snap-store-terms), 2026-11-26 (listing fields themselves not verified)

### Overview by topic

#### Privacy

Items: [D-04](#d-04)

#### Intellectual property

Items: [S-03](#s-03), [S-04](#s-04)

#### Updates

Items: [S-05](#s-05), [D-01](#d-01)

#### Contact and support

Items: [S-08](#s-08)

---

## Flathub

Sources (all retrieved 2026-11-26):

- Requirements: <https://docs.flathub.org/docs/for-app-authors/requirements>
- MetaInfo guidelines: <https://docs.flathub.org/docs/for-app-authors/metainfo-guidelines>
- Verification: <https://docs.flathub.org/docs/for-app-authors/verification>

- [x] <a id="f-01"></a>**F-01 Inclusion policy.** Graphical desktop app with real function, not a tray-only app, not a duplicate. Status: OK. Source: [Requirements](https://docs.flathub.org/docs/for-app-authors/requirements), 2026-11-26.
- [x] <a id="f-02"></a>**F-02 Monetisation and generative AI policy.** No payment flows, no generated content. Status: OK. Source: [Requirements](https://docs.flathub.org/docs/for-app-authors/requirements), 2026-11-26.
- [x] <a id="f-03"></a>**F-03 Application ID.** Reverse DNS of a domain we control: `de.linefm.app`. Status: OK. Where: `packaging/flathub/de.linefm.app.yml`. Source: [Requirements](https://docs.flathub.org/docs/for-app-authors/requirements), 2026-11-26.
- [ ] <a id="f-04"></a>**F-04 Domain verification.** A token file under `linefm.de/.well-known/org.flathub.VerifiedApps.txt` (https) proves control of the domain and gives the verified badge. The client places it at go-live: copy the token from the Flathub developer portal, save it as a plain text file at that path on the linefm.de web server, check that it loads in the browser, then press "Verify" in the portal. Status: owner. Where: linefm.de web server. Source: [Verification](https://docs.flathub.org/docs/for-app-authors/verification), 2026-11-26.
- [ ] <a id="f-05"></a>**F-05 Building from source.** Flathub builds from source; prebuilt binaries only for known vendors. The manifest still uses a prebuilt archive; the offline source build is decided but not built. Status: open. Where: `packaging/flathub/de.linefm.app.yml`, `.github/workflows/flathub-prep.yml`. Source: [Requirements](https://docs.flathub.org/docs/for-app-authors/requirements), 2026-11-26.
- [x] <a id="f-06"></a>**F-06 No network during the build.** All sources pinned with checksums. Status: OK (generate Dart package sources for the source build). Where: `packaging/flathub/de.linefm.app.yml`. Source: [Requirements](https://docs.flathub.org/docs/for-app-authors/requirements), 2026-11-26.
- [ ] <a id="f-07"></a>**F-07 License.** License in the metainfo, license file installed, content legally redistributable. The license URL must point to `/lizenz/`, which does not exist yet. Status: open. Where: `linux/de.linefm.app.metainfo.xml`, `web/lizenz/` (to create). Source: [Requirements](https://docs.flathub.org/docs/for-app-authors/requirements), 2026-11-26.
- [ ] <a id="f-08"></a>**F-08 Permissions.** As few as possible, portals where available; justify `--share=ipc` and the notification bus name. Status: open (review). Where: `packaging/flathub/de.linefm.app.yml` (`finish-args`). Source: [Requirements](https://docs.flathub.org/docs/for-app-authors/requirements), 2026-11-26.
- [x] <a id="f-09"></a>**F-09 Stable releases and patches.** Only stable versions, patches upstream where possible. Status: OK. Source: [Requirements](https://docs.flathub.org/docs/for-app-authors/requirements), 2026-11-26.
- [ ] <a id="f-10"></a>**F-10 MetaInfo quality.** Real screenshots at stable URLs, release entries with dates, OARS rating (`language-profanity` moderate), developer tag, no trademark misuse in name or icon. Status: open (placeholders). Where: `linux/de.linefm.app.metainfo.xml`. Source: [MetaInfo guidelines](https://docs.flathub.org/docs/for-app-authors/metainfo-guidelines), 2026-11-26.
- [x] <a id="f-11"></a>**F-11 No self-update.** Flatpaks update through Flathub; the updater is excluded. Status: OK (CI check D-01 open). Source: [Requirements](https://docs.flathub.org/docs/for-app-authors/requirements), 2026-11-26.

- [ ] <a id="f-12"></a>**F-12 Account, fees and review.** GitHub account of the client for the submission, no fee. Review happens in the public submission on GitHub; answer the reviewers there. Status: owner. Source: [Requirements](https://docs.flathub.org/docs/for-app-authors/requirements), 2026-11-26.

- [ ] <a id="f-13"></a>**F-13 Contact and support.** `url type="contact"` and `url type="support"` in the metainfo: support@linefm.de and the `/support/` page. Status: open. Where: `linux/de.linefm.app.metainfo.xml`. Source: [MetaInfo guidelines](https://docs.flathub.org/docs/for-app-authors/metainfo-guidelines), 2026-11-26.

### Overview by topic

#### Privacy

Items: [D-04](#d-04)

#### Intellectual property

Items: [F-07](#f-07), [F-10](#f-10), [D-03](#d-03)

#### Updates

Items: [F-09](#f-09), [F-11](#f-11), [D-01](#d-01)

#### Contact and support

Items: [F-13](#f-13)

---

## Web and PWA

Sources (retrieved 2026-11-26): <https://web.dev/articles/install-criteria>, <https://www.w3.org/TR/appmanifest/>.

- [x] <a id="w-01"></a>**W-01 Installable.** Manifest with name, icons 192 and 512 (maskable), start URL, `display` standalone, served over HTTPS with a service worker. Status: OK. Where: `web/manifest.webmanifest`. Source: [Install criteria](https://web.dev/articles/install-criteria), 2026-11-26.
- [ ] <a id="w-02"></a>**W-02 Rich install UI.** Optional `screenshots` and `shortcuts` in the manifest. Status: open (optional). Where: `web/manifest.webmanifest`. Source: [Manifest](https://www.w3.org/TR/appmanifest/), 2026-11-26.
- [x] <a id="w-03"></a>**W-03 Consent before tracking.** GA4 and GTM only after consent. Status: OK. Where: `web/analytics.js`, `web/datenschutz/`. Source: [TDDDG § 25](https://www.gesetze-im-internet.de/ttdsg/__25.html), 2026-11-26.
- [ ] <a id="w-04"></a>**W-04 License page.** `/lizenz/` in German and English, linked from the metainfo and the stores. Status: open. Where: `web/lizenz/` (to create). Source: owner decision; Flathub needs it, see F-07.

- [ ] <a id="w-05"></a>**W-05 Contact and support.** `/support/` page in German and English with support@linefm.de, linked from imprint, app and every store listing. Status: open. Where: `web/support/` (to create). Source: owner decision; the stores need it, see G-29, A-28, M-22.

- [ ] <a id="w-06"></a>**W-06 Accessibility statement.** Published voluntarily at `/barrierefreiheit/` (German and English), even if the micro-enterprise exemption of the BFSG may apply; the lawyer confirms. Status: open. Where: `web/barrierefreiheit/` (to create). Source: [BFSG § 3](https://www.gesetze-im-internet.de/bfsg/__3.html), 2026-11-26

### Overview by topic

#### Privacy

Items: [W-03](#w-03)

#### Intellectual property

Items: [W-04](#w-04)

#### Updates

Items: [W-01](#w-01)

#### Contact and support

Items: [W-05](#w-05)

---

## Cross-store points

- [ ] <a id="d-01"></a>**D-01 Updater only in direct downloads.** Store builds (Play, App Store, Mac App Store, Microsoft Store, Snap, Flathub) are built without the updater; a CI check searches the store packages for updater code. Status: open. Where: build flags, `.github/workflows/store-*.yml`.
- [ ] <a id="d-02"></a>**D-02 Own accounts of the client.** Every store account belongs to the client's organisation. Status: owner. Where: `docs/EINRICHTUNG.md`.
- [ ] <a id="d-03"></a>**D-03 Content rights.** The client keeps the laut.fm agreement and names it wherever a store asks for rights (Apple content rights, Google on request, Microsoft notes, Snap, Flathub). The same applies to the partner stations Radio3FM and FobFM: the client keeps their written consent to be listed. The client also obtains written confirmation from laut.fm that its GEMA and GVL licences cover playback in the LINEFM app; the lawyer checks it. Status: owner.
- [ ] <a id="d-04"></a>**D-04 Privacy policy without placeholders.** Controller and contact filled in, all three telemetry services named as optional. It also names the outbound links and lookups: Spotify, YouTube Music, radiogruppe.de and the iTunes search for covers. The URL must stay reachable for good: domain renewal, TLS and uptime monitoring. Legal review by a lawyer recommended. Status: owner. Where: `web/datenschutz/`, `web/datenschutz/en/`.

- [ ] <a id="d-05"></a>**D-05 Record of processing activities (Art. 30 GDPR).** A filled template lists Sentry, Firebase, Umami, GA4/GTM on the web, laut.fm requests, server logs and support mail. The client checks it, adds company data and keeps it current. Status: owner. Where: `docs/VERARBEITUNGSVERZEICHNIS.md`. Source: [Art. 30 GDPR](https://dsgvo-gesetz.de/art-30-dsgvo/), 2026-11-26
- [ ] <a id="d-06"></a>**D-06 Youth protection (JMStV).** The 13+ rating and its reason (occasional strong language in third-party streams) are documented. Whether a youth protection officer is needed is checked by the client's lawyer. Status: owner. Where: client's records. Source: [JMStV § 7](https://www.gesetze-bayern.de/Content/Document/JMStV-7), 2026-11-26

---

## Further stores (not planned yet)

Only the main rules and the links. If a store becomes relevant, expand its section like the ones above.

- [ ] <a id="x-01"></a>**X-01 Amazon Appstore.** Content policy close to Google Play; apps are reviewed, an age rating is set by Amazon, Android features without Google services. Chromecast and Android Auto would not work on Fire devices. Status: not planned yet. Source: [Content policy](https://developer.amazon.com/docs/policy-center/understanding-content-policy.html), 2026-11-26.
- [ ] <a id="x-02"></a>**X-02 Samsung Galaxy Store.** Own review against the distribution guide: working app, accurate metadata, age rating, privacy policy. Status: not planned yet. Source: [Distribution guide](https://developer.samsung.com/galaxy-store/distribution-guide.html), 2026-11-26.
- [ ] <a id="x-03"></a>**X-03 Huawei AppGallery.** Review rules for content, privacy and functionality; apps must run without Google Mobile Services. Status: not planned yet. Source: [Review guidelines](https://developer.huawei.com/consumer/en/doc/app/50104), not verified (page renders only with JavaScript).
- [ ] <a id="x-04"></a>**X-04 F-Droid.** Only free and open-source software built from source; proprietary dependencies (Firebase, Cast SDK) are flagged or rejected. The proprietary license of LINEFM rules it out as it stands. Status: not planned yet. Source: [Inclusion policy](https://f-droid.org/docs/Inclusion_Policy/), 2026-11-26.
- [ ] <a id="x-05"></a>**X-05 winget.** Manifest in the community repository pointing to the signed Windows setup; installer must run silently. A good fit for the direct-download setup. Status: not planned yet. Source: [Submit packages](https://learn.microsoft.com/en-us/windows/package-manager/package/), 2026-11-26.
- [ ] <a id="x-06"></a>**X-06 Homebrew cask.** Cask for the notarised macOS DMG; the app must be signed, notarised and reasonably known. Status: not planned yet. Source: [Acceptable casks](https://docs.brew.sh/Acceptable-Casks), 2026-11-26.
