---
name: evidence-based-health-analysis
description: "Search medical literature (PubMed, clinical guidelines), extract evidence from cohort studies, synthesize multi-source findings, and produce personalized health risk assessments + actionable plans."
version: 1.1.0
author: Emma
tags: [health, medical-research, evidence-based, risk-assessment, patient-education, lifestyle-medicine]
---

# Evidence-Based Health Analysis

Systematic workflow for researching a health condition, finding authoritative evidence, and creating personalized risk assessment + lifestyle recommendations.

## When to Use

Trigger conditions (any of these):
- User asks "what are the risks/complications of condition X after recovery?"
- User provides a patient profile and asks for risk analysis + lifestyle guidance
- User shares lab/imaging results and asks for interpretation + action plan
- User asks "what does the research say about X" in a health/medical context
- User asks general health/wellness/lifestyle science questions (metabolism, diet, exercise, sleep, longevity, energy levels, etc.)
- User has a personal or family health history and wants evidence-based preventive guidance

Do NOT use for:
- Emergency medical advice ("I'm having chest pain") → tell user to call 911/120
- Drug interaction queries → refer to pharmacy/clinical pharmacist
- Interpreting diagnostic imaging directly → radiologist territory
- Very narrow pharmacology-only questions → better suited to drug-specific databases

## Workflow

### Phase 1: Literature Search Strategy

Search in this priority order:

1. **PubMed cohort studies** — structured PubMed queries with filters:
   ```
   site:pubmed.ncbi.nlm.nih.gov <condition> <outcome> cohort prospective long-term
   ```
   Add `2023 2024 2025` for recency. Use `+AND+` syntax or natural language.

2. **Clinical guidelines** — search for major specialty societies:
   - Chinese: `site:yiigle.com <condition> 指南 诊治`
   - International: `site:guidelines.gov <condition>` or society acronyms (IAP/APA, AGA, AASLD, ESC, etc.)

3. **Major journal reviews** (The Lancet, JAMA, BMJ, NEJM, Gastroenterology):
   ```
   site:thelancet.com <condition> epidemiology review
   ```

4. **Systematic reviews / meta-analyses** (highest evidence level):
   ```
   <condition> systematic review meta-analysis
   ```

### Search Reliability & Fallback Strategy

**DuckDuckGo (`web_search`) frequently times out** on both English and Chinese health queries, especially through VPN/proxy. Do NOT retry more than once — switch to `web_extract` on known authoritative sites immediately.

**Authoritative sites for direct extraction (web_extract):**

| Site | Type | Best For |
|------|------|----------|
| `pubmed.ncbi.nlm.nih.gov` | Search results page | PubMed abstract discovery |
| `pmc.ncbi.nlm.nih.gov` | Full-text PMC articles | Free full-text papers |
| `www.health.harvard.edu` | Harvard Health | Wellness, lifestyle, metabolism, disease overviews |
| `www.mayoclinic.org` | Mayo Clinic | Clinical condition guides, patient education |
| `ods.od.nih.gov` | NIH Office of Dietary Supplements | Supplement/nutrition evidence (industry-neutral) |
| `www.nhs.uk` | UK National Health Service | Evidence-based healthy living guides |
| `www.chinanews.com.cn/jk/` | China News Health Section | Chinese-language health science articles |
| `m.thepaper.cn` | The Paper (澎湃) | Chinese-language health/lifestyle features |

**Parallel search pattern (batch independent queries):**
```
Round 1: Direct topic search (EN)        — web_search, if fail → web_extract
Round 2: Direct topic search (ZH)        — web_search, if fail → web_extract
Round 3: Authoritative site extraction   — web_extract on known URLs above
Round 4: Academic/PubMed extraction      — web_extract on pubmed search results
```

Run rounds 1-2 in parallel (they're independent), then 3-4 based on what was found. This minimizes turns lost to timeouts.

### Phase 2: Evidence Extraction

For each key paper, extract structured data:

```
[PMID: XXXXXXXX]
Design: (population-based cohort / RCT / systematic review / etc.)
Population: (n, demographics, geography, follow-up duration)
Key findings: (effect sizes with 95% CI, absolute risks, HR/RR/OR)
Subgroup findings: (age, sex, etiology, severity)
Confounders adjusted for:
```

**Quality checkpoints:**
- Prefer population-based nationwide cohorts over single-center
- Prefer >5 year follow-up for long-term risk assessment
- Check that effect sizes have confidence intervals
- Note if the study adjusted for key confounders (age, sex, smoking, alcohol, BMI)
- Distinguish association from causation — use cautious language

### Phase 3: Evidence Synthesis

Build a structured risk profile:

```
## Related Diseases — Evidence Table

| Disease | Risk Metric (95% CI) | Population | Source |
|---------|---------------------|------------|--------|
| Condition A | HR X.XX (X.XX-X.XX) | National cohort, n=X,XXX | [PMID: XXXXXXXX] |
| Condition B | OR X.XX (X.XX-X.XX) | Meta-analysis, n=XX,XXX | [PMID: XXXXXXXX] |
```

Group by:
- **Pancreatic outcomes** (recurrence, chronic disease, cancer)
- **Endocrine outcomes** (diabetes, metabolic syndrome)
- **Cardiovascular outcomes** (MI, stroke, MACE)
- **Nutritional outcomes** (exocrine insufficiency, vitamin deficiencies)

### Phase 4: Patient-Specific Risk Assessment

Map evidence to the individual patient:

| Risk Factor in Evidence | Patient Status | Risk Contribution |
|------------------------|----------------|-------------------|
| Smoking (RR 2.5) | Non-smoker | ✅ Low (protective) |
| Obesity (OR 2.59 for PPDM) | BMI 27.3 | ⚠️ Moderate |
| Male sex (HR 1.80 for MACE) | Male | ⚠️ Elevated baseline |

**Then identify signal clusters** — combinations of subjective symptoms + objective data that point toward a specific risk:

```
Symptom A + Finding B + Risk Factor C → probable early stage of Condition X
```

### Phase 5: Actionable Plan

Structure as a table with priority levels:

```
## Recommendations (Priority-Ordered)

### 🔴 High Priority (do this week)
- Specific lab/imaging tests to order
- Lifestyle changes with immediate impact

### 🟡 Medium Priority (this month)
- Diet/exercise modifications
- Supplementary tests if first batch abnormal

### 🟢 Low Priority (ongoing)
- Long-term monitoring schedule
- Screening cadence by age
```

Use a **batch testing strategy** — don't suggest 15 tests at once. Group into 3 rounds:
1. Core metabolic (catch the most likely issue first)
2. Organ-specific (deeper investigation if indicated)
3. Nutritional/metabolic supplement (fine-tuning)

### Phase 6: Deliverable

Create a structured markdown file if user wants it saved/sent. Include:
- Background summary of patient + evidence
- Risk table
- Action plan with priorities
- Interpretation quick-reference table for test results
- CTA to come back with results

## Evidence Interpretation Guidelines

### Effect Size Language
| Statistic | Language |
|-----------|----------|
| HR/OR 1.0-1.5 | Modest increase |
| HR/OR 1.5-3.0 | Moderate increase |
| HR/OR 3.0-10.0 | Substantial increase |
| HR/OR > 10.0 | Strong/deterministic |
| 95% CI crosses 1.0 | Not statistically significant |

### p-value and CI caveats
- Large studies can have tiny p-values for clinically trivial effects — always look at the effect size, not just p
- Wide CIs = imprecise estimate; narrow CIs with strong effects = robust finding
- Absolute risk (e.g. "5-year risk 0.87%") tells a different story than relative risk (HR 2.02) — report both when available

## Pitfalls

1. **Don't overstate risk.** A HR of 2.0 sounds scary but if baseline risk is 0.5%, the absolute increase is only 0.5%. Always try to anchor with absolute risk numbers.
2. **Don't confuse relative risk with absolute risk.** Report both when possible.
3. **PubMed abstracts may not tell the full story** — the full text may have conflicting subgroup analyses.
4. **Single-center studies have limited generalizability.** Prefer nationwide/multi-center cohorts.
5. **Confounding is everywhere in observational studies.** Look for adjusted models and sensitivity analyses.
6. **Don't extrapolate pediatric evidence to adults or vice versa** unless the study explicitly covers that age range.
7. **Never recommend specific medications or dosages** — that requires a physician's prescription and clinical judgment.
8. **Chinese guideline content may be behind paywalls** (yiigle.com). Use web_search + web_extract; if blocked, note the limitation.
9. **Avoid "WebMD-style" oversimplification** — the user asked for authoritative research, not pop-science.
10. **Always distinguish "correlation" from "causation"** in the write-up.
11. **web_search (DuckDuckGo) is unreliable** through VPN/proxy — it frequently times out on both EN and ZH queries. After the first timeout, switch to web_extract on authoritative sites (see Search Reliability section above). Do NOT retry 3+ times.
12. **Parallel search ≠ loading all at once** — Batch independent searches in the same turn, but limit to 3-4 web calls per turn to avoid timeouts on all of them simultaneously. If one call times out, the others may still return.

## Related Skills

- `paper-deep-dive` — Deep analysis of a single academic paper (complementary; use after this skill identifies a key paper)
- `research-backed-validation` — Validate a specific claim or hypothesis (use when user wants to fact-check a specific claim)
- `himalaya` — Email delivery of the markdown plan as attachment (pipe .md file as `cat plan.md | himalaya template send`)

## Reference Files

- `references/acute-pancreatitis-evidence.md` — Evidence synthesis on acute pancreatitis risks, outcomes, and lifestyle guidance
- `references/coffee-health-evidence.md` — Comprehensive evidence synthesis on coffee health effects: all-cause mortality, CVD, gastrointestinal effects, sleep, anxiety, genetic variability, timing effects
- `references/basal-metabolic-rate-evidence.md` — Evidence synthesis on basal metabolic rate determinants, relationship to "high energy" / NEAT, and science-backed interventions to increase BMR
