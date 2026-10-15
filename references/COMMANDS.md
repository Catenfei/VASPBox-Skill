# VASPBox Command Reference

## Health
```bash
vgdoctor
vgcheck 48
vgservice status
vgmail status
```

## Submit
```bash
vg48
vg96
vg192
vgauto
vg96 --project ZnI2 --tag OPT --mem 250G --retry 1
```

## Queue / monitor
```bash
vgq
vgqa
vginfo 1001
vgwatch 1001
vglog 1001
vglog 1001 -f
vgstat 1001
vgtop
```

## Control
```bash
vgcancel 1001
vghold 1001
vgrelease 1001
vgpriority 1001 90
vgmove 1001 top
vgrestart 1001
```

## Benchmark
```bash
vgbench --plan
vgbench
vgbench --repeat 2
vgbench --full --repeat 2
vgbench --apply balanced
vgprofile
vgauto
```

## Project/history
```bash
vgq --project ZnI2
vgreport ZnI2
vgrecommend
vaspbox clean --keep 100
```

## Scheduler
```bash
vgservice install
vgservice status
vgservice restart
vaspbox pause
vaspbox resume
```
