# iOS SSH App Market Research Report
**Date:** 2026-03-27
**Purpose:** Competitive analysis of iOS SSH clients to inform building a new SSH app

---

## Executive Summary

The iOS SSH client market has approximately 10-15 active players, with Termius, Blink Shell, and Prompt 3 dominating mindshare among power users. The market is characterized by **universal frustration with subscription pricing**, **poor touchscreen UX**, and **iOS background execution limitations**. There is a clear opportunity for a well-designed app that combines a fair pricing model with excellent touch-optimized UX and modern protocol support (Mosh/Eternal Terminal).

---

## Individual App Analysis

### 1. Termius - SSH & SFTP Client
- **Rating:** ~4.5/5 (App Store)
- **Pricing:** Free tier (limited) / $10-15/month subscription
- **Platform:** Cross-platform (iOS, Android, Mac, Windows, Linux)

**What Users Love:**
- Cross-platform sync across all devices
- Clean, polished UI for beginners
- Identity management and key generation in free tier
- Port forwarding support
- AI command generation (natural language to CLI)

**What Users Hate:**
- SFTP locked behind $10/mo paywall -- the #1 complaint
- Free plan restricted to one device; upgrading deletes connections on other devices
- $120/year feels excessive for an SSH client
- No one-time purchase option
- Blank screen bugs after login (unresolved for months)
- Keyboard/arrow key issues on iPad with external keyboards
- Settings/connections lost on Linux updates
- Port forwarding dies in background after free trial expires
- Customer support response times of weeks to months
- No ~/.ssh config access (everything in proprietary UI)

**Key Insight:** Termius is the most popular but also the most resented due to its aggressive paywall. Users would pay $59-99 one-time but refuse $120/year.

---

### 2. Blink Shell
- **Rating:** 3.09/5 (dropped from ~4.5 after subscription switch)
- **Pricing:** $19.99/year (was one-time ~$20 purchase)
- **Platform:** iOS/iPadOS/macOS only

**What Users Love:**
- Best Mosh implementation on iOS
- Sessions survive network switches, sleep, subway tunnels
- Professional-grade terminal emulation
- Open source (community trust)
- Customizable and powerful for advanced users

**What Users Hate:**
- Subscription switch from one-time purchase caused massive backlash ("scam", "fraud", "bait and switch")
- SSH keys from Secure Enclave don't save .pub files properly
- No command aliases support
- Missing core local utilities (ssh-keygen, nano, scp, vim)
- ~/.ssh/config editing buried in UI menus, not accessible from terminal
- Blink Code / Blink Build features diluted the core SSH tool
- Developer acknowledged "zigzagging" in product direction

**Key Insight:** Blink has the best technical foundation but alienated its user base with pricing changes and loss of focus. Users feel it stopped being a "serious tool for Linux administrators."

---

### 3. Prompt 3 (by Panic)
- **Rating:** ~4.5/5 (mixed due to pricing controversy)
- **Pricing:** $19.99/year OR $99 one-time (lifetime)
- **Platform:** iOS/iPadOS/macOS (native)

**What Users Love:**
- 100% native app -- extremely fast and responsive
- Text engine up to 10x faster with GPU acceleration
- Mosh + Eternal Terminal + SSH support
- Jump hosts and port forwarding
- YubiKey and Secure Enclave authentication
- Excellent iPadOS multitasking
- Very configurable iOS keyboard that "makes touchscreen typing fun"
- Running nvim inside tmux "feels as responsive as a local machine"
- Profile syncing across devices

**What Users Hate:**
- $99 lifetime price is "10x the price of Prompt 2"
- Prompt 2 was removed from sale, forcing upgrade
- Concerns about Panic's track record for long-term maintenance
- Transmit iOS (SFTP companion) was discontinued entirely
- Not justified for occasional/light SSH users

**Key Insight:** Prompt 3 is arguably the best technical product but the $99 one-time / $20/year pricing and Panic's history of discontinuing iOS apps creates trust issues.

---

### 4. Shelly - SSH Client
- **Rating:** 4.4/5
- **Pricing:** $12.99 one-time purchase
- **Platform:** iOS/iPadOS

**What Users Love:**
- One-time purchase (no subscription)
- Hardware-accelerated text rendering (PuTTY engine)
- Clean interface with finger-slide cursor movement
- Customizable key row at bottom
- RSA key authentication support
- Best convergence of "utility, simplicity, and value"
- Long-term users prefer it over Termius and Prompt 3

**What Users Hate:**
- Split-screen multitasking locks text input to Shelly
- Keyboard profile saves/renames get overwritten
- Auto-hide toolbar option unreliable with hardware keyboard
- Lacks Mosh support
- No background connection notifications
- Missing advanced features expected on iPad Pro

**Key Insight:** Shelly occupies a strong niche as the "affordable, simple, just-works" option. Its one-time pricing is a major differentiator.

---

### 5. Secure ShellFish (formerly SSH Files)
- **Rating:** ~4.7/5
- **Pricing:** Free with optional IAP to unlock full features
- **Platform:** iOS/iPadOS/macOS

**What Users Love:**
- Deep integration with Apple's Files app (SFTP servers appear as file sources)
- Built-in tmux support for session persistence
- iCloud Keychain sync for server settings
- Drag-and-drop files between terminal and other apps
- Developer is "super responsive" to issues
- Simple and convenient

**What Users Hate:**
- Occasional IAP unlocking required
- Less full-featured as a terminal compared to dedicated SSH apps
- More focused on file management than terminal use

**Key Insight:** Unique positioning as the "Files.app integration" SSH/SFTP tool. Shows that Apple ecosystem integration is highly valued.

---

### 6. WebSSH
- **Rating:** ~4.0/5 (declining)
- **Pricing:** $3.99 IAP to save more than one connection
- **Platform:** iOS/iPadOS

**What Users Love:**
- Clutter-free and fully-featured
- No cloud account required
- No ads in paid version
- Low price
- Developer historically responsive to feedback

**What Users Hate:**
- Background sessions terminate after ~60 seconds
- Screen freezes unpredictably, blocking keyboard input
- Copy/paste is "very wonky" and can freeze input
- Corrupts active sessions, leaving orphan TTYs on remote servers
- Perception of being abandoned (though updates continued)

**Key Insight:** WebSSH shows what happens when fundamental reliability issues go unfixed -- even a cheap, simple app loses trust.

---

### 7. ServerCat
- **Rating:** 4.6/5
- **Pricing:** Freemium with premium IAP
- **Platform:** iOS/iPadOS/macOS

**What Users Love:**
- Server monitoring + SSH in one app
- Docker container management
- Great design and quick access to system status
- Process list and performance graphs
- Works well across macOS and iOS

**What Users Hate:**
- iPad only supports portrait mode (terrible with keyboard in landscape)
- VPN disconnect/reconnect breaks SSH connections ungracefully
- Slow sync between devices
- Crashes on macOS after reboot
- No Mosh support
- Missing iOS widgets for quick server status

**Key Insight:** ServerCat proves that combining monitoring + SSH is a winning formula for the self-hosted/sysadmin audience. The portrait-only iPad limitation is a major miss.

---

### 8. Notable Newer Entrants

#### Termix (2025-2026)
- **Rating:** 4.9/5
- **Pricing:** ~$10 lifetime license
- **Highlights:** "Absolutely perfect rendering," neovim pixel-accuracy, split-screen, 40+ language syntax highlighting, serverless/encrypted iCloud storage
- **Gaps:** No Mosh support, no full-screen with external keyboard, missing keyboard copy/paste

#### NeoServer (2024-2025)
- **Rating:** 4.74/5
- **Pricing:** Freemium with affordable premium
- **Highlights:** Best free feature set, Docker/SFTP/SSH in one app, iCloud sync, FaceID, zero data collection, popular with NAS/self-hosting community

#### Echo by Replay Software (2025-2026)
- **Rating:** New/high
- **Pricing:** $2.99 one-time purchase
- **Highlights:** Built on Ghostty terminal engine, Mosh + SSH, session state persistence across backgrounding, AI agent support, touch-optimized toolbar, minimal and beautiful
- **Gaps:** Very new, limited feature set

#### Moshi (2025-2026)
- **Positioning:** "SSH Terminal for Claude Code & AI Agents"
- **Highlights:** Targeting the AI-assisted development workflow

---

## Cross-App Pattern Analysis

### Top 5 Pain Points (by frequency across all apps)

| Rank | Pain Point | Affected Apps |
|------|-----------|---------------|
| 1 | **Subscription pricing resentment** | Termius, Blink, Prompt 3 |
| 2 | **iOS background execution kills sessions** | All apps (~3 min limit) |
| 3 | **Keyboard/input issues** (external keyboard bugs, missing keys, toolbar problems) | Termius, Shelly, WebSSH, Termix |
| 4 | **Sync/connection data loss** | Termius, Blink, ServerCat |
| 5 | **Copy/paste broken or unreliable** | WebSSH, Blink, multiple |

### Top 5 Valued Features (by user praise frequency)

| Rank | Feature | Best Implementation |
|------|---------|-------------------|
| 1 | **Mosh support** (session persistence over unreliable networks) | Blink, Prompt 3, Echo |
| 2 | **One-time purchase pricing** | Shelly, Echo, Termix |
| 3 | **Fast/accurate terminal rendering** | Prompt 3, Termix, Echo (Ghostty) |
| 4 | **Touch-optimized keyboard toolbar** | Prompt 3, Shelly, Echo |
| 5 | **Cross-device sync via iCloud** | NeoServer, Secure ShellFish, Termix |

### Pricing Model Analysis

| Model | Apps | User Sentiment |
|-------|------|---------------|
| Subscription only | Termius ($10-15/mo) | Very negative |
| Subscription + lifetime option | Prompt 3 ($20/yr or $99), Blink ($20/yr) | Mixed (lifetime appreciated) |
| One-time purchase | Shelly ($13), Termix ($10), Echo ($3) | Very positive |
| Freemium with IAP | NeoServer, ServerCat, WebSSH, Secure ShellFish | Positive if free tier is generous |

**Conclusion:** Users overwhelmingly prefer one-time purchase or generous freemium. The $10-15 range for a one-time purchase is the sweet spot. Subscriptions above $20/year face significant resistance unless the app is used professionally.

---

## Opportunities for a New SSH App

### Underserved Needs

1. **Fair pricing with full features** -- A $10-15 one-time purchase that includes SFTP, key management, and Mosh would immediately differentiate. No artificial feature gating.

2. **Reliable background session handling** -- Mosh + intelligent session state capture (like Echo's approach) + Live Activities for connection status. This is the #1 technical challenge on iOS.

3. **First-class iPad + external keyboard experience** -- Landscape mode, proper arrow key handling, customizable toolbar that auto-hides correctly, full keyboard shortcut support. Multiple apps fail here.

4. **Transparent ~/.ssh/config support** -- Power users want to edit their config files directly, not through proprietary UIs. Import/export of standard SSH configs.

5. **Server monitoring + SSH combined** -- ServerCat proves this works but has UX limitations. Combining monitoring dashboards with a proper terminal is underserved.

6. **AI-assisted terminal** -- Natural language to commands (Termius started this), AI agent compatibility (Echo/Moshi targeting this). Emerging differentiator.

7. **Apple ecosystem integration** -- Files.app integration (like Secure ShellFish), Shortcuts/automation support, Widgets for server status, iCloud Keychain for keys.

8. **Reliable copy/paste and text selection** -- Surprisingly broken across many apps. Getting this right is a basic hygiene factor.

### Competitive Positioning Options

**Option A: "The Honest SSH Client"**
- One-time purchase, $9.99-14.99
- All features included (no tiers)
- Mosh + SSH + SFTP
- Great keyboard UX
- Target: sysadmins and developers frustrated with subscriptions

**Option B: "The Server Companion"**
- Freemium with generous free tier
- SSH terminal + server monitoring + Docker management
- NeoServer/ServerCat competitor with better iPad UX
- Target: self-hosters and NAS users

**Option C: "The AI-Native Terminal"**
- AI command generation + agent support
- Modern protocol stack (Mosh, ET, SSH)
- Built on fast engine (Ghostty-class)
- Target: developers using AI coding tools on mobile

### Technical Recommendations

1. **Terminal engine:** Use or port Ghostty (proven fast and correct) or build on libvterm
2. **Protocol support:** SSH + Mosh + Eternal Terminal from day one
3. **Key management:** Secure Enclave + iCloud Keychain + FIDO2/YubiKey
4. **Background handling:** Mosh for persistence + iOS Live Activities for status + full state capture on backgrounding
5. **Rendering:** GPU-accelerated, pixel-perfect terminal rendering
6. **File transfer:** Built-in SFTP with Files.app provider extension

---

## Source Summary

Primary data gathered from: App Store reviews, Reddit (r/sysadmin, r/selfhosted, r/ipad), Hacker News discussions, GitHub Issues/Discussions, Trustpilot, Capterra, G2, SourceForge reviews, MacStories reviews, and developer blogs.

---

## Sources

- [Geekflare: 9 Best Terminals/SSH Apps for iPad and iPhone](https://geekflare.com/dev/best-terminals-ssh-apps/)
- [Termius Reviews - Capterra](https://www.capterra.com/p/234457/Termius/reviews/)
- [Termius Reviews - Trustpilot](https://www.trustpilot.com/review/termius.com)
- [Termius Reviews - JustUseApp](https://justuseapp.com/en/app/549039908/termius-terminal-ssh-client/reviews)
- [Termius Complaints - ComplaintsBoard](https://www.complaintsboard.com/termius-b149183)
- [Blink Shell Alternatives After Subscription Switch](https://getmoshi.app/articles/blink-shell-alternatives)
- [Blink Shell GitHub Discussion: Has it stopped being serious?](https://github.com/blinksh/blink/discussions/2114)
- [Blink Shell - SaaSHub Reviews](https://www.saashub.com/blink-shell)
- [Prompt 3 - Panic Blog](https://blog.panic.com/introducing-prompt-3-now-on-all-of-your-devices/)
- [Prompt 3 - Michael Tsai Blog](https://mjtsai.com/blog/2024/01/19/prompt-3/)
- [Prompt 3 - App Store](https://apps.apple.com/us/app/prompt-3/id1594420480)
- [Shelly SSH Client - App Store](https://apps.apple.com/us/app/shelly-ssh-client/id989642999)
- [Shelly Reviews - JustUseApp](https://justuseapp.com/en/app/989642999/shelly-ssh-client/reviews)
- [ServerCat - App Store](https://apps.apple.com/us/app/servercat-ssh-terminal/id1501532023)
- [ServerCat Reviews - JustUseApp](https://justuseapp.com/en/app/1501532023/servercat-linux-status-ssh/reviews)
- [ServerCat: Top 5 iOS SSH Clients 2024](https://servercat.app/en/posts/Top-5-Most-Popular-iOS-SSH-Clients-in-2024)
- [WebSSH Reviews - JustUseApp](https://justuseapp.com/en/app/497714887/webssh-ssh-client/reviews)
- [WebSSH - App Store](https://apps.apple.com/us/app/webssh-ssh-sftp-tools/id497714887)
- [Secure ShellFish Review - MacStories](https://www.macstories.net/reviews/secure-shellfish-review-adding-your-mac-or-another-ssh-or-sftp-server-to-apples-files-app/)
- [NeoServer - App Store](https://apps.apple.com/us/app/neoserver-ssh-client-terminal/id6448362669)
- [NeoServer - Best SSH/Docker/SFTP App](https://www.joyk.com/en/app/neoserver.html)
- [Termix - App Store](https://apps.apple.com/us/app/termix-ssh-client-terminal/id6739386670)
- [Echo - Replay Software](https://replay.software/echo)
- [Echo - App Store](https://apps.apple.com/us/app/echo-ssh-mosh-client/id6758669847)
- [Free SSH Apps for iOS - Harvard](https://hea-www.harvard.edu/~fine/opinions/ios_ssh.html)
- [Termius vs Blink - StackShare](https://stackshare.io/stackups/blink-vs-termius)
- [Termius vs Blink - SaaSHub](https://www.saashub.com/compare-termius-vs-blink-shell)
- [La Terminal - SSH Client](https://la-terminal.net/)
- [Termius Blog: New Touch Terminal on iOS](https://termius.com/blog/new-touch-terminal-on-ios)
- [Shelly vs Terminus - MeepingBlog](https://meepingblog.com/tech/apps/shelly-vs-terminus-app-review/)
