# Bundled runtime layout

This folder is for an optional **portable, offline Python runtime**.
The app does **not** commit Python binaries to git, but the launchers can use
this layout when you copy a runtime onto a USB stick.

## Expected structure

```text
runtime/
├── README.md
├── START-HERE.md
└── python/
    ├── .gitkeep
    └── bin/
        ├── .gitkeep
        ├── python3        # macOS / Linux
        └── python.exe     # Windows
```

## Launcher lookup order

- `serve.sh` checks:
  1. `runtime/python/bin/python3`
  2. `runtime/python/bin/python`
  3. `INTERVENTION_PYTHON`
  4. system Python
- `launch-macos.command` checks:
  1. `runtime\\python\\bin\\python3`
  2. `runtime\\python\\bin\\python`
  3. `INTERVENTION_PYTHON`
  4. system Python
- `launch-windows.bat` checks:
  1. `py -3`
  2. `python3`
  3. `python`
  4. `runtime\\python\\python.exe`
  5. `runtime\\python\\bin\\python.exe`
- `launch-windows.cmd` is a simple wrapper for the same launcher.

## Notes

- Keep the runtime local to the stick; do not commit the interpreter files.
- The database lives in `./data/intervention_reports.sqlite3`.
- If you bundle a runtime, test both macOS and Windows launchers once on the target OS.
- The single polished entry point is `START-HERE.md`.
