# Issues in `optimize_samp_bd.m` (IntClassNorm Toolbox)

This document details unit mismatches and ignored conditions identified in the boundary optimization function `optimize_samp_bd.m`, specifically within the Quadratic SVM (`samp_opt = 'svm'`) block.

## 1. Unit Discrepancy in Output Print Statements
When `classify_normals` runs sample boundary optimization, it prints a comparison between the starting normal boundary and the final sample boundary:

```text
Found boundary to optimize sample classification accuracy/value: 
 10291 (with normal boundary) 
 0.660367 (with sample boundary)
```

**The Issue:** The two numbers are in completely different units and are not directly comparable.
* **Normal Boundary (10291):** Evaluated using the `samp_value_flat` function, which respects the default `samp_balance = false` flag and the default `vals = eye(2)`. As a result, it returns the **absolute count** of correctly classified points across all samples.
* **Sample Boundary (0.660367):** Evaluated manually inside the SVM block. It calculates the hit rate and correct rejection rate and hardcodes the metric as `0.5 * (hit_rate + corr_rej)`. This always returns a **fractional class-balanced accuracy** between 0 and 1.

## 2. Ignored Conditions in the SVM Block
While the SVM correctly accounts for outcome costs (`Cost` derived from `vals`), it completely ignores the `samp_balance` flag during both the training phase and the final metric evaluation phase.

### A. Ignoring `samp_balance` During Training
If a user calls `classify_normals` with `samp_balance = false` (the default), they are explicitly asking for an overall accuracy boundary. However, the SVM block explicitly hardcodes class-balanced weights:
```matlab
% Class-balanced sample weights: each class gets total weight 0.5
N1 = size(samp_1,1);
N2 = size(samp_2,1);
W  = [0.5/N1 * ones(N1,1);
      0.5/N2 * ones(N2,1)];
```
Because these weights are unconditionally hardcoded, the SVM will **always** force a class-balanced boundary during optimization, ignoring the user's configuration intent.

### B. Ignoring Configurations in Final Evaluation
The final metric it computes for `samp_val_best` is hardcoded:
```matlab
samp_val_best = 0.5 * (hit_rate + corr_rej);
```
This hardcoded calculation fails to respect the input arguments:
* **Ignores `samp_balance`:** Whether the user wanted overall accuracy (`false`) or class-balanced accuracy (`true`), the SVM block overrides this and forces the output to be class-balanced accuracy.
* **Ignores `vals`:** If the user provides a custom `vals` matrix to calculate expected value instead of accuracy, the SVM block completely ignores it when computing `samp_val_best`. It continues to return pure accuracy, masking the true expected value of the boundary.

## Recommended Fixes

To resolve these discrepancies, the SVM block must explicitly extract the `samp_balance` flag from `varargin` and conditionally adapt its training behavior and final evaluation.

### Fix 1: Conditional SVM Training Weights
Extract `samp_balance` and conditionally set the training weights `W`:

```matlab
% Extract samp_balance from varargin (defaults to false)
samp_balance = false;
for i=1:2:numel(varargin)-1
    if strcmpi(varargin{i},'samp_balance')
        samp_balance = varargin{i+1};
    end
end

N1 = size(samp_1,1);
N2 = size(samp_2,1);
if samp_balance
    % Train class-balanced SVM
    W = [0.5/N1 * ones(N1,1); 0.5/N2 * ones(N2,1)];
else
    % Train overall accuracy SVM
    W = ones(N1+N2, 1) / (N1+N2);
end
```

### Fix 2: Unified Metric Evaluation
Remove the hardcoded metric evaluation:

```diff
-        % Compute class-balanced accuracy on training data
-        Yhat     = predict(svm_model, X);
-        hit_rate = mean(Yhat(Y ==  1) ==  1);   % TPR
-        corr_rej = mean(Yhat(Y == -1) == -1);   % TNR
-        samp_val_best = 0.5 * (hit_rate + corr_rej);
```

And replace it with a standard call to `samp_value_flat`, feeding it the exact same `varargin` parameters used at the top of the file to evaluate the normal boundary:

```matlab
        % Evaluate the trained SVM boundary using the user's requested metrics
        samp_val_best = samp_value_flat(samp_bd_current, samp_1, samp_2, varargin{:});
```

**Benefits of these fixes:**
1. The SVM will correctly train either a class-balanced or overall boundary depending on the user's exact configuration.
2. Both `samp_val_current` and `samp_val_best` will be reported in identical units.
3. The printed value will correctly reflect Expected Value instead of pure Accuracy when custom `vals` are supplied.

---

## Assessment (verified against source, 2026-07-08)

I traced every claim through `optimize_samp_bd.m`, `samp_value_flat.m`, `samp_value.m`, and `classify_normals.m`. **The report is substantively correct.** All three reported bugs are real, and the recommended fixes are sound. Details, corrections, and additional considerations follow.

### Verification of the reported issues

**Issue 1 — Unit discrepancy: CONFIRMED (with one nuance).**
- The "normal boundary" value is `samp_val_current` from `samp_value_flat(samp_bd_current, samp_1, samp_2, varargin{:})` (`optimize_samp_bd.m:24`). This routes to `samp_value.m`, which under the defaults `samp_balance=false` and `vals=eye(2)` returns `sum(samp_count_mat .* eye(2))` — an **absolute count** of correctly classified points (`samp_value.m:78-81`). This matches the `10291` in the example.
- The "sample boundary" value is `samp_val_best`, hardcoded as `0.5*(hit_rate + corr_rej)` (`optimize_samp_bd.m:120`) — a **fractional balanced accuracy** in `[0,1]`. This matches the `0.660367`.
- **Nuance / correction:** The report states the SVM metric "*always* returns a fractional class-balanced accuracy." That part is accurate for `samp_val_best`. But the claim that the two are *always* in different units is slightly overstated, because `samp_val_current` reflects *whatever the user passed*, not fixed defaults. If a user happens to call with `samp_balance=true` and default `vals`, then `samp_val_current` is itself a balanced accuracy in `[0,1]` and the two would coincidentally share units. The robust framing of the bug is therefore: **the SVM branch computes `samp_val_best` with a metric that is independent of the user's `samp_balance`/`vals` configuration, so it is not guaranteed to match the units of `samp_val_current` (and generally does not).**

**Issue 2A — `samp_balance` ignored during training: CONFIRMED.** `W` at `optimize_samp_bd.m:56-60` is unconditionally class-balanced, and `samp_balance` is never read anywhere in the `elseif strcmpi(samp_opt,'svm')` block. Regardless of the user's intent, the trained boundary is class-balanced.

**Issue 2B — `samp_balance` and `vals` ignored in final evaluation: CONFIRMED.** `samp_val_best` (`optimize_samp_bd.m:120`) ignores `samp_balance` (always balanced) and ignores `vals` entirely (always accuracy, never expected value). Note that `vals` *is* used during training via the `Cost` matrix (`optimize_samp_bd.m:64-72`) — so the report is right that training partially honors `vals` while evaluation does not.

**Data-flow check for the proposed Fix 1.** I confirmed `samp_balance` actually reaches `optimize_samp_bd` via `varargin`: it is a declared parameter of `classify_normals` but *not* of `optimize_samp_bd`'s `inputParser`, and `classify_normals.m:576` forwards the raw `varargin{:}`. So the extraction loop in Fix 1 will find it. Likewise `vals` is available (though `optimize_samp_bd` already parses `vals` into a local variable, so Fix 2 could reuse that directly rather than re-reading `varargin`).

### Additional considerations the report does not mention

1. **Training/evaluation objective mismatch is only partially fixable.** `fitcsvm` minimizes a (cost- and weight-weighted) *hinge loss*, not the exact 0-1 count/expected-value metric that `samp_value_flat` computes. Even after Fix 1 aligns the *weighting scheme*, the SVM is still optimizing a surrogate objective, so `samp_val_best` from Fix 2 is an honest *evaluation* of the returned boundary but not a guarantee that the SVM maximized that exact metric. This is acceptable (the other branches also just report `samp_value_flat` of whatever boundary they found), but it is worth a code comment so future readers do not expect the SVM to be an exact optimizer of the reported number.

2. **Potential double-application of class priors.** `fitcsvm` internally combines `Weights` and `Cost` (cost is folded into effective observation weights). The block currently passes *both* class-balanced `W` *and* a `Cost` derived from `vals`. When both a custom `vals` and balancing are in play, the class reweighting can effectively be applied twice. Fix 1 does not address this. A cleaner design is to pick one channel: either encode balancing purely through `W` and keep `Cost` for the value asymmetry, or document explicitly how the two compose. This deserves a deliberate decision, not silent hardcoding.

3. **Default `samp_opt`.** `optimize_samp_bd`'s own parser defaults `samp_opt='svm'` (`optimize_samp_bd.m:8`), whereas `classify_normals` defaults `samp_opt=100` (`classify_normals.m:236`). So through the normal entry point the SVM branch runs only on explicit opt-in, which limits blast radius — but anyone calling `optimize_samp_bd` directly hits the SVM path by default. Not a bug, but relevant to prioritization.

4. **Print label semantics.** The `fprintf` (`optimize_samp_bd.m:176`) labels are correct (`samp_val_current` = starting/normal boundary, `samp_val_best` = optimized sample boundary); the only defect is units, exactly as reported.

### Overall verdict

The report correctly identifies genuine defects and its proposed fixes are the right shape. I would adopt Fix 1 and Fix 2 essentially as written, with the small refinements below.

---

## My resolution plan

**Step 0 — Reproduce.** Add a quick harness script that calls `classify_normals` on an unbalanced 2-class dataset with (a) defaults, (b) `samp_balance=true`, (c) custom `vals`, all with `samp_opt='svm'`, and prints `samp_val_current`/`samp_val_best`. Capture current (buggy) output as a baseline.

**Step 1 — Fix the final metric (Issue 1 & 2B).** Replace `optimize_samp_bd.m:116-120` (the `predict`/`hit_rate`/`corr_rej`/hardcoded `samp_val_best` block) with:
```matlab
samp_val_best = samp_value_flat(samp_bd_current, samp_1, samp_2, varargin{:});
```
This reuses the exact code path used by `samp_val_current` and by the other optimizer branches, guaranteeing identical units and correct honoring of `samp_balance` and `vals`. This single change fixes the unit mismatch (Issue 1) and the ignored-config-in-evaluation (Issue 2B) together, and removes the now-unused `Yhat` computation.

**Step 2 — Fix training weights (Issue 2A).** Make `W` conditional on `samp_balance`. Rather than re-parsing `varargin` (Fix 1 as written), I would extract `samp_balance` once near the top of `optimize_samp_bd` alongside the existing `parser.Results` reads (adding it as an explicit `addParameter(parser,'samp_balance',false,@islogical)` so it is parsed cleanly instead of scraped from `varargin`), then in the SVM block:
```matlab
if samp_balance
    W = [0.5/N1 * ones(N1,1); 0.5/N2 * ones(N2,1)];
else
    W = ones(N1+N2,1) / (N1+N2);
end
```
This keeps parsing consistent with the rest of the function.

**Step 3 — Resolve the Weights×Cost interaction (additional consideration #2).** Decide and document how balancing and value-asymmetry compose in `fitcsvm`. Minimum: add a comment stating the intended semantics. Better: verify empirically on the unbalanced test data that the effective priors are what we intend, and adjust `W` or `Cost` so priors are not applied twice.

**Step 4 — Add a clarifying comment (additional consideration #1)** noting that the SVM optimizes a hinge-loss surrogate and that `samp_val_best` is a post-hoc evaluation, not the quantity the SVM maximized.

**Step 5 — Verify.** Re-run the Step 0 harness and confirm: (a) `samp_val_current` and `samp_val_best` are in the same units in all three configs; (b) with `samp_balance=false` the SVM boundary differs from the `samp_balance=true` one on unbalanced data; (c) with custom `vals`, `samp_val_best` reflects expected value, not accuracy. Also run any existing test/demo scripts in the repo to check for regressions in the non-SVM branches (which should be untouched).

**Step 6 — Scope check.** The changes are confined to `optimize_samp_bd.m`; `samp_value.m`/`samp_value_flat.m` already behave correctly and need no edits. Confirm no other caller depends on the old balanced-accuracy semantics of the SVM branch's return value.

---

## Implementation status (done, tested in MATLAB R2024b — 2026-07-08)

All steps above were implemented in `optimize_samp_bd.m` and verified headlessly.

**Changes made:**
1. Added `addParameter(parser,'samp_balance',false,@islogical)` and extracted `samp_balance` alongside the other parsed results (cleaner than scraping `varargin`).
2. Training weights `W` are now conditional on `samp_balance` (overall vs class-balanced).
3. The hardcoded `0.5*(hit_rate+corr_rej)` metric (and the now-unused `predict` call) was replaced with `samp_val_best = samp_value_flat(samp_bd_current, samp_1, samp_2, varargin{:})`.
4. Added code comments documenting the Weights×Cost composition and that `fitcsvm` optimizes a hinge-loss surrogate rather than the exact reported metric.

**Verification (unbalanced data, N1=800 / N2=200, `samp_opt='svm'`):**

| Config | Before fix (printed *normal* / *sample*) | After fix (printed *normal* / *sample*) |
|---|---|---|
| (a) defaults `samp_balance=false`, `vals=eye(2)` | `875` (count) / `0.896` (accuracy) — **mismatched** | `875` / `919` (both counts) — **matched** |
| (b) `samp_balance=true` | `0.894` / `0.896` (coincidentally matched) | `0.894` / `0.896` (matched) |
| (c) custom `vals=[2 0;0 1]`, `samp_balance=false` | `1565` (exp. value) / `0.896` (accuracy) — **mismatched** | `1565` / `1700` (both expected value) — **matched** |

In every case the printed `samp_val_best` now equals an independent `samp_value_flat` evaluation of the returned boundary. The `samp_balance=false` and `samp_balance=true` runs produce **different** boundaries (e.g. count 919 vs 897 correct), confirming training now honors the flag. End-to-end tests through `classify_normals` (`input_type='samp'`) succeed for both SVM configs, and a regression run of the non-SVM `samp_opt=1` (fminsearch) branch is unaffected.

## Follow-up: report accuracy (not count), and label the metric (2026-07-08)

**User request:** when no custom `vals` is supplied, both printed numbers should be **accuracy fractions**, not the raw correct-classification count that `samp_value_flat` returns for `samp_balance=false`. Additionally, the print statement should state *what* is being optimized (accuracy vs. class-balanced accuracy vs. expected value vs. class-balanced expected value), switched on whether `vals` was explicitly passed and whether `samp_balance` is set — rather than the generic "accuracy/value" wording.

This is a common concern across *all* four optimizer branches (`fminsearch`/global, `svm`, `smooth`), since they all funnel through the single shared `fprintf` at the end of `optimize_samp_bd.m` and all compute their values via `samp_value_flat` with the same `varargin`. So the fix was made once, at that shared print site, rather than duplicated per branch.

**Implementation** (`optimize_samp_bd.m`):
1. `vals_given = ~ismember('vals', parser.UsingDefaults)` detects whether the caller explicitly passed a custom `vals` matrix (vs. relying on the default `eye(2)`).
2. Immediately before the final `fprintf`, if `~vals_given && ~samp_balance` (the one case where `samp_value_flat`/`samp_value` returns a raw count rather than a fraction — see `samp_value.m:80-81`), both `samp_val_current` and `samp_val_best` are divided by `N = size(samp_1,1)+size(samp_2,1)` to convert count → accuracy. The `samp_balance=true` case is left alone because `samp_value.m:85` already returns a mean of per-class fractions.
3. A `metric_label` is chosen by a case switch on `(vals_given, samp_balance)`: `'accuracy'`, `'class-balanced accuracy'`, `'expected value'`, or `'class-balanced expected value'`, and substituted into the format string in place of the old generic "accuracy/value".

**Verification (MATLAB R2024b, headless), unbalanced 800/200 data, `samp_opt='svm'`:**

| Config | Label printed | Normal / Sample |
|---|---|---|
| defaults | `accuracy` | `0.875` / `0.919` (fractions, not counts) |
| `samp_balance=true` | `class-balanced accuracy` | `0.894` / `0.896` (unchanged, already a fraction) |
| custom `vals=[2 0;0 1]` | `expected value` | `1565` / `1700` (unchanged, correctly not rescaled) |
| custom `vals` + `samp_balance=true` | `class-balanced expected value` | `1.325` / `1.366` |

Re-ran the `classify_normals` integration test and the `smooth`/`fminsearch` branches directly: all print the correctly labeled fractional accuracy by default, and non-default-`vals` behavior (expected value, unscaled) is preserved. No regressions.
