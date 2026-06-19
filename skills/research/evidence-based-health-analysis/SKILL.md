---
name: evidence-based-health-analysis
description: "Search medical literature (PubMed, clinical guidelines), extract evidence from cohort studies, synthesize multi-source findings, and produce personalized health risk assessments + actionable plans."
version: 1.0.0
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

## Related Skills

- `paper-deep-dive` — Deep analysis of a single academic paper (complementary; use after this skill identifies a key paper)
- `research-backed-validation` — Validate a specific claim or hypothesis (use when user wants to fact-check a specific claim)
- `himalaya` — Email delivery of the markdown plan as attachment (pipe .md file as `cat plan.md | himalaya template send`)
