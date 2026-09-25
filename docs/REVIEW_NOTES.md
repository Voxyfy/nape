# App Review notes (paste into App Store Connect → App Review Information → Notes)

Nape measures forward head tilt using the motion sensors in AirPods (CoreMotion `CMHeadphoneMotionManager`) and nudges the user when they lean too long.

**Testing.** Requires AirPods Pro / AirPods 3 / AirPods 4 / AirPods Max or Beats Fit Pro, worn in at least one ear. On first launch: Continue → "Set as upright" while looking straight ahead → tracking starts. Tilt your head forward past ~25° for 30 seconds to hear the nudge in the earbuds and feel the haptic. No account or sign-in exists.

**Background audio (UIBackgroundModes: audio).** Nape plays its alert sounds through the headphones while the app is in the background, which is the main use case (user reads on a laptop or phone with the app not in front). To deliver those sounds and to keep receiving headphone motion updates, the audio session stays active while tracking is on. The user can turn this off in Settings ("Track in background"). No audio is recorded.

**Notifications.** Nudges are also posted as local notifications so they mirror to Apple Watch when the iPhone is locked. The permission is requested after calibration with an in-app explanation.

**Live Activity / Apple Watch.** The Live Activity shows the current tilt while tracking. The watch app mirrors the state and lets the user start a self-care extended runtime session (user-initiated via a button) so nudges can be delivered as wrist haptics.

**Privacy.** No data leaves the device. No analytics, no network requests. Motion data is processed in memory; only daily summaries are stored locally.

Privacy policy: https://voxyfy.github.io/nape/privacy.html · Support: https://voxyfy.github.io/nape/support.html

---

## Submission checklist (internal)

- [ ] Xcode: Signing & Capabilities → Time Sensitive Notifications (app), App Groups `group.com.batuhanhaymana.nape` (watch app + watch widget)
- [ ] App Store Connect → App Information: category Health & Fitness, age rating, content rights
- [ ] Pricing & Availability: price, regions, **uncheck "Make available on Mac" and Apple Vision** (iPhone only)
- [ ] App Privacy: "Data Not Collected", privacy policy URL, publish
- [ ] Version page: build, contact info (all four fields), "Sign-in required" unchecked, review notes above
- [ ] Screenshots: `store/en/6.9` and `store/tr/6.9` (1320×2868), optional 6.5"
- [ ] Localizations: English (primary), Turkish
