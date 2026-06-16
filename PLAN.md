# SimfitMemo Current Spec

## Goal

SimfitMemo is a dark-first SwiftUI workout memo app for iOS and watchOS. The iPhone app is the canonical data source. The Apple Watch app is a workout companion that displays the current workout, handles set completion/rest controls, and caches snapshots sent from the phone.

## Current Product Scope

### iOS

- Home screen centered on today's workout record.
- Date strip with lightweight record indicators.
- Calendar view for reviewing workout history by date.
- Routine list, routine detail sheet, routine creation, and routine editing.
- Exercise selection with search, body-part filters, bookmark filter, sorting, selection order badges, and bottom CTA.
- Routine targets with optional set-level weight/repetition/rest targets.
- Empty workout and routine-based workout start.
- Workout memo screen for:
  - adding exercises from the full exercise picker,
  - editing actual weight/repetitions,
  - completing sets,
  - starting rest timers,
  - changing exercise order,
  - dismissing the keyboard by tapping outside inputs,
  - manually sending the current full snapshot to Apple Watch.
- Workout finish summary with total duration and completed set count.
- History persistence via SwiftData-backed app snapshot.
- Live Activity / Dynamic Island support for active workout/rest status.
- App icon assets for iOS.

### Apple Watch

- Home screen with entries for current workout, routines, and history.
- Current workout screen split by state:
  - workout state: current exercise, target, heart rate, set-complete button,
  - rest state: remaining rest time, `-10s`, `+10s`, next set/exercise guidance, rest-complete button.
- Manual sync request button retained as fallback.
- Current workout empty state when no active workout exists.
- Cached routine/history snapshots.
- Heart-rate display through HealthKit when permission/data are available.
- Rest countdown cues:
  - one beep at 10 seconds remaining,
  - three beeps from 3 seconds remaining, ending exactly at rest completion.
- Headset-only audio beep path plus watch haptic notification.
- App icon assets for watchOS.

## Data and Domain Decisions

- iPhone owns canonical state.
- Watch receives snapshots and can send intent events back to iPhone.
- Active workout state tracks:
  - session id,
  - routine name,
  - start/update timestamps,
  - exercise order,
  - current exercise/set,
  - set targets and actual values,
  - rest timer timestamps,
  - sync version.
- Default rest time is 60 seconds.
- Routine exercise only requires an exercise; set targets are optional.
- Exercise order matters and is preserved from selection through routine/workout execution.
- Completed workout records retain workout duration and completed set data.
- Apple Health workout writing is out of scope. HealthKit is used only for heart-rate display.

## Watch Sync Design

### Payloads

- `activeWorkout`
- `routines`
- `history`
- `fullSnapshot`
- `setCompletion`
- `restAdjustment`
- `syncRequest`

Payloads are encoded through shared DTOs and a versioned `WatchPayloadCoding` layer.

### Phone to Watch

- iPhone sends full snapshots containing active workout, routines, and history.
- When the Watch is reachable, the phone uses `sendMessage`.
- If not reachable, the phone falls back to `updateApplicationContext` and then `transferUserInfo`.
- The workout memo screen exposes a visible `Watch 전송` button to push the current state from iPhone to Watch without requiring the user to press sync on the Watch.

### Watch to Phone

- Watch sends set-completion events.
- Watch sends rest-adjustment events for `-10s`, `+10s`, and rest-complete.
- Watch can still send a `syncRequest`; iPhone responds by sending a full snapshot.
- Set-completion events are deduplicated so repeated delivery does not complete the same set twice.

## UI Direction

- Dark charcoal background.
- Dark slate cards and elevated surfaces.
- Bright blue primary actions.
- Muted blue-gray secondary text and borders.
- Dense, utility-oriented screens instead of marketing-style layouts.
- Fixed safe-area bottom actions for core workout/routine flows.

## Key Implementation Areas

- `Shared/DTO/WatchSyncDTOs.swift`
- `Shared/Domain/ActiveWorkoutDomain.swift`
- `Shared/Models/ActiveWorkoutState.swift`
- `Shared/Utilities/RestTimerCalculator.swift`
- `Shared/Utilities/HeadsetOnlyBeepPlayer.swift`
- `SimfitMemo/Stores/AppDataStore.swift`
- `SimfitMemo/Services/WatchSyncService.swift`
- `SimfitMemo/Services/WorkoutLiveActivityService.swift`
- `SimfitMemo/Views/Home/HomeView.swift`
- `SimfitMemo/Views/Home/WorkoutCalendarView.swift`
- `SimfitMemo/Views/ExerciseSelection/ExerciseSelectionView.swift`
- `SimfitMemo/Views/Routines/RoutineListView.swift`
- `SimfitMemo/Views/Routines/RoutineTargetEditorView.swift`
- `SimfitMemo/Views/Workout/WorkoutMemoView.swift`
- `SimfitMemoLiveActivity/`
- `SimfitMemoWatch Watch App/Services/WatchSyncService.swift`
- `SimfitMemoWatch Watch App/Views/WatchHomeView.swift`
- `SimfitMemoWatch Watch App/Views/CurrentWorkoutView.swift`

## Current Verification Commands

```bash
xcodebuild -project SimfitMemo.xcodeproj -scheme SimfitMemo -destination 'generic/platform=iOS' -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

```bash
xcodebuild -project SimfitMemo.xcodeproj -scheme 'SimfitMemo Watch App' -destination 'generic/platform=watchOS' -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

## Device Testing Notes

- Personal Team development signing can expire after roughly 7 days.
- If the Watch app gets stuck installing/running, the effective recovery sequence has been:
  - uninstall the Watch app by bundle id with `devicectl`,
  - reboot the Watch with `devicectl`,
  - reopen Xcode,
  - run the Watch app again.
- WatchConnectivity is sensitive to lock state. Keep both iPhone and Apple Watch unlocked during install/debug sessions.

## Remaining Work

- Make Watch sync more observable with timestamps and explicit last received snapshot status.
- Add a stronger phone-to-watch request/reply sync path for immediate Watch button responses.
- Add UI tests/snapshot tests for the major iPhone flows.
- Add more real-device QA around background delivery, Live Activity behavior, and headset-only rest audio.
- Decide whether to add a settings screen for rest defaults, units, and Watch sync diagnostics.
