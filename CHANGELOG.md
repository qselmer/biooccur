# Changelog

## 0.0.2-dev — native S2 area diagnostics

- User confirmed 44 passing expectations and F01 (152706.8 km²; 94.70236% marine); F02 metrics failed on a land-overlap repair.
- Measure area-only overlaps and differences directly in S2 using polygon-dimensional outputs, avoiding WKB reconstruction of boundary contacts.
- Keep geometry-producing operations strict; add boundary-contact and band tests, panel-specific metric logging. Execution pending.

## 0.0.2-dev — environment overlay topology

- Use direct complementary intersection/difference against the original validated land mask.
- Validate polygonal overlay results before area calculation, including diagnostic overlays.
- Add shared-edge regression checks. User reported 34 passes and one masking failure; revised tests pending.

## 0.0.2-dev — final spatial refinement

- User demonstrated all three GSHHG integration cases and F01/F02 outputs.
- Add environment masks, quantitative spatial metrics and sampled distance/area audits.
- PNG-only 600 dpi maps with base font 16, scale bars, balanced extents and individual F02 panels.
- New verification pending.

## 0.0.2-dev — integration test fixture correction

- Replace unsupported nested collection constructor in unit test with valid mixed polygon/point collection.
- Scope integration options restoration to a function using on.exit.
- User reported 29 passing expectations and one fixture construction failure; real GSHHG integration not yet reached.

## 0.0.2-dev — heterogeneous overlay diagnostics

- User reported 27 passing expectations and successful F01; real continental F02 case still failed with do.call error (exact call unknown).
- Extract nested geometry components explicitly; normalize polygon overlays to MULTIPOLYGON and validate coordinates per feature.
- Add stage-specific tracing and standalone real-GSHHG integration script. Execution pending.

## 0.0.2-dev — session isolation fix

- Qualify base::c in overlay concatenation to prevent global-object masking.
- Isolate gallery objects in a local environment; use descriptive domain names.
- Add masking regression test. User reported three failures caused by nonfunction c; execution of fix pending.

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
