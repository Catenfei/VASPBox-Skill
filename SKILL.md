---
name: vaspbox-vasp-task-manager
description: >
  Use this skill when operating VASP calculations on the user's single Linux server
  through VASPBox 3.0. Covers uploading/preparing VASP jobs, preflight checks,
  submission, queue monitoring, convergence/error diagnosis, safe restart, resource
  management, email/systemd checks, and vgbench-based parallel efficiency tuning.
  Do not use this skill for CP2K, Slurm multi-node jobs, or for changing scientific
  parameters without explicit user authorization.
---

# VASPBox VASP Task Manager

## Purpose

Use this skill to autonomously operate **VASPBox 3.0** on a single Linux compute server.

Primary objectives:

1. Put each VASP calculation in an isolated directory.
2. Verify inputs before submission.
3. Submit through VASPBox instead of launching raw `mpirun` jobs.
4. Record and track the VASPBox JOBID.
5. Monitor convergence and runtime health.
6. Distinguish successful completion, non-convergence, interruption, and hard failure.
7. Restart safely only when allowed.
8. Never modify scientific assumptions or physical parameters just to make a calculation run.
9. Use `vgbench` when the user asks to optimize CPU/NCORE/KPAR performance.

---

# Environment

Expected host:

```text
user: hpc
host: hpc
```

Expected hardware:

```text
192 physical CPU cores
2 sockets × 96 physical cores
8 NUMA nodes × 24 physical cores
~566 GB RAM
OpenMPI
```

Expected VASP executables:

```text
/home/hpc/software/vasp/VTST/vasp.6.5.1/bin/vasp_std
/home/hpc/software/vasp/VTST/vasp.6.5.1/bin/vasp_gam
/home/hpc/software/VTST/vasp.6.5.1/bin/vasp_ncl
```

VASPBox configuration/state:

```text
~/.vaspbox/config.json
~/.vaspbox/state.json
~/.vaspbox/daemon.log
```

Before first use in a session, check:

```bash
vgdoctor
```

Expected healthy signals include:

```text
192 physical cores
OpenMPI detected
mpirun OK
taskset OK
vasp_std OK
vasp_gam OK
vasp_ncl OK
```

---

# Non-negotiable safety boundary

## Allowed autonomous changes

You may autonomously change or select **resource-management parameters**:

```text
VASPBox core count
VASPBox priority
VASPBox soft memory reservation
VASP executable variant (std/gam/ncl) when unambiguous
NCORE/KPAR only after a valid vgbench recommendation/profile
```

You may autonomously:

```text
create directories
upload/copy user-provided input files
run vgdoctor
run vgcheck
run vgq/vginfo/vglog/vgtop/vgstat
submit VASPBox jobs
hold/release pending jobs
cancel an obvious accidental duplicate before useful computation has occurred
monitor calculations
archive outputs through VASPBox restart
perform vgrestart when explicitly authorized or when --retry already grants permission
```

## Never change without explicit user authorization

Do not autonomously alter:

```text
ENCUT
EDIFF
EDIFFG
ISMEAR
SIGMA
ISPIN
MAGMOM
LDAU / U values
IBRION
NSW
POTCAR choice/order
exchange-correlation functional
vdW correction
KPOINTS mesh
KSPACING
SOC/noncollinear physics
solvation settings
NEB physics settings
cell shape/volume
atomic coordinates
vacuum thickness
chemical composition
```

Do not silently delete:

```text
OUTCAR
OSZICAR
vasprun.xml
WAVECAR
CHGCAR
CONTCAR
historical calculation folders
```

Do not launch raw background VASP with `nohup`, `screen`, `tmux`, or direct `mpirun` when VASPBox is intended to manage those cores.

---

# Standard workflow

Follow this sequence unless the user explicitly requests something different.

```text
receive task
  ↓
identify/create calculation directory
  ↓
place input files
  ↓
verify required files
  ↓
vgcheck
  ↓
check resources / duplicate jobs
  ↓
choose cvauto or requested core count
  ↓
submit
  ↓
record JOBID
  ↓
monitor with vgq + vginfo
  ↓
diagnose final state
  ↓
restart only if permitted
  ↓
report result
```

---

# 1. Prepare/upload a task
Every active VASP calculation must use its own directory.

Recommended layout:

```text
/project/
├── calc_001/
│   ├── INCAR
│   ├── POSCAR
│   ├── POTCAR
│   └── KPOINTS
└── calc_002/
```

After upload/copy:

```bash
cd /path/to/calculation
ls -lh
```

Required in the normal case:

```text
INCAR
POSCAR
POTCAR
KPOINTS
```

A missing KPOINTS is acceptable only if INCAR intentionally uses `KSPACING`.

Never submit two active jobs from the same working directory.

---

# 2. Preflight check

If the user requested N cores:

```bash
vgcheck N
```

Examples:

```bash
vgcheck 48
vgcheck 96
```

If the user did not specify a core count:

1. If a valid `.vaspbox_profile.json` exists, prefer `vgauto`.
2. Else if a recent valid benchmark exists, prefer its `balanced` profile.
3. Else default to 96 physical cores on the current dual-9654 server.

If `vgcheck` reports a clear ERROR:

```text
DO NOT SUBMIT
```

If it reports only warnings:

- determine whether the warning is benign;
- if scientific interpretation is required, stop and report to the user.

---

# 3. Submission

## Basic

```bash
vg48
vg96
vg192
```

Or:

```bash
vg96 /path/to/calculation
```

## With metadata

Prefer project/tag metadata for long-running work:

```bash
vg96 \
  --project ZnI2 \
  --tag OPT
```

Optional soft memory reservation:

```bash
vg96 --mem 250G
```

Optional explicit retry allowance:

```bash
vg96 --retry 1
```

Preferred full example:

```bash
vg96 \
  --project ZnI2 \
  --tag OPT \
  --mem 250G \
  --retry 1
```

Capture the returned line:

```text
Submitted VASPBox job 1001
```

Store:

```text
JOBID
working directory
submission time
core count
project
tag
```

Never continue monitoring only by directory name when a JOBID exists.

---

# 4. Queue semantics

Use:

```bash
vgq
```

or:

```bash
vgqa
```

Interpret:

```text
RUNNING                 currently executing
PENDING                 waiting for resources
HOLD                    intentionally blocked
COMPLETED               normal VASP completion
NOT_CONVERGED           ionic/structural convergence not reached
ELECTRONIC_NOT_CONVERGED electronic SCF not converged
FAILED                  hard program failure
INCOMPLETE              output ended without valid completion
INTERRUPTED             execution was externally interrupted
CANCELLED               user/manager cancelled
```

`PENDING` is not an error.

---

# 5. Monitor a running job

Primary commands:

```bash
vgq
vginfo JOBID
```

Examples:

```bash
vginfo 1001
```

Use logs when needed:

```bash
vglog 1001
```

Do not use blocking `vglog 1001 -f` as the autonomous long-term monitor. Prefer periodic polling.

For a terminal overview:

```bash
vgtop
```

Recommended polling cadence for long jobs:

```text
first 10 minutes: every 1–2 minutes
after stable start: every 10–30 minutes
near expected completion: every 5–10 minutes
```

Do not poll every second.

Track:

```text
state
elapsed time
ionic step
electronic step
total energy
maximum force
SCF convergence
output freshness
disk availability
memory pressure
```

---

# 6. Detect normal completion

Prefer VASPBox status first:

```bash
vginfo JOBID
vgq
```

For confirmation:

```bash
tail -n 80 OUTCAR
```

A normally finished VASP run should have normal timing/accounting output near the end.

For a geometry optimization, do not claim "structure converged" unless convergence evidence supports it, e.g. the equivalent of:

```text
reached required accuracy
```

A clean program exit without ionic convergence is not the same as a converged structure.

---

# 7. Diagnose failures conservatively

Important error strings include:

```text
EDDDAV
BRMIX
ZBRENT
VERY BAD NEWS
internal error
segmentation fault
MPI_ABORT
Killed
Out of memory
```

Do not modify INCAR merely because one keyword appears.

Before acting:

1. inspect the VASPBox state;
2. read relevant output context;
3. identify the last valid ionic/electronic step;
4. verify whether CONTCAR is valid;
5. determine whether the issue is resource-related, numerical, or scientific.

If diagnosis would require changing physical/scientific settings, stop and report to the user.

---

# 8. Safe restart

Use:

```bash
vgrestart JOBID
```

Example:

```bash
vgrestart 1001
```

Expected behavior:

```text
archive old OUTCAR/OSZICAR/vasprun.xml
validate CONTCAR
copy CONTCAR -> POSCAR
preserve useful WAVECAR/CHGCAR
create a NEW JOBID
re-enter queue
```

Always record the new JOBID and switch monitoring to it.

You may autonomously restart only when:

```text
the user explicitly authorized continuation
OR
the original job was submitted with --retry
```

Default autonomous restart limit:

```text
1 restart
```

After repeated failure, stop and report. Never create an infinite restart loop.

---

# 9. Queue controls

Cancel:

```bash
vgcancel JOBID
```

Hold a waiting job:

```bash
vghold JOBID
```

Release:

```bash
vgrelease JOBID
```

Priority:

```bash
vgpriority JOBID 90
```

Move in queue:

```bash
vgmove JOBID top
vgmove JOBID bottom
```

Do not preempt a running scientific calculation merely to reorder pending work unless the user explicitly requests it.

---

# 10. Resource inspection

Per-job statistics:

```bash
vgstat JOBID
```

Historical recommendation:

```bash
vgrecommend
```

Project summary:

```bash
vgreport PROJECT
```

Use `vgrecommend` only as a rough history-based guide.

For controlled parallel tuning, use `vgbench`.

---

# 11. Parallel efficiency benchmark

Use when the user asks to determine the best:

```text
MPI cores + NCORE + KPAR
```

for the current system/hardware.

## Preview

```bash
vgbench --plan
```

Default core candidates on this server:

```text
48
96
192
```

NCORE candidates commonly include:

```text
4
8
16
24
```

plus other valid values inferred from atom count, NUMA size, socket size, and core-count divisors.

KPAR is only scanned when VASP detects multiple irreducible k-points.

## Run

Quick screening:

```bash
vgbench
```

More reliable:

```bash
vgbench --repeat 2
```

Exhaustive valid-combination scan:

```bash
vgbench --full --repeat 2
```

Custom search:

```bash
vgbench \
  --cores 48,96,192 \
  --ncore 4,8,16,24 \
  --kpar 1,2,4,8
```

VASPBox should reject invalid combinations such as those violating:

```text
cores % KPAR == 0
NKPTS % KPAR == 0
(cores / KPAR) % NCORE == 0
```

Benchmark jobs run in `.vaspbox_bench/...`, not directly over the production files.

---

# 12. Benchmark recommendation policy

Understand the three outputs:

```text
fastest
```

lowest wall time per measured step.

```text
efficient
```

lowest `core·seconds / step`.

```text
balanced
```

among configurations within the fastest solution's ~10% time window, prefer lower core cost.

Unless the user explicitly asks for maximum single-job speed, prefer:

```text
balanced
```

for production use on this dual-socket workstation.

Do not assume 192 cores is automatically best.

---

# 13. Apply benchmark/profile

Apply:

```bash
vgbench --apply balanced
```

Expected effects:

```text
backup current INCAR
write benchmark-recommended NCORE/KPAR
create .vaspbox_profile.json
```

View:

```bash
vgprofile
```

Then submit:

```bash
vgauto
```

A profile is valid only for sufficiently similar:

```text
INCAR scientific settings
POSCAR/system size
POTCAR
KPOINTS/KSPACING
VASP executable/build
MPI environment
CPU/NUMA topology
```

If VASPBox says the profile is stale:

```text
do not silently force it
```

Prefer a new benchmark.

---

# 14. Project/tag usage

For formal calculations, prefer adding metadata.

Examples:

```bash
vg96 --project ZnI2 --tag OPT
vg96 --project ZnI2 --tag DOS
vg48 --project LiS --tag ADS
```

Common tags:

```text
OPT
STATIC
DOS
BAND
BADER
CDD
ADS
NEB
AIMD
```

Filter:

```bash
vgq --project ZnI2
vgq --tag DOS
```

Report:

```bash
vgreport ZnI2
```

---

# 15. Batch submission

If each first-level subdirectory contains a complete VASP input set:

```bash
vaspbox batch 48
```

With metadata:

```bash
vaspbox batch 48 . --project ZnI2 --tag ADS
```

Core shortage should result in PENDING jobs, not oversubscription.

---

# 16. Scheduler daemon

Check:

```bash
vgservice status
```

Install user service if requested/appropriate:

```bash
vgservice install
```

Control:

```bash
vgservice start
vgservice stop
vgservice restart
vgservice remove
```

Pausing VASPBox scheduling:

```bash
vaspbox pause
```

must not kill already running VASP calculations.

Resume:

```bash
vaspbox resume
```

---

# 17. Email notifications

Check:

```bash
vgmail status
```

Test:

```bash
vgmail test
```

VASPBox may notify for:

```text
STARTED
COMPLETED
NOT_CONVERGED
FAILED
INTERRUPTED
CANCELLED
disk warnings
memory warnings
```

Do not duplicate every VASPBox email with separate noisy notifications unless requested.

---

# 18. Server safety

VASPBox CPU allocation is based on `taskset`, not administrator-level Slurm/cgroup isolation.

Memory reservations are soft scheduling reservations, not kernel hard limits.

Before launching major work, watch for unmanaged competing VASP processes:

```bash
pgrep -a vasp
```

or:

```bash
ps aux | grep '[v]asp'
```

If non-VASPBox jobs are consuming managed CPUs, do not blindly add more work.

Do not run Slurm-controlled VASP jobs and VASPBox-controlled jobs over the same physical cores at the same time.

---

# 19. Monitoring record

For autonomous operations, maintain concise notes such as:

```text
JOBID
directory
project/tag
cores
submit time
start time
last observed state
ionic step
energy/force snapshot
restart relationship
final state
```

Do not copy the entire OUTCAR into the activity record.

---

# 20. Final report format

## Successful optimization

Report:

```text
JOBID
directory
COMPLETED
cores
elapsed time
whether ionic convergence was achieved
final energy
final maximum force when available
important output files
whether any input/scientific parameters were changed
```

## Non-converged optimization

Report:

```text
JOBID
NOT_CONVERGED
last ionic step
last maximum force
whether CONTCAR is valid
whether restart is safe
state clearly that scientific INCAR parameters were not changed
```

## Failure

Report:

```text
JOBID
FAILED/INCOMPLETE/INTERRUPTED
main error evidence
last known valid step
CONTCAR validity
what autonomous actions were taken
whether the task was stopped awaiting user scientific judgment
```

---

# 21. Autonomous decision tree

Use this logic:

```text
Are input files complete?
  no -> stop and report
  yes
   ↓
Does vgcheck have blocking errors?
  yes -> stop and report
  no
   ↓
Is there a valid benchmark profile?
  yes -> vgauto
  no -> use user cores, otherwise 96
   ↓
Submit and record JOBID
   ↓
RUNNING?
  yes -> monitor
  no, PENDING -> wait
   ↓
COMPLETED?
  yes -> verify convergence and report
  no
   ↓
NOT_CONVERGED?
  yes -> restart only if authorized
  no
   ↓
FAILED/INCOMPLETE/INTERRUPTED?
  diagnose
   ↓
resource/operational issue with safe recovery?
  yes -> recover only within granted retry policy
  no -> stop and report
```

---

# 22. Golden rules

Always follow:

```text
Check before submit.
Record every JOBID.
Monitor state, not guesses.
Diagnose before restart.
Never confuse program completion with scientific convergence.
Never change scientific parameters without permission.
Never infinite-retry.
Preserve old outputs.
Prefer vgauto after a valid benchmark profile.
Use VASPBox, not unmanaged raw mpirun, for managed production jobs.
```
