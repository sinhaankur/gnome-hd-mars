# Research brief — Hugging Face artifacts + Epic Games, applied to Mars HAWC

Date: 2026-11-22. Scope: the three Hugging Face links the user shared, plus the
Epic Games / Fab 3D-asset ecosystem, each assessed go/no-go **for this game**.

---

## 1. THUSI-Lab/GameScaling — a game-*playing* VLM. **NO-GO for us.**

**What it is.** A collection of vision-language models (Qwen3.5 backbones) that
*play* games. Input: the current game frame + up to 5 history frames and prior
actions. Output: the next 200 ms of keyboard+mouse control —
`6 steps × 33 ms + one mouse move + scroll`, in a fixed action grammar
(`<|action_start|> X Y Z ; g1..g6 <|action_end|>`).

**Sizes / HW.** 0.8B (2.2 GB) · 2B (5.4 GB) · 9B (18.8 GB) · 27B (54.7 GB, needs
**2 GPUs**, tensor-parallel). Configs: **S1** = Minecraft-only, **S3** = balanced
mix (27% Minecraft). 1,600 h gameplay. Apache-2.0 (code+weights); training data
proprietary.

**Could it auto-playtest our Godot game?** In practice, **no.** It was evaluated
only on Minecraft, ViZDoom, OmniGameArena, GameWorld, and it needs a per-game
system prompt with explicit rules + key bindings. An untrained custom title
(our Mars HAWC) has no instruction template; performance would degrade badly. It
also can't read Godot internals — it only sees pixels and emits input. Even the
small checkpoints are heavy for what would be a flaky playtester.

**Verdict.** Interesting as *prior art* for "a model specialized on gameplay,"
but not a tool we adopt. The transferable idea — a **small model fine-tuned to a
narrow, verifiable task** — is exactly what we're doing with bpy-smith, just for
asset *creation* instead of *playing*.

---

## 2. FronkonGames/steam-games-dataset — market data. **GO, for positioning only.**

**What it is.** ~124,000 Steam games, Parquet (pandas/Polars/🤗 Datasets), **MIT**
licensed (DOI 10.57967/hf/0511). 40+ fields incl. `appID, name, release_date,
estimated_owners, peak_ccu, price, genres, tags, categories, developers,
publishers, positive, negative, metacritic_score, average_playtime_forever,
header_image, screenshots`.

**Use for Mars HAWC.** Pure *market research*, not game content. It can answer:
how crowded is the mech/action/sci-fi segment, what tags co-occur with high
owner counts, what price band mech-shooters sit in, which recent releases are
comparable. Useful before a store page, not for building the game.

**Verdict.** Keep as a positioning input. Low priority vs. actually finishing the
vertical slice. One `pandas` script (filter `genres`/`tags` for
mech/robot/sci-fi-action) answers the only questions we have today.

---

## 3. sinhaankur/helmsman-4b — the *recipe* we're reusing. **GO — it's our template.**

**What it is (user's own model).** Qwen3-4B-Instruct-2507 + **QLoRA** (r16, a32,
3 epochs, cosine), merged to fp16, exported **Q4_K_M GGUF** (~2.5 GB) to run in
4-bit on a laptop. Trained on **305 synthetic QA pairs** (Claude as teacher) for
document-grounded QA in the Unhosted daemon. AGPL-3.0-or-later. Not for
open-ended chat / tool use / safety-critical.

**Why it matters here.** It is the proven blueprint for **bpy-smith**: same base,
same QLoRA→merge→GGUF path, same "small high-signal dataset + Claude teacher"
philosophy — retargeted from *document QA* to *Blender-Python code generation*.
See `~/Downloads/bpy-smith/`. The one hard rule we add: every training output is
**executed** by `eval/verify_bpy.py` in headless Blender, so the model only ever
learns scripts that actually run and export a valid GLB.

**Verdict.** This is the spine of the whole effort. Already scaffolded, 6 seed
scripts verified 6/6, dataset + harness working.

---

## 4. Epic Games / Fab — the asset ecosystem. **GO — biggest practical win.**

This is the item that **changes our asset strategy**, so it earned its own dig.

**Megascans is free again (Nov 2026).** Epic's Fab marketplace has made the
**entire Quixel Megascans library free** under the **Fab Standard License**, and
— critically — updated terms now **permit training AI models on Megascans/
Megaplants**. Timeline for context: free in the 2024 giveaway → mostly paid Jan
2025 (only ~1,500 free) → **fully free again as of this month**. If anything was
bought in the paid window it's refunded to Epic balance, license kept.

**The three facts that matter for us:**
1. **Any engine.** The Fab Standard License explicitly allows use "in any game
   engine or tool" — **not** Unreal-only. Godot is fine.
2. **Right formats.** Downloads include **FBX / glTF + texture maps**, which
   Godot imports directly. (Download from **Fab**, *not* the legacy Bridge — Bridge
   files carry the old Unreal-only Epic Content License.)
3. **AI-training rights.** New terms allow training models on the assets — relevant
   if we ever want bpy-smith (or a texture model) to learn from Megascans scans.

**Use for Mars HAWC.** Megascans is *photoscanned real-world rock, cliff, sand,
gravel, and debris* — i.e. exactly the Mars-surface set dressing we keep
hand-building and calibrating against NASA photos. This is a legitimate, licensed
shortcut to photoreal terrain detail and rock/boulder props. It slots directly
into our existing "find real CC asset → normalize → export GLB" pipeline (the
`mars-hawc-asset-sourcing` skill), just with a far higher-quality, now-free source.

**Caveat.** Terms change (this library flip-flopped twice in two years) — confirm
the current Fab Standard License at download time and record the license in
`CREDITS.md` as we do for Sketchfab CC-BY assets.

**Verdict.** Adopt as a primary asset source for Mars terrain/rock/debris.
Highest-leverage finding here.

---

## What we do with this (priority order)

1. **Keep building bpy-smith** (in progress) — the on-device bpy code model. Spine.
2. **Pull Megascans Mars-surface scans from Fab** → normalize via the asset
   pipeline → drop into `godot/assets/`. Biggest immediate quality win; log license.
3. **Scale the bpy-smith dataset** from our real `tools/build_*.py` + GLBs — every
   row verified by the headless-Blender harness.
4. **Wind training to the cloud** — QLoRA on cloud GPU (laptop only runs the GGUF).
5. **(Low priority)** one `pandas` pass over the Steam dataset for store-page
   positioning when we get there.

GameScaling: noted as prior art, **not adopted.**

---

### Sources
- [GameScaling (HF)](https://huggingface.co/THUSI-Lab/GameScaling)
- [Steam Games Dataset (HF)](https://huggingface.co/datasets/FronkonGames/steam-games-dataset)
- [helmsman-4b (HF)](https://huggingface.co/sinhaankur/helmsman-4b)
- [Tim Sweeney — Fab launch, Megascans free perpetual license, all engines](https://x.com/TimSweeneyEpic/status/1848876936136954083)
- [Quixel — Megascans are going free again](https://quixel.com/news/update-megascans-are-going-free-again)
- [Epic made Megascans free to all (CG Channel)](https://www.cgchannel.com/2024/10/epic-games-has-made-megascans-free-to-all-but-only-until-the-end-of-2024/)
- [Megascans update, March 2025 (Epic forums)](https://forums.unrealengine.com/t/megascans-update-march-2025/2419561)
