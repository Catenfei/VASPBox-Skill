# VASPBox Skill

A Codex skill for operating **VASPBox 3.0** on a single Linux VASP server.

It defines a safe autonomous workflow for:

- preparing and checking VASP inputs;
- submitting jobs through VASPBox;
- recording and monitoring JOBIDs;
- diagnosing convergence and runtime failures;
- performing authorized safe restarts;
- managing queue/resources;
- running `vgbench` to optimize cores, `NCORE`, and `KPAR`;
- using `vgprofile` / `vgauto` for validated production settings.

## Structure

```text
VASPBox-Skill/
├── README.md
├── SKILL.md
├── references/
│   └── COMMANDS.md
└── scripts/
    └── check_environment.sh
```

## Quick start

Clone the repository and make the environment checker executable:

```bash
git clone https://github.com/Catenfei/VASPBox-Skill.git
cd VASPBox-Skill
chmod +x scripts/check_environment.sh
./scripts/check_environment.sh
```

For Codex, use `SKILL.md` as the primary operating contract.

## Safety principle

The skill allows Codex to automate execution, monitoring, diagnosis, resource selection, and authorized restart operations, but it must **not silently change scientific VASP parameters or physical models** merely to make a calculation run.

## Target environment

Current reference environment:

- VASPBox 3.0
- VASP 6.5.1 + VTST
- OpenMPI
- 192 physical CPU cores
- 2 × 96-core sockets
- 8 NUMA nodes × 24 cores
- ~566 GB RAM

See `SKILL.md` for the full workflow and safety rules.
