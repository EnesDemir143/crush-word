# Graph Report - .  (2026-04-18)

## Corpus Check
- 31 files · ~0 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 80 nodes · 92 edges · 15 communities detected
- Extraction: 83% EXTRACTED · 17% INFERRED · 0% AMBIGUOUS · INFERRED: 16 edges (avg confidence: 0.5)
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
Cohesion: 0.25
Nodes (3): AppDelegate, FlutterAppDelegate, FlutterImplicitEngineDelegate

### Community 3 - "Community 3"
Cohesion: 0.32
Nodes (0): 

### Community 4 - "Community 4"
Cohesion: 0.38
Nodes (2): GetCommandLineArguments(), Utf8FromUtf16()

### Community 5 - "Community 5"
Cohesion: 0.5
Nodes (2): GeneratedPluginRegistrant, -registerWithRegistry

### Community 6 - "Community 6"
Cohesion: 0.5
Nodes (2): handle_new_rx_page(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.

### Community 7 - "Community 7"
Cohesion: 0.5
Nodes (2): RunnerTests, XCTestCase

### Community 8 - "Community 8"
Cohesion: 0.5
Nodes (2): MainFlutterWindow, NSWindow

### Community 9 - "Community 9"
Cohesion: 0.67
Nodes (2): FlutterSceneDelegate, SceneDelegate

### Community 10 - "Community 10"
Cohesion: 1.0
Nodes (1): MainActivity

### Community 11 - "Community 11"
Cohesion: 1.0
Nodes (1): WindowClassRegistrar

### Community 12 - "Community 12"
Cohesion: 1.0
Nodes (0): 

### Community 13 - "Community 13"
Cohesion: 1.0
Nodes (0): 

### Community 14 - "Community 14"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **3 isolated node(s):** `MainActivity`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry`
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 10`** (2 nodes): `MainActivity.kt`, `MainActivity`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 11`** (2 nodes): `WindowClassRegistrar`, `.WindowClassRegistrar()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 12`** (1 nodes): `build.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 13`** (1 nodes): `settings.gradle.kts`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 14`** (1 nodes): `Runner-Bridging-Header.h`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WindowClassRegistrar` connect `Community 11` to `Community 0`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `Create()` (e.g. with `Destroy()` and `GetWindowClass()`) actually correct?**
  _`Create()` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 5 inferred relationships involving `Destroy()` (e.g. with `Win32Window()` and `Create()`) actually correct?**
  _`Destroy()` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `MessageHandler()` (e.g. with `WndProc()` and `Destroy()`) actually correct?**
  _`MessageHandler()` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Are the 3 inferred relationships involving `WndProc()` (e.g. with `EnableFullDpiSupportIfAvailable()` and `GetThisFromHandle()`) actually correct?**
  _`WndProc()` has 3 INFERRED edges - model-reasoned connections that need verification._
- **What connects `MainActivity`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry` to the rest of the system?**
  _3 weakly-connected nodes found - possible documentation gaps or missing edges._