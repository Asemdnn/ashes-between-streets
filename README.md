# Ashes Between Streets

A Godot 4 prototype for a 2.5D civilian war-survival story game.

## Core rules

- The campaign is a map of story chapters.
- Each chapter starts with narrative context and ends only when its story objective is resolved.
- Supplies are local to a chapter. Water, food, medicine, and letters do not carry forward.
- Hard and very hard chapters appear periodically and use tighter time, harsher hope loss, and larger requirements.
- The theme is civilian struggle: thirst, hunger, medicine, memory, family, and impossible choices.
- Missions use a mouse-only point-and-click stealth loop: plan a route, search locations, hide from patrols, and retry if you are caught.

## Controls

- Map: Click a chapter marker.
- Mission: Click a location to walk there; click a site to search it.
- Return to chapter map: Click the Map button.

## Current vertical slice

The prototype contains five chapters:

1. The Last Tap
2. Bread Line
3. The Hospital Stairs
4. Letters Under Bricks
5. The Well Road

The first pass focuses on the campaign loop and emotional pacing. Combat is intentionally absent; the pressure comes from scarcity, time, patrol routes, hiding, and story consequences.

Chapter 1 uses `3d assets/first mission.glb` as its interactive 3D mission module, with interaction points placed in the kitchen, rooftop, and storage room. The cutaway-house image remains as a fallback while the 3D asset is importing.

The playable survivor uses `3d assets/main character.fbx` in the 3D mission viewport.

## Campaign map

The campaign map uses `art/campaign_map.png`.

Chapter 1 starts in the lower-left residential block, inside the house cluster near the edge of the city. Later chapter markers move from that corner toward the damaged center and then toward the river district.
