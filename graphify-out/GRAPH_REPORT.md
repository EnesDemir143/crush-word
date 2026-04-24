# Graph Report - .  (2026-04-24)

## Corpus Check
- 102 files · ~0 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 112 nodes · 100 edges · 40 communities detected
- Extraction: 84% EXTRACTED · 16% INFERRED · 0% AMBIGUOUS · INFERRED: 16 edges (avg confidence: 0.5)
- Token cost: 0 input · 0 output

## God Nodes (most connected - your core abstractions)
1. `AppDelegate` - 7 edges
2. `Create()` - 6 edges
3. `Destroy()` - 6 edges
4. `MessageHandler()` - 5 edges
5. `WndProc()` - 4 edges
6. `GeneratedPluginRegistrant` - 3 edges
7. `RunnerTests` - 3 edges
8. `MainFlutterWindow` - 3 edges
9. `GetClientArea()` - 3 edges
10. `UpdateTheme()` - 3 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Communities

### Community 0 - "Community 0"
Cohesion: 0.18
Nodes (15): Create(), Destroy(), EnableFullDpiSupportIfAvailable(), GetClientArea(), GetThisFromHandle(), GetWindowClass(), MessageHandler(), OnCreate() (+7 more)

### Community 1 - "Community 1"
Cohesion: 0.22
Nodes (0): 

### Community 2 - "Community 2"
Cohesion: 0.22
Nodes (4): FlutterSceneDelegate, RunnerTests, SceneDelegate, XCTestCase

### Community 3 - "Community 3"
Cohesion: 0.32
Nodes (0): 

### Community 4 - "Community 4"
Cohesion: 0.29
Nodes (3): AppDelegate, FlutterAppDelegate, FlutterImplicitEngineDelegate

### Community 5 - "Community 5"
Cohesion: 0.38
Nodes (2): GetCommandLineArguments(), Utf8FromUtf16()

### Community 6 - "Community 6"
Cohesion: 0.4
Nodes (2): GeneratedPluginRegistrant, -registerWithRegistry

### Community 7 - "Community 7"
Cohesion: 0.5
Nodes (2): handle_new_rx_page(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.

### Community 8 - "Community 8"
Cohesion: 0.5
Nodes (2): MainFlutterWindow, NSWindow

### Community 9 - "Community 9"
Cohesion: 1.0
Nodes (1): MainActivity

### Community 10 - "Community 10"
Cohesion: 1.0
Nodes (1): PodsDummy_Pods_Runner

### Community 11 - "Community 11"
Cohesion: 1.0
Nodes (1): PodsDummy_Pods_RunnerTests

### Community 12 - "Community 12"
Cohesion: 1.0
Nodes (1): PodsDummy_shared_preferences_foundation

### Community 13 - "Community 13"
Cohesion: 1.0
Nodes (1): PodsDummy_sqflite_darwin

### Community 14 - "Community 14"
Cohesion: 1.0
Nodes (1): WindowClassRegistrar

### Community 15 - "Community 15"
Cohesion: 1.0
Nodes (0): 

### Community 16 - "Community 16"
Cohesion: 1.0
Nodes (0): 

### Community 17 - "Community 17"
Cohesion: 1.0
Nodes (0): 

### Community 18 - "Community 18"
Cohesion: 1.0
Nodes (0): 

### Community 19 - "Community 19"
Cohesion: 1.0
Nodes (0): 

### Community 20 - "Community 20"
Cohesion: 1.0
Nodes (0): 

### Community 21 - "Community 21"
Cohesion: 1.0
Nodes (0): 

### Community 22 - "Community 22"
Cohesion: 1.0
Nodes (0): 

### Community 23 - "Community 23"
Cohesion: 1.0
Nodes (0): 

### Community 24 - "Community 24"
Cohesion: 1.0
Nodes (0): 

### Community 25 - "Community 25"
Cohesion: 1.0
Nodes (0): 

### Community 26 - "Community 26"
Cohesion: 1.0
Nodes (0): 

### Community 27 - "Community 27"
Cohesion: 1.0
Nodes (0): 

### Community 28 - "Community 28"
Cohesion: 1.0
Nodes (0): 

### Community 29 - "Community 29"
Cohesion: 1.0
Nodes (0): 

### Community 30 - "Community 30"
Cohesion: 1.0
Nodes (0): 

### Community 31 - "Community 31"
Cohesion: 1.0
Nodes (0): 

### Community 32 - "Community 32"
Cohesion: 1.0
Nodes (0): 

### Community 33 - "Community 33"
Cohesion: 1.0
Nodes (0): 

### Community 34 - "Community 34"
Cohesion: 1.0
Nodes (0): 

### Community 35 - "Community 35"
Cohesion: 1.0
Nodes (0): 

### Community 36 - "Community 36"
Cohesion: 1.0
Nodes (0): 

### Community 37 - "Community 37"
Cohesion: 1.0
Nodes (0): 

### Community 38 - "Community 38"
Cohesion: 1.0
Nodes (0): 

### Community 39 - "Community 39"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **7 isolated node(s):** `MainActivity`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `PodsDummy_Pods_Runner`, `PodsDummy_Pods_RunnerTests`, `PodsDummy_shared_preferences_foundation` (+2 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 9`** (2 nodes): `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 10`** (2 nodes): `Pods-Runner-dummy.m`, `PodsDummy_Pods_Runner`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 11`** (2 nodes): `Pods-RunnerTests-dummy.m`, `PodsDummy_Pods_RunnerTests`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 12`** (2 nodes): `shared_preferences_foundation-dummy.m`, `PodsDummy_shared_preferences_foundation`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 13`** (2 nodes): `sqflite_darwin-dummy.m`, `PodsDummy_sqflite_darwin`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 14`** (2 nodes): `WindowClassRegistrar`, `.WindowClassRegistrar()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 15`** (1 nodes): `build.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 16`** (1 nodes): `settings.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 17`** (1 nodes): `FlutterBinaryMessenger.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 18`** (1 nodes): `FlutterCallbackCache.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 19`** (1 nodes): `FlutterChannels.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 20`** (1 nodes): `FlutterCodecs.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 21`** (1 nodes): `FlutterDartProject.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 22`** (1 nodes): `FlutterEngineGroup.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 23`** (1 nodes): `FlutterHeadlessDartRunner.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 24`** (1 nodes): `FlutterHourFormat.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 25`** (1 nodes): `FlutterMacros.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 26`** (1 nodes): `FlutterPlatformViews.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 27`** (1 nodes): `FlutterPlugin.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 28`** (1 nodes): `FlutterPluginAppLifeCycleDelegate.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 29`** (1 nodes): `FlutterSceneLifeCycle.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 30`** (1 nodes): `FlutterTexture.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 31`** (1 nodes): `FlutterViewController.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 32`** (1 nodes): `Pods-Runner-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 33`** (1 nodes): `shared_preferences_foundation-Swift.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 34`** (1 nodes): `shared_preferences_foundation-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 35`** (1 nodes): `SqfliteImportPublic.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 36`** (1 nodes): `SqflitePluginPublic.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 37`** (1 nodes): `sqflite_darwin-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 38`** (1 nodes): `Pods-RunnerTests-umbrella.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 39`** (1 nodes): `Runner-Bridging-Header.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `AppDelegate` connect `Community 4` to `Community 2`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Why does `WindowClassRegistrar` connect `Community 14` to `Community 0`?**
  _High betweenness centrality (0.007) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `Create()` (e.g. with `Destroy()` and `GetWindowClass()`) actually correct?**
  _`Create()` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 5 inferred relationships involving `Destroy()` (e.g. with `Win32Window()` and `Create()`) actually correct?**
  _`Destroy()` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `MessageHandler()` (e.g. with `WndProc()` and `Destroy()`) actually correct?**
  _`MessageHandler()` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `WndProc()` (e.g. with `EnableFullDpiSupportIfAvailable()` and `GetThisFromHandle()`) actually correct?**
  _`WndProc()` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `MainActivity`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `PodsDummy_Pods_Runner` to the rest of the system?**
  _7 weakly-connected nodes found - possible documentation gaps or missing edges._