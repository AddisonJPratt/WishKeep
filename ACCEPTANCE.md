# Wishkeep ACCEPTANCE.md

## ✅ Acceptance Criteria

### 1. Capture & Import
- [ ] When I take a screenshot, Wishkeep detects it and shows it in Inbox within 10 seconds.
- [ ] OCR extracts visible text and displays it in a Bubbles or Transcript view.
- [ ] If a message ends with ellipsis (`…`), it is marked `isTruncated = true`.
- [ ] If I copy text and tap **Save Clipboard**, a new note appears instantly in Inbox.
- [ ] Clipboard text is stored accurately without modification.

### 2. Mixed Capture Upgrade
- [ ] If a truncated screenshot and a matching clipboard text exist within 10 minutes, the app merges them.
- [ ] The final note keeps the screenshot as its cover and uses clipboard text as the transcript.
- [ ] The note shows capture type as **Mixed**.

### 3. Manual Naming
- [ ] Each conversation can be manually renamed in the Inbox.
- [ ] Renamed conversations retain their name and are never auto-overwritten.

### 4. Viewing Modes
- [ ] Each note opens in 3 tabs: **Bubbles**, **Transcript**, **Reflection**.
- [ ] The Bubbles tab correctly renders left/right alignment for ≥70% of OCR lines.
- [ ] If alignment confidence < 70%, the note defaults to Transcript view.
- [ ] Reflection input autosaves locally.

### 5. Privacy
- [ ] App only reads clipboard content after explicit user action (Save Clipboard).
- [ ] No background clipboard reads or uploads.

### 6. Stability
- [ ] All data is stored locally using Core Data.
- [ ] Notes persist after app restart.
- [ ] Multiple screenshots from the same thread within 90 seconds are grouped into one conversation.

---

## 🧪 QA Checks
| Area | Test | Expected |
|------|------|-----------|
| Screenshot Import | Take screenshot | Appears in Inbox ≤10s |
| Clipboard Save | Copy + Save Clipboard | Appears instantly |
| Mixed Upgrade | Screenshot (truncated) → Copy (full text) | Merges to one note |
| Naming | Rename contact | Persists |
| OCR Bubbles | Check chat alignment | 70%+ accuracy |
| Privacy | Open app w/o clipboard | No privacy banner |
| Restart | Force quit + reopen | Notes persist |

---

## 💡 MVP Success Definition
Wishkeep successfully allows users to:
- Save meaningful messages through either screenshots or copy/paste.
- Read and relive them through a beautiful chat-like interface.
- Organize memories manually with names.
- Keep everything private, offline, and emotionally resonant.

> *“Your words, kept beautifully.”*
