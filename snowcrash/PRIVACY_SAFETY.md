# Project Snow Crash: Privacy and Safety

*Drafted 11 Oct 2026 from Q5, Q11, Q20, Q21, Q26 and Bit's SAFETY hard line. **This is a design document, not legal advice.** Before shared workspaces go live, the policy parts should be checked by someone who knows UK data protection and online safety law (see §7).*

## 1. Our promises, in plain English

1. **Your PC is yours.** We never monitor, scan or upload anything from your own computer. Solo use is completely offline and private.
2. **Read-only by default.** The free app can look at and open your files, but it cannot change, move or delete them.
3. **We point, we never copy.** Snow Crash shows your files where they already are. It doesn't import, duplicate or upload them.
4. **Guests see nothing until you show them.** Everything is private by default; you open doors one at a time.
5. **Shared spaces are different, and we say so up front.** When you join a shared workspace you're told, before you enter, that it may be recorded and is moderated, and why.
6. **Zero tolerance for child sexual abuse material.** Snow Crash must never be a way to share it. Shared spaces are protected by automated checks, and offenders are reported.

---

## 2. Read-only safety (solo use)

| Area | Rule |
|---|---|
| File writes | None in free mode. All app data lives in the app's own folders, `%APPDATA%\SnowCrash\` (settings, index, resume points) and `%LOCALAPPDATA%\SnowCrash\` (thumbnails). |
| Permissions | Windows permissions always apply (Q20). We run as the normal user, never elevated. Folders we can't read show as locked doors. |
| Thumbnails | Generated into our own cache, never alongside your files (no `Thumbs.db`-style files in your folders). Cache can be cleared in Settings. |
| Launching | Never on pick-up. Confirmation on first launch; extra warning for downloaded files; scripts not runnable by default (TECH_ARCHITECTURE.md §9). |
| Write mode (paid, later) | Recycle Bin instead of permanent delete, undo journal, hold-to-confirm, system folders protected. |
| Network | Solo mode makes **no network calls** by default. Optional online features (box-art lookups, update checks, crash reports) are each off until switched on, and the setting says exactly what is sent. |
| Telemetry | None by default. Opt-in crash reports contain no file names or paths (paths are scrubbed). |
| Screenshots/streaming | Nothing is captured by us. (Users can of course screenshot their own headset; we remind people of this in shared spaces.) |

---

## 3. Guest visibility (Q20, Q21)

### 3.1 The model
- **Owner** (host): sees everything they normally could in Explorer.
- **Guest**: sees **nothing** of the owner's file system by default. They arrive in a neutral **guest lobby** (or the workspace room).
- The owner **opens doors** explicitly: "Share this room with: everyone here / specific people", and chooses **view only** (default) or **view + download** (later, explicitly).

### 3.2 What sharing means technically
- A shared room is shared **as that folder only**, not its parents or siblings. Subfolders are *not* shared unless the owner ticks "include subfolders".
- Guests see only file names, thumbnails and content of shared items. Paths are shown relative to the shared folder (guests never see `C:\Users\Bit\...`).
- Search for guests only covers shared rooms.
- Sharing ends when the owner leaves, or they revoke it (wrist → Sharing → Stop sharing), or after a timeout they choose.
- Hidden items (the owner's hide list) are never shared even inside a shared folder.
- A visible **eye icon** on shared doors and a "You are sharing 2 rooms" banner on the owner's wrist, so nothing is shared by accident.

### 3.3 Defaults that protect people
- Guests can't pick things up into their own bag unless the owner allows downloads.
- Guests can't teleport into unshared areas; the room graph sent to them only contains shared rooms.
- The host can mute, remove or block any guest instantly.

---

## 4. Shared workspaces: consent and recording policy (Q6, Q26)

### 4.1 Before anyone joins
A **join screen** that must be read and accepted, in plain language:

> **This is a shared workspace.**
> - Other people here can see your avatar and hear your voice.
> - Files you put on your desk can be seen by people in this room.
> - **This workspace may be recorded** (what happens in the room: voices, avatars and shared files) to keep people safe and to improve Snow Crash. Recordings are kept for **[30] days**, then deleted, unless they're needed for a safety report.
> - Shared files are automatically checked against known illegal content. Illegal content is blocked and reported to the authorities.
> - [Read the full privacy notice] [Read the rules]
> **[ I understand, join ]** **[ No thanks ]**

Details to get right (UK GDPR):
- **Lawful basis.** Consent under UK GDPR has to be *freely given*; if recording is a condition of joining, consent may not count. A cleaner approach (to confirm with advice): **safety recording on the basis of legitimate interests** (with a written legitimate-interests assessment and clear notice), and **a separate, optional tick-box consent** for using recordings to *improve the product*. Default: unticked.
- **DPIA.** Recording shared spaces counts as systematic monitoring, so a Data Protection Impact Assessment should be written before launch.
- **Transparency.** A recording indicator (red dot) visible to everyone in the room the whole time.
- **Rights.** People can ask for access to or deletion of recordings of themselves (subject to safety-report holds).
- **Retention.** Short by default (suggest 30 days), automatic deletion, and a legal hold only for active reports.
- **Storage.** Encrypted at rest, access logged, limited to Bit (and any named moderators).
- **Age.** Suggest **18+ only** for shared workspaces at first (simpler under the Children's Code and safer); open question for Bit.
- **Host vs project.** Clarify who is the "controller" when a host records their own workspace versus when the project's servers record it.

### 4.2 Recording design
- What gets recorded: room events (who joined/left, which files were placed on desks: their **hashes and names**), voice audio, avatar positions. **We avoid recording the file content itself** where we can (see §5.4: storing illegal images would itself be a problem).
- Workspaces where the host uses their own **cloud folder** (Q6): we don't scan the cloud folder itself; we check files when they're *placed into the shared space*.

---

## 5. Moderation approach (the hard line)

### 5.1 Layers
1. **Terms of use** everyone accepts before using shared spaces: no illegal content, no CSAM (zero tolerance), no harassment, no non-consensual intimate images, no malware.
2. **Design that limits harm:** private by default; small rooms (no 256-person crowds); host controls (mute/kick/block); no anonymous public rooms in v1 (workspaces are invite-only).
3. **Automated checks ("a robot watching over"):**
   - **Hash-matching** of every image/video placed into a shared space against known-CSAM hash lists (PhotoDNA-style perceptual hashes; e.g. via the **IWF Hash List**, **Microsoft PhotoDNA Cloud Service**, or a provider such as **Thorn's Safer**; all need an application/agreement, and some cost money; see OPEN_QUESTIONS.md).
   - Matching happens **before** the file is shown to anyone else. A match blocks the share instantly, ends the session for that user, and triggers the reporting flow.
   - Optional later: AI classifiers for *unknown* abuse material and nudity (high false-positive risk; human review needed and very careful handling).
4. **User reports:** a "Report" button on the wrist and on any avatar/object, with categories.
5. **Human review:** by Bit or trusted moderators, with welfare in mind (exposure to harmful content is distressing; use blurred previews and hash results, never casual viewing).

### 5.2 Reporting illegal content
- **CSAM:** report to the **NCA** (the Online Safety Act includes a duty for in-scope services to report detected CSEA content to the NCA; check commencement status) and/or the **IWF** (UK hotline), and **NCMEC** for US users if relevant. Preserve the minimum evidence required by law and guidance; don't distribute it; don't keep copies beyond what's required.
- **Other illegal activity** (threats, terrorism content, fraud): shut the session down, preserve logs, report to the police where appropriate.
- Report **everyone involved** (Bit's rule): the person who shared it and anyone who knowingly received or requested it, based on logs.

### 5.3 The Online Safety Act (UK)
Shared workspaces and a social lobby make Snow Crash a **user-to-user service** under the Online Safety Act 2023 if UK users can share content with each other. That brings duties even for small services: an **illegal content risk assessment**, proportionate safety measures (Ofcom's codes of practice), a way to report content, a complaints process, and clear terms. Solo mode (no sharing) is not affected. This is a strong reason to **launch workspaces invite-only and small**, and to write the risk assessment before the feature ships.

### 5.4 Careful with "we record everything"
If recordings captured illegal images, holding them could itself be a legal problem. So:
- Record **hashes and metadata** of shared files, not the files.
- Hash-match at the point of sharing, so illegal images are blocked before they spread or get recorded.
- When something must be preserved for a report, follow the authorities' instructions (NCA/IWF) and store it encrypted, access-restricted, and only as long as required.

### 5.5 End-to-end encryption vs moderation
If workspace streams are end-to-end encrypted (good for privacy), the server can't see content. The design that keeps both: **client-side hash-matching at the moment of sharing** (on the sharer's machine, using a hash list, before upload/stream), plus metadata logs. This needs care (hash lists on clients can be extracted and abused), so it's a technical decision for the workspaces phase. Open question.

### 5.6 Content Bit won't allow anywhere (Q25)
The project's rules (code of conduct + content policy) apply to the repository, theme packs listed in any official gallery, and official shared spaces. The maintainer has final say. What users do privately on their own PCs is their own business (and the law's), and we don't monitor it (Q26).

---

## 6. Theme packs and community content
- Official gallery packs are reviewed before listing; packs contain no code (WORLDS.md §6.4).
- Packs must have a licence file; obvious IP violations are not listed.
- Reports on packs go to the maintainer.

## 7. Before workspaces launch: checklist
- [ ] Privacy notice (plain English) + terms of use + code of conduct
- [ ] DPIA and legitimate-interests assessment
- [ ] Online Safety Act illegal content risk assessment
- [ ] Hash-matching provider agreement (IWF / PhotoDNA / Safer)
- [ ] Reporting procedure with NCA/IWF contacts documented; moderator welfare plan
- [ ] Data retention and deletion jobs tested
- [ ] Age policy decided and implemented
- [ ] Short legal review (UK data protection + online safety)
