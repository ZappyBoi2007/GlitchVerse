# GlitchVerse audio integration

## Current asset status

The repository contained no WAV, OGG, MP3, or FLAC assets when this foundation was added. No files were downloaded and no third-party or copyrighted game audio is included.

`audio/audio_manager.gd` currently generates small mono `AudioStreamWAV` tones/noise at runtime. They are functional synthesized placeholders, not premium final assets. Replace individual registered event streams with selected licensed files later; retain the event names so gameplay and UI callers do not change.

Approved future sources from the project brief include Kenney's CC0 Sci-Fi Sounds, Interface Sounds, RPG Audio, and Impact Sounds packs. When real files are added, place them under `res://audio/assets/`, include the pack name/source URL/license text, and record each used filename here.

## Audio buses

`default_bus_layout.tres` defines:

| Bus | Purpose | Default |
| --- | --- | --- |
| Master | Overall output | 0 dB |
| Music | Musical atmosphere and score loops | -12 dB |
| Ambience | Environmental loops and machinery beds | -10 dB |
| SFX | Abilities, movement, world reactions and stingers | -5 dB |
| UI | Hover/click/confirm/back/error | -6 dB |
| Voice | Future operator dialogue | -6 dB |

All child buses send to Master. The manager also creates missing buses defensively for test tools or unusual editor startup states.

## Runtime architecture

`AudioManager` is a project autoload. It automatically discovers and binds existing `RealityDebugger`, `PhaseableBarrier`, `GravityCrate`, `FreezableHazard`, and `GameFlowManager` instances through their verified signals. It does not own puzzle, player, or progression state.

One-shots are capped and free themselves when finished. World loops are keyed by owner and purpose, so duplicate requests reuse the existing player. Loops are children of their world object and disappear with it. Level loading also clears active world sounds, preventing audio from a replaced scene continuing into the next scene.

The player scene has a small observer component. Footsteps accumulate actual horizontal distance while grounded, with different walking/sprinting spacing and pitch variation. Jump and landing cues use real floor transitions and impact velocity. The component never moves the player or reads a standalone cadence timer.

## Public event API

```gdscript
AudioManager.play_sfx(&"event_name", volume_db, pitch_scale)
AudioManager.play_3d(&"event_name", global_position, volume_db, pitch_scale, max_distance)
AudioManager.start_world_loop(owner_node_3d, &"slot", &"event_name", volume_db)
AudioManager.stop_world_loop(owner_node_3d, &"slot")
AudioManager.play_voice(stream, volume_db)
AudioManager.register_event(&"custom_event", stream)
```

Supported built-in categories include ability activation/reversal, invalid targeting, footsteps/jump/landing, puzzle/exit/level/failure/restart/victory cues, UI cues, machinery loops, and four atmosphere profiles.

## UI integration for Anushree

No UI scene is modified. Buttons can call:

```gdscript
AudioManager.play_ui_cue(&"hover")
AudioManager.play_ui_cue(&"click")
AudioManager.play_ui_cue(&"confirm")
AudioManager.play_ui_cue(&"back")
AudioManager.play_ui_cue(&"error")
```

Volume sliders use normalized values from 0 to 1:

```gdscript
AudioManager.set_bus_volume(&"Master", value)
AudioManager.set_bus_volume(&"Music", value)
AudioManager.set_bus_volume(&"Ambience", value)
AudioManager.set_bus_volume(&"SFX", value)
AudioManager.set_bus_volume(&"Voice", value)
```

Use `get_bus_volume(bus_name)` to initialize sliders. The UI bus is also available if the final settings design exposes it. Persistence is not implemented; Anushree can save normalized values in the final settings system.

## Gameplay event mapping

- **PHASE on:** digital glitch + mechanical response; stronger spatial energy loop.
- **PHASE off:** upward restoration response; quiet idle instability loop.
- **GRAVITY inverted:** low pulse + rising whoosh + restrained electrical hum.
- **GRAVITY normal:** hum stops and a falling restoration cue plays.
- **FREEZE:** sharp interruption + clock glitch; hazard rhythm stops.
- **FREEZE resumed:** mechanical restart cue and hazard rhythm resumes.
- **Invalid interaction:** quiet non-positional chirp, limited to one every 300 ms.
- **Movement:** grounded distance-based steps, jump transition, impact-scaled landing.
- **Flow:** puzzle complete, exit unlocked, level complete, failure, same-level reload/restart, and once-per-run final victory.

## Atmosphere profiles

`set_atmosphere_profile()` crossfades the Music and Ambience players. `GameFlowManager.level_started` selects profiles by registered index:

- `level_1`: controlled research hum.
- `level_2`: low gravity-instability drone.
- `level_3`: gated clock-like tension.
- `level_4`: pulsing emergency machinery.

These are exposed now without editing final level scenes. If the final level order changes, the integrator can explicitly call the desired profile from a level or add a profile field to the shared level contract later.

## Level integration for Jefin

Existing reusable PHASE, GRAVITY, and FREEZE scenes need no audio setup. Their signals are discovered automatically. For extra machinery:

```gdscript
AudioManager.start_world_loop($Machine, &"motor", &"hazard_loop", -20.0, 18.0)
# Later:
AudioManager.stop_world_loop($Machine, &"motor")
```

Keep looping sources sparse, give each owner/slot pair a stable purpose, and use realistic attenuation distances. Do not place non-positional ambience players inside every level; use the shared atmosphere controller.

## Replacing placeholders

Import licensed WAV/OGG files, then register them during audio-manager initialization or replace entries in `_build_placeholder_streams()`. Prefer mono for positional sounds and stereo only for music/ambience/UI where spatialization is not required. Normalize source files conservatively and keep bus headroom rather than making every asset loud.

## Manual audio QA checklist

Headless checks cannot verify actual listening quality. Test with speakers and headphones:

1. Start F5 and confirm ambience fades in without a loud click.
2. Walk, sprint, stop, jump, fall and land. Confirm no airborne/stationary footsteps and no machine-gun cadence against walls.
3. Trigger and reverse each ability. Confirm its loop starts/stops once and positional attenuation is obvious.
4. Spam an invalid target and confirm the chirp is rate-limited and quiet.
5. Solve the chamber and verify puzzle, exit, completion and victory cues do not repeat.
6. Press R and transition/reload scenes. Confirm old object loops stop and the restart cue plays once.
7. Run NULL SPINDLE and listen from the observation corridor and lower maintenance route for excessive overlapping hums.
8. Move every settings slider through 0–100%, including mute, and confirm important SFX remain intelligible beneath music.
9. Test at low system volume for missing cues and high system volume for clipping/fatigue.
10. Replace synthesized placeholders with licensed assets before describing the audio as final or premium.
