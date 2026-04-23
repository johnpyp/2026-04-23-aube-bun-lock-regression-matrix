#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CASES_DIR="$ROOT/cases"
RESULTS_DIR="$ROOT/results"

rm -rf "$CASES_DIR" "$RESULTS_DIR"
mkdir -p "$CASES_DIR" "$RESULTS_DIR"

write_package_json() {
  local dir="$1"
  local body="$2"
  mkdir -p "$dir"
  printf '%s\n' "$body" > "$dir/package.json"
}

write_local_package() {
  local dir="$1"
  local name="$2"
  mkdir -p "$dir"
  cat > "$dir/package.json" <<JSON
{
  "name": "$name",
  "version": "1.0.0",
  "type": "module",
  "exports": "./index.js"
}
JSON
  cat > "$dir/index.js" <<JS
export function label() {
  return "$name";
}
JS
}

create_simple_exact() {
  write_package_json "$CASES_DIR/simple-exact" '{
  "name": "simple-exact",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "is-number": "7.0.0"
  }
}'
}

create_peer_optional() {
  write_package_json "$CASES_DIR/peer-optional" '{
  "name": "peer-optional",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "@vitejs/plugin-react": "5.1.2",
    "vite": "8.0.2"
  },
  "devDependencies": {
    "@types/node": "24.10.10"
  }
}'
}

create_workspace_catalog_overrides() {
  local dir="$CASES_DIR/workspace-catalog-overrides"
  mkdir -p "$dir/packages/app" "$dir/packages/lib"
  write_package_json "$dir" '{
  "name": "workspace-catalog-overrides",
  "version": "1.0.0",
  "private": true,
  "workspaces": {
    "packages": [
      "packages/*"
    ],
    "catalog": {
      "cookie": "1.1.1",
      "react": "19.2.4",
      "react-dom": "19.2.4",
      "react-router": "7.13.2",
      "typescript": "5.9.3",
      "zod": "4.2.0"
    }
  },
  "overrides": {
    "cookie": "1.1.1"
  },
  "devDependencies": {
    "typescript": "catalog:"
  }
}'
  write_package_json "$dir/packages/app" '{
  "name": "sample-app",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "cookie": "catalog:",
    "react": "catalog:",
    "react-dom": "catalog:",
    "react-router": "catalog:",
    "sample-lib": "workspace:*"
  }
}'
  write_package_json "$dir/packages/lib" '{
  "name": "sample-lib",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "zod": "catalog:"
  }
}'
}

create_named_catalogs() {
  write_package_json "$CASES_DIR/named-catalogs" '{
  "name": "named-catalogs",
  "version": "1.0.0",
  "private": true,
  "workspaces": {
    "packages": [
      "packages/*"
    ],
    "catalog": {
      "typescript": "5.9.3"
    },
    "catalogs": {
      "runtime": {
        "is-number": "7.0.0"
      }
    }
  },
  "dependencies": {
    "is-number": "catalog:runtime"
  },
  "devDependencies": {
    "typescript": "catalog:"
  }
}'
}

create_workspace_protocol_only() {
  local dir="$CASES_DIR/workspace-protocol-only"
  mkdir -p "$dir/packages/app" "$dir/packages/lib"
  write_package_json "$dir" '{
  "name": "workspace-protocol-only",
  "version": "1.0.0",
  "private": true,
  "workspaces": [
    "packages/*"
  ]
}'
  write_package_json "$dir/packages/app" '{
  "name": "sample-app",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "sample-lib": "workspace:*"
  }
}'
  write_package_json "$dir/packages/lib" '{
  "name": "sample-lib",
  "version": "1.0.0",
  "private": true
}'
}

create_workspace_catalog_only() {
  local dir="$CASES_DIR/workspace-catalog-only"
  mkdir -p "$dir/packages/app"
  write_package_json "$dir" '{
  "name": "workspace-catalog-only",
  "version": "1.0.0",
  "private": true,
  "workspaces": {
    "packages": [
      "packages/*"
    ],
    "catalog": {
      "is-number": "7.0.0"
    }
  }
}'
  write_package_json "$dir/packages/app" '{
  "name": "sample-app",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "is-number": "catalog:"
  }
}'
}

create_overrides_resolutions() {
  write_package_json "$CASES_DIR/overrides-resolutions" '{
  "name": "overrides-resolutions",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "debug": "4.4.3"
  },
  "overrides": {
    "ms": "2.1.2"
  },
  "resolutions": {
    "ms": "2.1.2"
  }
}'
}

create_alias_npm() {
  write_package_json "$CASES_DIR/alias-npm" '{
  "name": "alias-npm",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "number-check": "npm:is-number@7.0.0"
  }
}'
}

create_tarball_url() {
  write_package_json "$CASES_DIR/tarball-url" '{
  "name": "tarball-url",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "is-number": "https://registry.npmjs.org/is-number/-/is-number-7.0.0.tgz"
  }
}'
}

create_file_directory() {
  local dir="$CASES_DIR/file-directory"
  write_local_package "$dir/vendor/local-helper" "local-helper"
  write_package_json "$dir" '{
  "name": "file-directory",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "local-helper": "file:vendor/local-helper"
  }
}'
}

create_link_directory() {
  local dir="$CASES_DIR/link-directory"
  write_local_package "$dir/vendor/local-helper" "local-helper"
  write_package_json "$dir" '{
  "name": "link-directory",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "local-helper": "link:vendor/local-helper"
  }
}'
}

create_local_tarball() {
  local dir="$CASES_DIR/local-tarball"
  write_local_package "$dir/vendor/local-helper" "local-helper"
  mkdir -p "$dir/tarballs"
  (
    cd "$dir/vendor/local-helper"
    bun pm pack --destination "$dir/tarballs" --ignore-scripts --quiet > /dev/null
  )
  write_package_json "$dir" '{
  "name": "local-tarball",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "local-helper": "file:tarballs/local-helper-1.0.0.tgz"
  }
}'
}

create_local_git() {
  local dir="$CASES_DIR/local-git"
  write_local_package "$dir/vendor/git-helper" "git-helper"
  (
    cd "$dir/vendor/git-helper"
    git init -q
    git config user.email "fixture@example.test"
    git config user.name "Fixture"
    git config commit.gpgsign false
    git add package.json index.js
    git commit -q -m "initial"
  )
  local commit
  commit="$(cd "$dir/vendor/git-helper" && git rev-parse HEAD)"
  write_package_json "$dir" "{
  \"name\": \"local-git\",
  \"version\": \"1.0.0\",
  \"private\": true,
  \"dependencies\": {
    \"git-helper\": \"git+file://$dir/vendor/git-helper#$commit\"
  }
}"
}

create_github_shorthand() {
  write_package_json "$CASES_DIR/github-shorthand" '{
  "name": "github-shorthand",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "is-number": "github:jonschlinkert/is-number#7.0.0"
  }
}'
}

create_patched_dependency() {
  local dir="$CASES_DIR/patched-dependency"
  mkdir -p "$dir/patches"
  write_package_json "$dir" '{
  "name": "patched-dependency",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "is-number": "7.0.0"
  },
  "patchedDependencies": {
    "is-number@7.0.0": "patches/is-number@7.0.0.patch"
  }
}'
  cat > "$dir/patches/is-number@7.0.0.patch" <<'PATCH'
diff --git a/index.js b/index.js
index 27f19b757f7c1186b92c405a213bf0dd9b6cbe95..0e1cda761b1a13f02501510df14bfc38af4850cb 100644
--- a/index.js
+++ b/index.js
@@ -16,3 +16,5 @@ module.exports = function(num) {
   }
   return false;
 };
+
+// patched for lockfile repro
PATCH
}

create_trusted_builds() {
  write_package_json "$CASES_DIR/trusted-builds" '{
  "name": "trusted-builds",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "esbuild": "0.27.2"
  },
  "trustedDependencies": [
    "esbuild"
  ]
}'
}

create_optional_platforms() {
  write_package_json "$CASES_DIR/optional-platforms" '{
  "name": "optional-platforms",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "lightningcss": "1.32.0",
    "rolldown": "1.0.0-rc.11"
  }
}'
}

run_case() {
  local name="$1"
  local dir="$CASES_DIR/$name"
  local result="$RESULTS_DIR/$name"
  mkdir -p "$result"

  rm -rf "$dir/node_modules" "$dir/bun.lock" "$dir/aube-lock.yaml"

  if ! (cd "$dir" && bun install > "$result/bun-install.log" 2>&1); then
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "bun-install-failed" "" "" "" "" >> "$RESULTS_DIR/summary.tsv"
    return
  fi

  cp "$dir/bun.lock" "$result/before-bun.lock"

  if ! (cd "$dir" && aube install > "$result/aube-install.log" 2>&1); then
    cp "$dir/bun.lock" "$result/after-aube-bun.lock"
    git diff --no-index -- "$result/before-bun.lock" "$result/after-aube-bun.lock" > "$result/after-aube.diff" || true
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "aube-install-failed" "" "" "" "" >> "$RESULTS_DIR/summary.tsv"
    return
  fi

  cp "$dir/bun.lock" "$result/after-aube-bun.lock"

  if ! (cd "$dir" && bun install > "$result/bun-after-aube.log" 2>&1); then
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "bun-after-aube-failed" "" "" "" "" >> "$RESULTS_DIR/summary.tsv"
    return
  fi

  cp "$dir/bun.lock" "$result/after-bun-again.lock"

  git diff --no-index -- "$result/before-bun.lock" "$result/after-aube-bun.lock" > "$result/after-aube.diff" || true
  git diff --no-index -- "$result/before-bun.lock" "$result/after-bun-again.lock" > "$result/after-bun-again.diff" || true

  rm -rf "$dir/node_modules"
  cp "$result/before-bun.lock" "$dir/bun.lock"
  local aube_force_lock_status="aube-force-unchanged"
  if ! (cd "$dir" && aube install --force > "$result/aube-force-install.log" 2>&1); then
    aube_force_lock_status="aube-force-failed"
    cp "$dir/bun.lock" "$result/after-aube-force-bun.lock"
  else
    cp "$dir/bun.lock" "$result/after-aube-force-bun.lock"
    if ! cmp -s "$result/before-bun.lock" "$result/after-aube-force-bun.lock"; then
      aube_force_lock_status="aube-force-changed"
    fi
  fi
  git diff --no-index -- "$result/before-bun.lock" "$result/after-aube-force-bun.lock" > "$result/after-aube-force.diff" || true

  rm -rf "$dir/node_modules"
  cp "$result/before-bun.lock" "$dir/bun.lock"
  local bun_force_lock_status="bun-force-unchanged"
  if ! (cd "$dir" && bun install --force > "$result/bun-force-install.log" 2>&1); then
    bun_force_lock_status="bun-force-failed"
    cp "$dir/bun.lock" "$result/after-bun-force.lock"
  else
    cp "$dir/bun.lock" "$result/after-bun-force.lock"
    if ! cmp -s "$result/before-bun.lock" "$result/after-bun-force.lock"; then
      bun_force_lock_status="bun-force-changed"
    fi
  fi
  git diff --no-index -- "$result/before-bun.lock" "$result/after-bun-force.lock" > "$result/after-bun-force.diff" || true
  git diff --no-index -- "$result/after-bun-force.lock" "$result/after-aube-force-bun.lock" > "$result/aube-force-vs-bun-force.diff" || true
  sha256sum "$result/before-bun.lock" "$result/after-aube-bun.lock" "$result/after-bun-again.lock" "$result/after-aube-force-bun.lock" "$result/after-bun-force.lock" > "$result/sha256.txt"
  wc -l "$result/before-bun.lock" "$result/after-aube-bun.lock" "$result/after-bun-again.lock" "$result/after-aube-force-bun.lock" "$result/after-bun-force.lock" > "$result/line-counts.txt"

  local plain_aube_lock_status="plain-aube-unchanged"
  if ! cmp -s "$result/before-bun.lock" "$result/after-aube-bun.lock"; then
    plain_aube_lock_status="plain-aube-changed"
  fi

  local bun_after_plain_aube_lock_status="bun-after-plain-aube-same"
  if ! cmp -s "$result/before-bun.lock" "$result/after-bun-again.lock"; then
    bun_after_plain_aube_lock_status="bun-after-plain-aube-changed"
  fi

  local aube_force_vs_bun_force_lock_status="aube-force-matches-bun-force"
  if ! cmp -s "$result/after-bun-force.lock" "$result/after-aube-force-bun.lock"; then
    aube_force_vs_bun_force_lock_status="aube-force-differs-from-bun-force"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$plain_aube_lock_status" "$bun_after_plain_aube_lock_status" "$aube_force_lock_status" "$bun_force_lock_status" "$aube_force_vs_bun_force_lock_status" >> "$RESULTS_DIR/summary.tsv"
}

create_simple_exact
create_peer_optional
create_workspace_catalog_overrides
create_named_catalogs
create_workspace_protocol_only
create_workspace_catalog_only
create_overrides_resolutions
create_alias_npm
create_tarball_url
create_file_directory
create_link_directory
create_local_tarball
create_local_git
create_github_shorthand
create_patched_dependency
create_trusted_builds
create_optional_platforms

printf 'case\tplain_aube_lock_status\tbun_after_plain_aube_lock_status\taube_force_lock_status\tbun_force_lock_status\taube_force_vs_bun_force_lock_status\n' > "$RESULTS_DIR/summary.tsv"

for case_dir in "$CASES_DIR"/*; do
  run_case "$(basename "$case_dir")"
done

column -t -s $'\t' "$RESULTS_DIR/summary.tsv" | tee "$RESULTS_DIR/summary.txt"
