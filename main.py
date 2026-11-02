"""Run the case study and its variants, and write the verdict tables to output.md."""

from pathlib import Path

import clingo

ROOT = Path(__file__).resolve().parent
PROGRAMS = [ROOT / "framework.lp", ROOT / "appeal_deadline.lp"]
SCENARIOS = {
    "Base": [],
    "Too late": [ROOT / "variants" / "too_late.lp"],
    "Undeserving addressee": [ROOT / "variants" / "undeserving_addressee.lp"],
}
THEORIES = ["m2", "m3", "p1", "p2", "c1", "c2"]
DECISIONS = {"stand": "leave standing", "retract": "retract"}
SYMBOLS = {"ok": "✓", "ko": "✗"}


def solve(files):
    """Return the atoms of the unique answer set of the given programs."""
    ctl = clingo.Control(["--warn=none"])
    for file in files:
        ctl.load(str(file))
    ctl.ground([("base", [])])
    models = []
    ctl.solve(on_model=lambda m: models.append(m.symbols(shown=True)))
    if len(models) != 1:
        raise RuntimeError(f"expected one answer set, got {len(models)}")
    return models[0]


def verdicts(atoms):
    """Map (decision, theory) to 'ok' or 'ko'."""
    table = {}
    for atom in atoms:
        if atom.name == "verdict":
            decision, theory, value = (str(arg) for arg in atom.arguments)
            table[(decision, theory)] = value
    return table


def step0_types(atoms):
    """Epistemic types of the step-0 assertion."""
    return sorted({str(a.arguments[2]) for a in atoms
                   if a.name == "type" and "inform" in str(a.arguments[1])})


def render(name, atoms):
    table = verdicts(atoms)
    lines = [f"## {name}", ""]
    lines.append(f"Step-0 assertion: {', '.join(step0_types(atoms))}.")
    lines.append("")
    lines.append("| Decision | " + " | ".join(THEORIES) + " |")
    lines.append("|---|" + "---|" * len(THEORIES))
    for key, label in DECISIONS.items():
        cells = [SYMBOLS[table[(key, t)]] for t in THEORIES]
        lines.append(f"| {label} | " + " | ".join(cells) + " |")
    lines.append("")
    return "\n".join(lines)


def main():
    sections = ["# Verdicts at step 1", "",
                "m: maxim, p: principialism, c: consequentialism; "
                "✓: permissible, ✗: impermissible.", ""]
    for name, extra in SCENARIOS.items():
        sections.append(render(name, solve(PROGRAMS + extra)))
    report = "\n".join(sections)
    (ROOT / "output.md").write_text(report, encoding="utf-8")
    print(report)


if __name__ == "__main__":
    main()
