# Harbour PRXRV Refactor Plan

## Goals

This refactor wave addresses the two most immediate sources of architectural friction:

1. **The Pixiv Gateway module is shallow**: `qml/js/pixiv.js` currently mixes auth constants, HTTP transport, error handling, and endpoint routing, so the interface is nearly as complex as the implementation.
2. **The Download seam is fragile**: `RequestMgr` and `PxvRequest` coordinate through a parent cast and incomplete failure signaling, which hurts locality and makes failure paths easy to leak.

The implementation in this phase keeps the existing QML interface stable while tightening the internals and creating cleaner seams for deeper follow-up work.

## Current Design Overview

1. **Application composition module**: `src/harbour-prxrv.cpp` injects `requestMgr`, `cacheMgr`, `Utils`, and `PxvImageProvider` into QML.
2. **Application state module**: `qml/harbour-prxrv.qml` holds tokens, accounts, multiple `ListModel` instances, and cross-page shared state.
3. **Pixiv Gateway module**: `qml/js/pixiv.js` handles login, authenticated requests, feed loading, and bookmark actions.
4. **Download module**: `src/requestmgr.*` and `src/pxvrequest.*` manage download scheduling, progress, and file persistence.
5. **Cache module**: `src/cachemgr.*`, `src/pxvnetworkaccessmanager.*`, and `src/pxvnamfactory.*` manage network and disk caching.

## Target Modules and Seams

### 1. Pixiv Gateway module

- **Current problem**
  - `pixiv.js` currently owns transport, auth, and endpoint policy, which keeps its depth low.
  - Header rules and error modes are scattered, so the test surface sits on top of large functions.
- **Target**
  - Preserve the `Pixiv.*` interface used by pages.
  - Move transport and auth helpers behind dedicated implementation modules.
  - Turn `pixiv.js` into a stable facade so later page refactors do not need to touch transport details.

### 2. Download module

- **Current problem**
  - `PxvRequest` currently forwards progress by casting its parent to `RequestMgr`, so the seam is implicit.
  - Network failures, existing files, and file write failures do not share one cleanup path, which hurts locality.
- **Target**
  - Replace the parent cast with an explicit signal.
  - Route every failure path through one cleanup flow.
  - Keep the `requestMgr` interface unchanged for QML callers.

## Phased Plan

### Phase 1: Tighten the Pixiv Gateway and Download seam

1. Add `qml/js/pixiv-request.js`
   - Own shared headers, query serialization, HTTP sending, and normalized callbacks.
2. Add `qml/js/pixiv-auth.js`
   - Own login, token refresh, authorization-code login, and auth constants.
3. Rewrite `qml/js/pixiv.js`
   - Preserve the existing `Pixiv.*` interface.
   - Delegate implementation details to the new facade helpers.
4. Update `PxvRequest` and `RequestMgr`
   - Let `PxvRequest` emit its own `downloadProgress` signal.
   - Fix mutable path concatenation.
   - Route all failure paths through `saveImageFailed`.

### Phase 2: Extract an AppState module

Move the following state out of `qml/harbour-prxrv.qml`:

- active account
- token lifecycle
- feed model registry
- request lock
- refresh flags

The goal is to reduce the root page from a giant state container into an application composition module.

### Phase 3: Deepen the Feed module

Concentrate pagination and busy-state handling for following, ranking, recommendation, bookmarks, search, and user works into one deep module:

- one pagination interface
- one `requestLock` protocol
- one feed append / replace / refresh behavior

### Phase 4: Deepen the DownloadQueue module

Replace the implicit `cacheCount + prList + filename` protocol with explicit task state:

- task IDs
- a state machine
- failure reasons
- one completion event

## Risks and Rollback

- QML pages still call `Pixiv.*`, so page-level regression risk stays relatively low.
- The C++ download interface exposed to QML does not change, so rollback scope is mostly limited to `PxvRequest` and `RequestMgr`.
- If the Pixiv Gateway helpers introduce compatibility issues, `pixiv.js` can temporarily inline the auth helper again while keeping `pixiv-request.js`.

## Verification Focus

1. Login, token refresh, and authorization-code login must keep returning the same response shape.
2. Following, ranking, search, and bookmarks must keep returning the same JSON payloads through `Pixiv.*`.
3. Download failures must clear the queue so `allImagesSaved` cannot get stuck.
4. Download progress must still update `DownloadsPage.qml`.

## Changes Landed in This Phase

- Added `CONTEXT.md` with the domain glossary.
- Split Pixiv request and auth handling into facade helpers.
- Fixed the implicit parent coupling and incomplete failure cleanup in the download flow.
- Added `qml/js/feed.js` as a shared feed helper for work filtering, item mapping, ranking headers, duplicate suppression, and author icon policy.
- Moved the repeated feed append loops in following, favorites, recommendation, ranking, search, user works, and related works pages behind the shared feed module while preserving page-level state and behavior.
