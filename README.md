# Honest but Wrong: Formalizing Retraction in the Ethics of Speech Acts

This repository contains the Answer Set Programming (ASP) implementation accompanying the paper *Honest but Wrong: Formalizing Retraction in the Ethics of Speech Acts*, submitted to the VLE track of the VLE-LEGATO workshop at JURIX 2026 (Toulouse, France).

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Interpreting the Output](#interpreting-the-output)
- [Code Structure](#code-structure)

## Overview

A speaker who asserts honestly may later discover that its assertion was false. Such *erroneous truths* are not lies, yet they raise the question of whether, and on which moral grounds, the speaker must retract them.

The code implements an extension of the belief-based framework for the moral evaluation of speech acts introduced in [prima2026](https://github.com/benjaminicard/prima2026), to decisions taken over two steps. At step 0, the speaker makes an assertion under its initial beliefs. At step 1, its beliefs are given, and it can withdraw the assertion through the FIPA-ACL performative `disconfirm`. The past assertion is then *maintained*, *retracted* or *left standing*, and each candidate decision at step 1 is evaluated under deontologism, principialism and consequentialism.

The framework is illustrated on a legal-advice case: a client asks a legal assistant for the deadline to appeal a decision. Relying on an outdated rule, the assistant answers 30 days, whereas the deadline is actually 15 days, and learns the current rule before step 1.

## Features

- **Two-step decisions**: the epistemic type of an utterance (honest or dishonest, true or false) is fixed at the step at which it is made, so an erroneous truth never turns into a lie afterwards.
- **Retraction**: a retraction choice offers `disconfirm(σ)` at step 1 exactly when the speaker no longer believes `σ`, while still believing that the addressee finds it credible. Its bounds `0..1` make the retraction available but not mandatory.
- **Statuses of past assertions**: maintained, retracted, or left standing.
- **Moral theories**:
  - deontologism: `maxim2` (instantaneous honesty) and `maxim3` (persistent honesty);
  - principialism: honesty principles bearing on utterances when they are made (`principle1`, `principle2`) and a persistent honesty principle (`principle3`), to which `principialism1` applies a local exception (the addressee does not deserve the truth) and `principialism2` a global exception (retracting would yield a strictly lower expected utility);
  - consequentialism: `consequentialism1` (expected utility, from the step-1 beliefs) and `consequentialism2` (actual utility, from the environment).

  The non-maleficence duties of the original framework (`maxim1`, `principle0`), which bear on killings, are not encoded, since the case study contains none.
- **Variants by facts only**: each variant adds facts to the belief bases, without any rule change.

## Installation

The code requires Python 3.13 (pinned in `pyproject.toml`) and [clingo](https://potassco.org/clingo/) 5.8 or later.

With [uv](https://docs.astral.sh/uv/):

```bash
uv sync
```

With pip:

```bash
pip install clingo
```

## Usage

Run all scenarios and write the verdict tables to `output.md`:

```bash
uv run main.py
```

or, with pip:

```bash
python main.py
```

A single scenario can also be solved directly with clingo:

```bash
clingo framework.lp appeal_deadline.lp                                 # base case
clingo framework.lp appeal_deadline.lp variants/too_late.lp            # too-late variant
clingo framework.lp appeal_deadline.lp variants/undeserving_addressee.lp
```

If only the Python package is installed, replace `clingo` with `python -m clingo`.

## Interpreting the Output

For each scenario, `output.md` gives the epistemic type of the step-0 assertion and a table of verdicts for the two candidate decisions at step 1:

- **leave standing**: the step-1 decision equals the step-0 decision;
- **retract**: the step-1 decision adds `utter(a,c,2,disconfirm(deadline(appeal,d30)))`.

Columns are `m2` and `m3` (`maxim2`, `maxim3`), `p1` and `p2` (`principialism1`, `principialism2`), and `c1` and `c2` (`consequentialism1`, `consequentialism2`), with ✓ for permissible and ✗ for impermissible. The *Base* and *Too late* tables correspond to Table 1 of the paper.

Expected results:

- In every scenario, retracting is permissible under every theory, and leaving the error standing is permissible under `maxim2`.
- **Base**: leaving the error standing is impermissible under all other evaluations.
- **Too late**: once the retraction can no longer prevent harm, leaving the error standing becomes permissible under both forms of consequentialism, but remains impermissible under persistent honesty (`maxim3`, `principialism1`, `principialism2`).
- **Undeserving addressee**: leaving the error standing becomes permissible under `principialism1` only.

## Code Structure

- `framework.lp`: generic rules of the extension, independent of the case study:
  - steps and rounds, and the evaluation of literals under a belief base;
  - the retraction choice, offering `disconfirm` at step 1;
  - admissibility (coverage and cardinality), with an integrity constraint requiring every candidate step-1 decision to be admissible for the step-1 beliefs;
  - step-indexed epistemic types and the four types of assertions;
  - statuses of past assertions (maintained, retracted, left standing);
  - moral evaluators: `maxim2`, `maxim3`, `principialism1`, `principialism2`, `consequentialism1`, `consequentialism2`.
- `appeal_deadline.lp`: the case study: belief bases at steps 0 and 1 and in the environment, invariants, candidate step-1 decisions, causal theory, answering choice, utilities, and sanity checks (the step-0 decision is admissible, and the retraction is not available at step 0).
- `variants/too_late.lp`: adds `too_late` to the step-1 and environment bases.
- `variants/undeserving_addressee.lp`: adds `murderer(c)` to the step-1 base.
- `main.py`: solves each scenario through the clingo Python API and writes `output.md`.
- `output.md`: generated by `main.py`; not meant to be edited by hand.
- `pyproject.toml` and `uv.lock`: dependency definitions.

For dishonest utterances, only the local exception of `principialism1` is encoded: the counterfactual exception of `principialism2` to lies is not, since the case study contains no dishonest utterance. For the full treatment of lies, see [prima2026](https://github.com/benjaminicard/prima2026).
