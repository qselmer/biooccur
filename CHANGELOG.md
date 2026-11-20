# Changelog

## 0.0.2-dev — regional shoreline-line buffers

- Buffer actual regional shoreline lines rather than entire land polygons.
- Normalize mixed overlay results to positive-area polygonal components; provide stage-specific errors.
- Add mixed-geometry and inland-window tests. Prior revision: 23 passing expectations and F01 successful; F02 continental buffer failed. New execution pending.

## 0.0.2-dev — regional shoreline preparation

- Avoid global S2 validation during loading; preselect regional candidates before predicates.
- Retry relevant invalid features at documented snap precisions.
- Extract polygon collections only when needed; add regional regression test.
- Real GSHHG execution pending.

## 0.0.2-dev — shoreline topology fix

- Validate and repair S2-invalid shoreline features before spatial predicates, retaining full resolution and original source files.
- Validate a separate planar display copy before cropping; add regression test and gallery stage messages.
- User reported duplicate vertex error with GSHHG; new revision execution pending.

## 0.0.2-dev — GSHHG reference

- Replace default Natural Earth land with GSHHG v2.3.7 full-resolution L1.
- Add local acquisition script and provenance manifest; no silent fallback.
- Crop cartographic layers for display only. Local execution pending.

## 0.0.2-dev — cartography refinement

- Add real land/ocean context for F01 and F02.
- Add geographic-window marine shoreline bands and selected island buffers.
- Expand F02 to ten examples; add coastal tests.
- Prior revision: user reported 12 passing tests. New revision execution pending.

## 0.0.2-dev — 2026-11-20

- Add draft spatial constructors, validation, point predicates, covering bounds, configuration dispatch and F01/F02 generation scripts.
- Add synthetic test suite and spatial documentation. Execution pending.

## 0.0.1-dev — 2026-11-20

- Establish canonical specification, eight spatial modes and 30 figure requirements.
- Add example configuration and repository scaffold.
