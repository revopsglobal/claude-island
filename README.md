<div align="center">
  <img src="ClaudeIsland/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" alt="Logo" width="100" height="100">
  <h3 align="center">Claude Island: Sheldon Edition</h3>
  <p align="center">
    A fork of <a href="https://github.com/farouqaldori/claude-island">Claude Island</a> that replaces the crab with a pixel-art turtle named Sheldon.
    <br />
    Same great Dynamic Island notifications for Claude Code, now with a living, reactive companion.
  </p>
</div>

<br />

<div align="center">
  <img src="docs/assets/sheldon_showcase_walk.gif" alt="Sheldon walking across the notch at night" />
  <br />
  <em>Sheldon on his grass island at night, with twinkling stars and his flower</em>
</div>

<br />

> The crab is great. We totally get why people love it. But we're turtle people. If you are too, this fork is for you.

---

## What's Different

This fork keeps all of Claude Island's core functionality (session monitoring, permission approvals, chat history, auto-setup) and adds a character layer on top.

### Sheldon the Turtle

A pixel-art turtle who lives on a grass island spanning both sides of the notch. He's not decoration. He reacts to what Claude is doing.

- **Walks** back and forth when Claude is processing, disappearing behind the notch and reappearing on the other side
- **Eats a flower** that regrows, replacing the processing spinner with something you actually want to watch
- **Follows your cursor** when idle, turning to face the mouse when it's near the notch
- **Sleeps** when no sessions are active (legs retract, eyes close, gentle breathing)
- **Blinks, fidgets, and stretches** with idle animations that make him feel alive
- **Click him** to make him spin

<div align="center">
  <img src="docs/assets/sheldon_hero.png" alt="Sheldon near his flower at night" />
  <br />
  <em>Sheldon approaching his flower on a starry night</em>
</div>

### 7-Emotion System

Sheldon's mood changes based on what's happening in your Claude sessions:

| Emotion | Trigger | Visual |
|---------|---------|--------|
| Happy | Task completed | Bright green shell, warm sky |
| Sad | Errors | Muted blue-grey shell, cool tones |
| Excited | Milestones | Golden shell, vibrant sky |
| Confused | Retries | Purple-grey shell |
| Curious | Research/exploration | Blue-tinted shell |
| Sob | Repeated failures | Dark muted tones |
| Neutral | Default | Standard green |

Emotions decay quickly so they feel like reactions, not permanent moods.

### Sunrise/Sunset Cycle

Real astronomical sunrise and sunset times drive the day/night cycle. No hardcoded hours.

- **Day:** Blue sky, clouds, butterflies
- **Dawn/Dusk:** 75-minute gradual transitions
- **Night:** Dark sky, twinkling stars, moon, fireflies
- Sheldon puts on a **nightcap** at midnight

### Spinach Treat

Say "feed Sheldon" or "Sheldon's hungry" in Claude Code. A spinach bowl appears. Sheldon walks over, eats the leaves one by one with an excited tail wag, then does happy hops with sparkles.

### Environmental Details

The island is alive beyond Sheldon:

- Seasonal particles, shooting stars, rainbows
- Birds, worms, snails, mushrooms
- Rain with puddles
- Campfire warmth
- Music notes (when connected to audio)
- **Hats:** nightcap (midnight), santa (December), party hat (milestones), top hat (New Year)

### Other Improvements

- **Permission bounce:** Sheldon bounces when approval is needed, so you notice it
- **AskUserQuestion auto-open:** Notch opens automatically and navigates to the chat when Claude asks a question (submitted as [upstream PR #88](https://github.com/farouqaldori/claude-island/pull/88))
- **Better hit targets:** Allow/Deny buttons are easier to click
- **Mixpanel removed:** No analytics, no TCC permission dialogs

---

## Install

Download from [releases](https://github.com/revopsglobal/claude-island/releases) or build from source:

```bash
xcodebuild -scheme ClaudeIsland -configuration Release build
```

### Requirements

- macOS 15.6+
- Claude Code CLI

## How It Works

Same as upstream Claude Island: hooks in `~/.claude/hooks/` communicate session state via a Unix socket. The app listens for events and displays them in the notch overlay. Sheldon's behavior layer reads the same events to drive animations and emotions.

## Credits

Built on top of [farouqaldori/claude-island](https://github.com/farouqaldori/claude-island). All the hard work on session monitoring, hook architecture, and the notch UI is theirs. We just added a turtle.

## License

Apache 2.0
