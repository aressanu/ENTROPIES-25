# run_oriconf.sh  i  run_vib.sh  (també té nsteps_vals)
T_vals=(...)
P_vals=(...)
nsteps_vals=(...)   # només a run_vib.sh
```

L'estructura que quedarà a la carpeta mare un cop tot hagi corregut:
```
projecte/
├── Entropy_summary.txt    ← S_conf + S_ori de totes les subcarpetes
├── S_vib.txt              ← S_vib de totes les subcarpetes
├── P1/
│   ├── run_oriconf.sh
│   ├── run_vib.sh
│   ├── entropy_oriconf.py
│   ├── svib_trr.py
│   ├── svib_mitjana.py
│   ├── NPT.mdp  /  NPT_v.mdp  (mai es modifiquen)
│   └── ...
├── P2/ ...
