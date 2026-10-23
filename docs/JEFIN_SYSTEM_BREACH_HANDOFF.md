# Jefin Milestone 2 — System Breach Gameplay Readability Handoff

## Status key

- **ENVIRONMENT BUILT:** Serialized, editable environment geometry or markers exist.
- **MECHANIC INTEGRATED:** Keith's gameplay code is connected and functionally exercised.
- **PLAYTESTED:** A human completed the intended interaction using the real mechanic.
- **BLOCKED:** Required gameplay API or implementation is absent.

## Scene

`res://levels/access_denied_system_breach_environment.tscn`

The five-area route, scene path, root identity, required markers, collision style, and shared sci-fi assets are preserved. The scene remains environment-only. It contains no player, gameplay wrapper, enemy, TETHER, BLADE, REWIRE, damage, HUD, or GameFlow script.

## Intended player route

1. **Arrival Chamber:** face the large east containment landmark, read `0/2 CIRCUITS RESTORED`, distinguish Relay A from Relay B, then follow the floor chevrons and cyan conduit west.
2. **Broken Crossing:** launch from the start ledge toward cyan `TETHER 01`, land on the raised intermediate platform, aim deliberately at amber `TETHER 02`, land on the destination ledge, then operate the bridge latch when TETHER exists.
3. **Security Interception:** enter through the safe northeast approach, fight at the two marked spawn positions, use limited cover without losing room circulation, then reach the cyan Relay A beacon and follow the amber Power Diversion threshold.
4. **Power Diversion:** use the central console to redirect power from cyan channel A to amber channel B. This disables the field protecting Relay B and unlocks the east service door.
5. **Final Containment Exit:** enter from the service route, handle the final marked encounter, follow the red floor approach strips, satisfy both relay states, and open the large east containment door.

## Required Marker3D NodePaths

- `InteractionMarkers/PlayerSpawn` — `(-2, 0.4, 35)`.
- `InteractionMarkers/GrappleAnchor_01` — `(-24, 7.2, 30)`.
- `InteractionMarkers/GrappleAnchor_02` — `(-30, 8.4, 27)`.
- `InteractionMarkers/TetherPullHandle_01` — `(-39, 1.45, 26)`.
- `InteractionMarkers/EnemySpawn_01` — `(-55, 0.4, 12)`.
- `InteractionMarkers/EnemySpawn_02` — `(-44, 0.4, 6.5)`.
- `InteractionMarkers/RelayA_Marker` — `(-57, 0.4, 2.5)`.
- `InteractionMarkers/PowerConsole_Marker` — `(-18, 0.4, -7.5)`.
- `InteractionMarkers/RelayB_Marker` — `(-23.5, 0.4, -19.3)`.
- `InteractionMarkers/FinalEnemySpawn` — `(23, 0.4, 30)`.
- `InteractionMarkers/ExitMarker` — `(31.5, 0.4, 30)`.

Supporting placement markers include `TetherLaunch_01`, `TetherIntermediateLanding`, `TetherLaunch_02`, `TetherLanding_02`, `BridgeExtendedTarget`, `CombatSafeEntry`, `CombatStrafeLeft`, `CombatStrafeRight`, `RelayAApproach`, `FallRecoveryMarker`, `FallZoneMarker`, `SecurityField_Marker`, `PoweredDoorMechanism_Marker`, `FinalRelayStatusLeft_Marker`, `FinalRelayStatusRight_Marker`, and `ExitDoorClearanceMarker`.

## Provisional TETHER measurements

TETHER is **BLOCKED** because no implementation or range configuration exists on current `main`. These world-space measurements require Keith's confirmation:

- First launch `(-20.5, 0.4, 30)` to Anchor 01 `(-24, 7.2, 30)`: **7.65 units**.
- Anchor 01 to intermediate landing `(-26.5, 4.4, 29)`: **3.88 units**.
- Second launch `(-28, 4.4, 28)` to Anchor 02 `(-30, 8.4, 27)`: **4.58 units**.
- Anchor 02 to second landing `(-33, 0.4, 27)`: **8.54 units**.
- Destination safe position `(-37, 0.4, 26)` to pull handle `(-39, 1.45, 26)`: **2.26 units**.
- Maximum uncovered floor-level gap between ledges: **11.0 units**.

The raised intermediate landing is at `y = 4`; ordinary jumping cannot reach it with the current controller's 5.2 m/s jump. The retracted bridge has no collision and is stored below floor height. `ExtendedBridgeTarget` is hidden and non-colliding. Final TETHER range, swing arc, aim assistance, landing comfort, and bypass resistance remain manual integration tests.

## Combat staging

**ENVIRONMENT BUILT:** Enemy markers are on open floor with separate red placement lights. The room retains three limited cover pieces, broad circulation lanes, `CombatSafeEntry`, two strafe reference markers, a visible Relay A beacon, and an amber onward threshold. Enemy dimensions, navigation, BLADE reach, damage, and encounter timing are **BLOCKED** on Keith's implementations and are not playtested.

## REWIRE state layout

Initial intended state:

1. `ChannelA_ActiveIndicator` and `ChannelA_ActiveBranchIndicator` are visible.
2. `SecurityField_Energized` is visible and collision-enabled.
3. Channel B active indicators are hidden.
4. `PoweredDoor_Locked` is visible and collision-enabled.
5. Relay B remains behind the energized field.

Intended REWIRE transition:

1. Keith switches power from channel A to channel B at `PowerConsole_Marker`.
2. Hide/disable collision on `SecurityField_Energized`; show `SecurityField_Disabled`.
3. Hide channel A indicators; show `ChannelB_ActiveIndicator` and `ChannelB_ActiveBranchIndicator`.
4. Hide/disable collision on `PoweredDoor_Locked`; show `PoweredDoor_Open`.
5. Player accesses `RelayB_Marker`, then follows the east service route.

No state controller, signal, group, or method name is assumed. REWIRE integration is **BLOCKED** until Keith supplies the actual API.

## Final exit geometry states

Under `Environment/FinalContainmentExit/ContainmentDoor`:

- Locked: `LockedDoorPanel`, `LockedDoorSeam`, and `LockingBolt01/02`.
- Unlocking: hidden `UnlockingDoorLeft` and `UnlockingDoorRight`.
- Open: hidden `OpenDoorLeftParked`, `OpenDoorRightParked`, `OpenDoorPocket`, and `OpenDoorClearanceGlow`.

The authored open doorway is approximately 7.2 units wide and 3.7 units high, exceeding the player capsule's 0.7 m width and 1.8 m height. Door animation, collision toggling, exit triggering, and GameFlow completion remain Keith-owned.

## Validation status

- Environment structure and collision: **ENVIRONMENT BUILT**.
- Godot 4.7.2 import and isolated scene startup: **PASSED** with exit code 0.
- Automated scene audit: **PASSED** with five required areas, 11 required markers, 90 colliders, 12 route-clearance samples, an 11 m broken crossing, two clear anchor sightlines, and the authored REWIRE state layout.
- Repository validation suite: **PASSED** with 48 checks and 0 failures.
- TETHER, BLADE combat, REWIRE behavior, enemy encounter, and GameFlow completion: **BLOCKED**, not integrated, not playtested.
- `PreviewCamera` remains non-current and cannot take control from the player camera.

## Integration notes

Keith must provide TETHER ranges/arc behavior, enemy body dimensions and BLADE combat, REWIRE state hooks, the revised `GameplayLevel` wrapper, fall handling, door state animation, Relay A/B progression, and final exit completion. The current legacy wrapper still targets PHASE and is intentionally untouched.

Anushree can continue receiving objective progress from Keith's `GameFlowManager`. The world-space `0/2 CIRCUITS RESTORED` display is environmental signage; HUD text and state binding remain Anushree/Keith integration work.

Manual playtests still required: first-person sign readability, both grapple arcs, intermediate landing comfort, ordinary-jump bypass attempts, pull-handle reach, enemy circulation and BLADE reach, console sightlines, state-transition clarity, Relay B access after field disable, powered-door clearance, final encounter spacing, and unlocked exit completion.
