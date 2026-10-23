# Jefin Level 3/4 production environment handoff

## Ownership and status

- Branch: `feature/jefin-level3-4`
- Base: `origin/main` at `51bafd98c86b63f5a10628ff11fbf6548d08d252`
- Level 3 environment: `res://levels/clock_failure_environment.tscn`
- Level 4 environment: `res://levels/kernel_panic_environment.tscn`
- Both scenes are native, editable Godot geometry with no attached gameplay script, player, enemy, ability controller, UI, or GameFlow node.
- Keith's gameplay scenes and scripts under `res://levels/clock_failure/` and `res://levels/kernel_panic/` are unchanged.

## Integration blocker

The current `ClockFailureLevel` and `KernelPanicLevel` scripts build their existing greybox geometry procedurally in `_build_environment()`. They do not instance these new production environment scenes. Keith must instance the matching environment scene and retire or suppress the overlapping procedural geometry before production integration. Runtime interactables should be placed at the environment's `InteractionMarkers` transforms.

Do not instance the production environment while retaining the complete procedural greybox; doing so will duplicate floors, walls, lights, collision, labels, and landmarks.

## Level 3 — CLOCK FAILURE

### Objective flow

1. Spawn in the Entry Control Room and read the timing-restoration objective.
2. Enter the Timing Chamber and traverse the broken machine decks with TETHER.
3. Use REWIRE in the Power Routing Room to disable the timing hazard and open the blocked route.
4. Fight one Security Construct and restore Sync A followed by Sync B.
5. Enter the opened sector exit.

### Areas

- `Environment/EntryControlRoom`
- `Environment/TimingChamber`
- `Environment/PowerRoutingRoom`
- `Environment/SecurityInterception`
- `Environment/ExitChamber`

The route uses collision-enabled connector floors between all five areas. VECTOR RUN is optional; no required surface group or script is authored.

### Marker NodePaths and positions

All paths are relative to `ClockFailureEnvironment`.

| NodePath | Position | Purpose |
|---|---:|---|
| `InteractionMarkers/PlayerSpawn` | `(0, 0.4, 35)` | Safe first-person spawn, facing progression |
| `InteractionMarkers/EntryObjectiveMarker` | `(0, 1.2, 33)` | Objective-display reference |
| `InteractionMarkers/TetherLaunch_01` | `(0, 0.4, 19)` | First timing-chamber launch |
| `InteractionMarkers/TetherAnchor_01` | `(-3.5, 7, 16)` | Cyan first anchor |
| `InteractionMarkers/TetherIntermediateLanding` | `(-6, 0.4, 12)` | First landing/recovery deck |
| `InteractionMarkers/TetherLaunch_02` | `(-4, 1.9, 10)` | Second launch |
| `InteractionMarkers/TetherAnchor_02` | `(4.5, 8.5, 8)` | Amber second anchor |
| `InteractionMarkers/TetherLanding_02` | `(5.5, 1.9, 8)` | Raised destination deck |
| `InteractionMarkers/FallRecoveryMarker` | `(0, 0.4, 20)` | Recovery position before broken route |
| `InteractionMarkers/TimingHazard_Marker_01` | `(-2, 1.2, 13)` | Timed-hazard placement reference |
| `InteractionMarkers/TimingHazard_Marker_02` | `(2, 1.2, 9)` | Second hazard placement reference |
| `InteractionMarkers/PowerConsole_Marker` | `(0, 0.4, -2.8)` | REWIRE console placement |
| `InteractionMarkers/BlockedRoute_Marker` | `(7, 1.2, -6)` | Powered route blocker reference |
| `InteractionMarkers/SecurityConstructSpawn` | `(0, 0.4, -18)` | Single combat spawn |
| `InteractionMarkers/SyncTerminalA_Marker` | `(-5, 0.4, -21)` | Sync A placement |
| `InteractionMarkers/SyncTerminalB_Marker` | `(5, 0.4, -21)` | Sync B placement |
| `InteractionMarkers/ExitMarker` | `(0, 0.4, -35.3)` | CampaignExit placement |

### TETHER measurements

Keith's current `GrappleController` exposes a 22 m maximum target range and maximum rope length. Straight-line environment distances are:

- Launch 1 to Anchor 1: approximately **8.05 m**.
- Anchor 1 to intermediate landing: approximately **8.11 m**.
- Launch 2 to Anchor 2: approximately **10.95 m**.
- Anchor 2 to destination landing: approximately **6.68 m**.

These fit the configured range. Release arcs, aim visibility, momentum, and landing comfort still require a human playtest with the real controller.

### REWIRE and visual states

Initial state:

- Show `Environment/PowerRoutingRoom/StateVisuals/ChannelA_Active`.
- Hide `Environment/PowerRoutingRoom/StateVisuals/ChannelA_Inactive`.
- Hide `Environment/PowerRoutingRoom/StateVisuals/ChannelB_Active`.
- Show `Environment/PowerRoutingRoom/StateVisuals/ChannelB_Inactive`.
- Show `Environment/PowerRoutingRoom/StateVisuals/TimingHazard_Active`; it has collision enabled.
- Hide `Environment/PowerRoutingRoom/StateVisuals/TimingHazard_Disabled`.
- Show `Environment/PowerRoutingRoom/StateVisuals/BlockedRoute_Locked`; it has collision enabled.
- Hide `Environment/PowerRoutingRoom/StateVisuals/BlockedRoute_Open`.

Rerouted state:

- Swap Channel A to inactive and Channel B to active.
- Hide and disable collision on `TimingHazard_Active`; show `TimingHazard_Disabled`.
- Hide and disable collision on `BlockedRoute_Locked`; show `BlockedRoute_Open`.

Visibility alone does not disable CSG collision. Keith must change `use_collision` or replace the blocking state with a controlled collision node.

### Exit states

- Locked collision: `Environment/ExitChamber/ExitDoorStates/Exit_Locked`.
- Open visuals: `Exit_OpenLeft`, `Exit_OpenRight`, and `Exit_OpenGlow` under the same parent.
- When unlocked, hide and disable collision on `Exit_Locked`, then show the three open-state nodes.

## Level 4 — KERNEL PANIC

### Objective flow

1. Spawn with a direct mission prompt and core-sector sightline.
2. Use POLARITY placement targets to form the gravity-distorted route.
3. Use the two TETHER anchors to reach the core network.
4. Use REWIRE to disable the core shield.
5. Clear the final Security Construct.
6. Activate the shutdown console and enter the victory gate.

### Areas

- `Environment/KernelApproach`
- `Environment/GravityDistortion`
- `Environment/CorePowerNetwork`
- `Environment/FinalSecurityChamber`
- `Environment/KernelShutdown`

The central kernel is a large magenta/cyan landmark. Fragmented platforms are authored as separate editable nodes. Required traversal does not depend on VECTOR RUN.

### Marker NodePaths and positions

All paths are relative to `KernelPanicEnvironment`.

| NodePath | Position | Purpose |
|---|---:|---|
| `InteractionMarkers/PlayerSpawn` | `(0, 0.4, 39)` | Safe first-person spawn |
| `InteractionMarkers/KernelObjectiveMarker` | `(0, 5, 8)` | Core landmark/objective reference |
| `InteractionMarkers/PolarityTarget_01` | `(-6, 2.2, 20)` | First POLARITY mass start |
| `InteractionMarkers/PolarityTarget_01_End` | `(-2, 5.7, 16)` | First constrained endpoint |
| `InteractionMarkers/PolarityTarget_02` | `(6, 3.7, 15)` | Second POLARITY mass start |
| `InteractionMarkers/PolarityTarget_02_End` | `(2, 7.2, 11)` | Second constrained endpoint |
| `InteractionMarkers/TetherLaunch_01` | `(0, 0.4, 25)` | First launch |
| `InteractionMarkers/TetherAnchor_01` | `(-4, 9, 21)` | Cyan anchor |
| `InteractionMarkers/TetherIntermediateLanding` | `(-2, 5.8, 16)` | Raised landing |
| `InteractionMarkers/TetherAnchor_02` | `(4, 11, 12)` | Magenta anchor |
| `InteractionMarkers/TetherLanding_02` | `(0, 0.4, 9)` | Core-network landing |
| `InteractionMarkers/FallRecoveryMarker` | `(0, 0.4, 26)` | Pre-traversal recovery point |
| `InteractionMarkers/RewireConsole_Marker` | `(8, 0.4, 2.3)` | Core REWIRE console placement |
| `InteractionMarkers/CoreShield_Marker` | `(0, 2, -5)` | Shield-state reference |
| `InteractionMarkers/SecurityConstructSpawn` | `(0, 0.4, -12)` | Single final combat spawn |
| `InteractionMarkers/KernelShutdownConsole_Marker` | `(0, 0.4, -26.5)` | Shutdown terminal placement |
| `InteractionMarkers/FinalVictoryMarker` | `(0, 0.4, -33)` | CampaignExit/final victory placement |

### POLARITY placement contract

- Initial platform visuals: `Environment/GravityDistortion/Platforms/PolarityPlatformA_Start` and `PolarityPlatformB_Start`; both have collision.
- Destination previews: `PolarityPlatformA_Target` and `PolarityPlatformB_Target`; both start hidden and non-colliding.
- Keith should place `PolarityMass` scenes at the start markers and configure their constrained endpoints from the matching `_End` markers.
- The environment previews are state references. They are not `PolarityMass` gameplay components.

### TETHER measurements

- Launch 1 to Anchor 1: approximately **10.29 m**.
- Anchor 1 to intermediate landing: approximately **6.26 m**.
- Intermediate landing to Anchor 2: approximately **8.89 m**.
- Anchor 2 to core-network landing: approximately **11.72 m**.

All straight-line distances fit the current 22 m TETHER range. Actual arcs remain unplaytested.

### Core power and kernel states

Initial power state:

- Show `Environment/CorePowerNetwork/Machinery/CyanChannel_Active`.
- Hide `Environment/CorePowerNetwork/Machinery/CyanChannel_Inactive`.
- Show `Environment/CorePowerNetwork/Machinery/MagentaChannel_Active`.
- Hide `Environment/CorePowerNetwork/Machinery/MagentaChannel_Inactive`.
- Show `Environment/CorePowerNetwork/Machinery/CoreShield_Active`; collision is enabled.
- Hide `Environment/CorePowerNetwork/Machinery/CoreShield_Disabled`.

Shield-disabled state:

- Hide and disable collision on `CoreShield_Active`.
- Show `CoreShield_Disabled`.
- Update channel active/inactive visuals as required by Keith's final puzzle state.

Kernel landmark state nodes under `Environment/CorePowerNetwork/KernelLandmark`:

- `KernelCore_Active` — initially visible.
- `KernelCore_Destabilized` — initially hidden.
- `KernelCore_Disabled` — initially hidden.

Shutdown-console visual nodes under `Environment/KernelShutdown/ShutdownMachinery`:

- `ShutdownConsole_Active` — initially visible.
- `ShutdownConsole_Destabilized` — initially hidden.
- `ShutdownConsole_Disabled` — initially hidden.

### Victory-gate states

- Locked collision: `Environment/KernelShutdown/VictoryGateStates/VictoryGate_Locked`.
- Open visuals: `VictoryGate_OpenLeft`, `VictoryGate_OpenRight`, and `VictoryGate_OpenGlow`.
- Final integration must hide and disable collision on `VictoryGate_Locked` before enabling the victory exit.

## Validation

- Godot 4.7.2 loaded each scene independently with exit code 0.
- Automated scene audit verified both root identities, all ten required areas, required markers, no attached gameplay scripts, and the initial/alternate state layout.
- Collision-enabled CSG count: Level 3 **51**, Level 4 **41**.
- Actual Godot Compatibility-renderer overhead and first-person spawn captures completed at 1280×720.
- Overhead inspection confirmed complete room-to-room connector floors and distinct five-area routes.
- First-person inspection confirmed both spawn-facing objective displays are visible and legible.
- Repository validation: **48 checks, 0 failures**.
- Final campaign validation: **62 checks, 0 failures**.
- Combat mobility validation: **41 checks, 0 failures**.
- Momentum/VECTOR RUN validation: **32 checks, 0 failures**.
- Independent Level 3 and Level 4 environment smoke runs: **30 frames each, exit code 0**.

## Manual tests still required

- Full traversal with Keith's actual player capsule.
- TETHER aim, release momentum, camera feel, and landing comfort.
- POLARITY mass dimensions, constrained travel, and collision refresh.
- REWIRE state transitions and CSG collision toggling after a rendered frame.
- Security Construct circulation and BLADE reach.
- Hazard timing and recovery fairness.
- Exit/victory trigger clearance.
- Mid-range laptop frame pacing with both production environments instanced.

Scene loading proves environment validity; it does not prove full gameplay completion.
