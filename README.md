# Bun lockfile feature matrix

This fixture matrix checks whether `aube install` preserves a Bun-generated `bun.lock` byte-for-byte across several Bun lockfile features.

Run:

```sh
cd ~/random/aube-bun-lock-feature-matrix
./run-matrix.sh
```

The script writes generated fixtures to `cases/` and outputs to `results/`.

Important result files:

- `results/summary.txt`
- `results/<case>/sha256.txt`
- `results/<case>/line-counts.txt`
- `results/<case>/after-aube.diff`
- `results/<case>/after-aube-force.diff`: diff after resetting to Bun's original lockfile and running `aube install --force`
- `results/<case>/after-bun-force.diff`: diff after resetting to Bun's original lockfile and running `bun install --force`
- `results/<case>/aube-force-vs-bun-force.diff`: direct comparison of `aube install --force` output vs. `bun install --force` output from the same original lockfile
- `results/<case>/after-bun-again.diff`

The expected behavior for compatibility is that `before-bun.lock` and `after-aube-bun.lock` are byte-for-byte identical for every supported case.

## Current findings

Tested locally with `bun 1.3.12` and `aube 1.0.0`.

Each case starts by running `bun install` to create `before-bun.lock`. For the `--force` checks, the script resets back to that exact lockfile and runs either `aube install --force` or `bun install --force`.

`bun install --force` leaves `bun.lock` byte-for-byte unchanged in every case where Bun can install the fixture. That means the `aube install --force` changes below are not just Bun's own forced-install behavior.

Summary:

| Case | Result |
| --- | --- |
| `simple-exact` | unchanged |
| `alias-npm` | plain `aube install` leaves `bun.lock` unchanged; `aube install --force` changes it, while `bun install --force` does not |
| `named-catalogs` | plain `aube install` leaves `bun.lock` unchanged; `aube install --force` changes it, while `bun install --force` does not |
| `optional-platforms` | plain `aube install` leaves `bun.lock` unchanged; `aube install --force` changes it, while `bun install --force` does not |
| `overrides-resolutions` | plain `aube install` changes `bun.lock`; `aube install --force` also changes it, while `bun install --force` does not |
| `patched-dependency` | plain `aube install` leaves `bun.lock` unchanged; `aube install --force` changes it, while `bun install --force` does not |
| `peer-optional` | plain `aube install` leaves `bun.lock` unchanged; `aube install --force` changes it, while `bun install --force` does not |
| `trusted-builds` | plain `aube install` leaves `bun.lock` unchanged; `aube install --force` changes it, while `bun install --force` does not |
| `workspace-catalog-only` | plain `aube install` leaves `bun.lock` unchanged; `aube install --force` changes it, while `bun install --force` does not |
| `workspace-catalog-overrides` | plain `aube install` changes `bun.lock`; follow-up `bun install` still does not restore original bytes; `aube install --force` changes it, while `bun install --force` does not |
| `workspace-protocol-only` | `aube install` fails |
| `file-directory` | `aube install` fails |
| `local-tarball` | `aube install` fails |
| `tarball-url` | `aube install` fails |
| `github-shorthand` | `aube install` fails |
| `link-directory` | Bun rejects this fixture before Aube runs |
| `local-git` | Bun rejects this fixture before Aube runs |

The `link-directory` and `local-git` probes are not counted as Aube issues because this exact fixture is rejected by Bun itself.

## Observed Incorrectness Examples

Each example below represents a distinct failure mode observed in the matrix.

### Specifier resolution failures

Aube can turn Bun-supported dependency specifiers into invalid registry tarball URLs.

Local `file:` directories:

```txt
file:vendor/local-helper -> https://registry.npmjs.org/local-helper/-/local-helper-file:vendor/local-helper.tgz
```

Local `file:` tarballs:

```txt
file:tarballs/local-helper-1.0.0.tgz -> https://registry.npmjs.org/local-helper/-/local-helper-tarballs/local-helper-1.0.0.tgz.tgz
```

HTTP tarball specs:

```txt
https://registry.npmjs.org/is-number/-/is-number-7.0.0.tgz -> https://registry.npmjs.org/is-number/-/is-number-https://registry.npmjs.org/is-number/-/is-number-7.0.0.tgz.tgz
```

GitHub shorthand specs:

```txt
github:jonschlinkert/is-number#7.0.0 -> https://registry.npmjs.org/is-number/-/is-number-github:jonschlinkert/is-number
```

Workspace protocol specs:

```txt
workspace:* -> https://registry.npmjs.org/sample-lib/-/sample-lib-workspace:packages/lib.tgz
```

### Top-level lock metadata loss

Aube can drop top-level metadata that Bun records in `bun.lock`.

`overrides` are dropped from `bun.lock` after normal `aube install` in `overrides-resolutions`:

```diff
-  "overrides": {
-    "ms": "2.1.2",
-  },
```

`catalog` / `catalogs` are dropped in `named-catalogs` after resetting to Bun's original lockfile and running `aube install --force`. Running `bun install --force` from the same starting lockfile leaves this metadata intact:

```diff
-  "catalog": {
-    "typescript": "5.9.3",
-  },
-  "catalogs": {
-    "runtime": {
-      "is-number": "7.0.0",
-    },
-  },
```

`patchedDependencies` are dropped in `patched-dependency` after resetting to Bun's original lockfile and running `aube install --force`. Running `bun install --force` from the same starting lockfile leaves this metadata intact:

```diff
-  "patchedDependencies": {
-    "is-number@7.0.0": "patches/is-number@7.0.0.patch",
-  },
```

`trustedDependencies` are dropped in `trusted-builds` after resetting to Bun's original lockfile and running `aube install --force`. Running `bun install --force` from the same starting lockfile leaves this metadata intact:

```diff
-  "trustedDependencies": [
-    "esbuild",
-  ],
```

### Workspace metadata loss

Workspace package entries can disappear even though Bun records them in `bun.lock`.

Workspace package entries are dropped in `workspace-catalog-only` after resetting to Bun's original lockfile and running `aube install --force`. Running `bun install --force` from the same starting lockfile keeps the workspace entry:

```diff
-    "sample-app": ["sample-app@workspace:packages/app"],
```

In `workspace-catalog-overrides`, plain `aube install` drops workspace package entries; a follow-up plain `bun install` restores those entries but does not restore the original peer metadata bytes:

```diff
-    "sample-app": ["sample-app@workspace:packages/app"],
-    "sample-lib": ["sample-lib@workspace:packages/lib"],
```

### Package identity and metadata rewrites

Aube can rewrite package entries in ways that differ from Bun's serializer.

NPM aliases are serialized with the alias name as the resolved package identity in `alias-npm` after resetting to Bun's original lockfile and running `aube install --force`. Running `bun install --force` from the same starting lockfile preserves Bun's original alias representation:

```diff
-    "number-check": ["is-number@7.0.0", "", {}, "sha512-..."],
+    "number-check": ["number-check@7.0.0", "", {}, "sha512-..."],
```

Peer dependency metadata is collapsed into concrete dependencies in `peer-optional` after resetting to Bun's original lockfile and running `aube install --force`. Running `bun install --force` from the same starting lockfile preserves the peer metadata:

```diff
-    "@vitejs/plugin-react": ["@vitejs/plugin-react@5.1.2", "", { "dependencies": { ... }, "peerDependencies": { "vite": "^4.2.0 || ^5.0.0 || ^6.0.0 || ^7.0.0" } }, "sha512-..."],
+    "@vitejs/plugin-react": ["@vitejs/plugin-react@5.1.2", "", { "dependencies": { ..., "vite": "8.0.2" } }, "sha512-..."],
```

Optional peer metadata is removed instead of preserved:

```diff
-    "fdir": ["fdir@6.5.0", "", { "peerDependencies": { "picomatch": "^3 || ^4" }, "optionalPeers": ["picomatch"] }, "sha512-..."],
+    "fdir": ["fdir@6.5.0", "", { "dependencies": { "picomatch": "4.0.4" } }, "sha512-..."],
```

Binary metadata is serialized differently:

```diff
-    "@babel/parser": ["@babel/parser@7.29.2", "", { "dependencies": { ... }, "bin": "./bin/babel-parser.js" }, "sha512-..."],
+    "@babel/parser": ["@babel/parser@7.29.2", "", { "dependencies": { ... }, "bin": { "@babel/parser": "./bin/babel-parser.js" } }, "sha512-..."],
```

### Platform package pruning

Aube can rewrite Bun's cross-platform lock entries into current-platform-only entries.

Optional platform packages are pruned in `optional-platforms` and `trusted-builds` after resetting to Bun's original lockfile and running `aube install --force`; `bun install --force` from the same starting lockfile still records all platforms. Example:

```diff
-    "@esbuild/darwin-arm64": ["@esbuild/darwin-arm64@0.27.2", "", { "os": "darwin", "cpu": "arm64" }, "sha512-..."],
-    "@esbuild/win32-x64": ["@esbuild/win32-x64@0.27.2", "", { "os": "win32", "cpu": "x64" }, "sha512-..."],
-    "@esbuild/linux-x64": ["@esbuild/linux-x64@0.27.2", "", { "os": "linux", "cpu": "x64" }, "sha512-..."],
+    "@esbuild/linux-x64": ["@esbuild/linux-x64@0.27.2", "", {}, "sha512-..."],
```

### Resolved version churn

Aube can change resolved versions while rewriting `bun.lock`.

Transitive versions can change when Aube writes `bun.lock`. Example from `peer-optional` after resetting to Bun's original lockfile and running `aube install --force`; `bun install --force` from the same starting lockfile preserves Bun's original transitive version:

```diff
-    "electron-to-chromium": ["electron-to-chromium@1.5.344", "", {}, "sha512-..."],
+    "electron-to-chromium": ["electron-to-chromium@1.5.343", "", {}, "sha512-..."],
```
