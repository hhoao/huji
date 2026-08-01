# Task list 「查看」 action alignment

## Problem

Desktop completed rows show a 「查看」 button that calls `handleTaskTap`, but many task types are no-ops (download, upload, missing output). Mobile has no 「查看」 control — only row tap — and completed rows only expose delete.

## Goals

1. Show 「查看」 only when the task has a viewable result.
2. `handleTaskTap` opens the result for every viewable type; missing files get a SnackBar.
3. Mobile completed/failed action chrome matches desktop action set (view + delete, etc.).

## Viewable results

| Type | View when | Opens |
|------|-----------|--------|
| VideoCompress | completed + non-empty `outputPath` | video player; missing file → SnackBar |
| VideoClip | completed (always) | desktop: preview `/clip/:id/preview`; mobile: RoundClip (or player if `outputPath`) |
| ImageCompress | completed + non-empty `outputList` | existing results sheet |
| VideoSegmentDetect | completed + non-null `edittingRecordId` | RoundClip; else SnackBar |
| Download | completed + non-empty `savePath` | `OpenFile.open`; missing file → SnackBar |
| VideoUpload | never | no 「查看」 |

Notes:
- Desktop local detection finishes as `VideoClipTask` with empty `outputPath` and an `EdittingVideoRecord` with the same id.
- Remote `outputPath` URLs open the network video player (no local `File.exists` check).

`viewProgress` (in-progress / failed clip without output) stays separate from `view`.

## UI

- Desktop: keep text 「查看」; gate via `canViewTaskResult`.
- Mobile: build action icons from `resolveTaskActions` (view = visibility icon → `onTap`).

## Non-goals

- Opening a destination for completed upload tasks.
- Changing batch-mode chrome.
