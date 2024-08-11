# Verlet

Play with Verlet Physic Object

## Tech

- Odin lang dev-2024-07
- Raylib

```shell
odin test . -out:./bin/test
odin run sim.odin -file -define:RAYLIB_SHARED=true -extra-linker-flags:"-Wl,-rpath $(odin root)/vendor/raylib/macos-arm64" -out:./bin/sim
```

## Notes

The test does not work anymore since I apply constraint and collision handling
