#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_MANIFEST="${SCRIPT_DIR}/../../../.repo/manifests/default.xml"
MANIFEST_SNIPPET="${SCRIPT_DIR}/../../../.repo/manifests/snippets/witaqua.xml"
GERRIT_REMOTE="gerrit"
UPSTREAM_REMOTE="upstream"
EXCLUDE_REMOTES=("gitlab")
EXCLUDE_PATHS=(
    "witaqua/hudson"
    "witaqua/wiki"
    "witaqua/www"
    "external/bouncycastle"
    "external/mejiro"
    "packages/apps/BtHelper"
    "packages/apps/FaceUnlock"
    "packages/apps/FelicaService"
    "packages/apps/LMOSystemUIClock"
    "packages/apps/WitAquaMagic"
    "packages/apps/XiaomiTWS"
    "packages/apps/XiaomiTWS/xiaomi-sdk"
    "prebuilts/custom-sdk"
    "vendor/witaqua"
)

# Helper Function: Check if an item is in an array
contains_element() {
    local e match="$1"
    shift
    for e; do [[ "$e" == "$match" ]] && return 0; done
    return 1
}

# Try to resolve BASE_DIR using Android build environment (gettop)
if ! command -v gettop &> /dev/null; then
    POSSIBLE_ENVSETUP="${SCRIPT_DIR}/../../../build/envsetup.sh"
    if [ -f "${POSSIBLE_ENVSETUP}" ]; then
        echo "=> Sourcing envsetup.sh to enable build environment..."
        . "${POSSIBLE_ENVSETUP}" &> /dev/null
    fi
fi

# Strictly assign BASE_DIR using gettop. Error out if unavailable.
if command -v gettop &> /dev/null && [ -n "$(gettop)" ]; then
    BASE_DIR="$(gettop)"
    echo "=> Root directory resolved via 'gettop': ${BASE_DIR}"
else
    echo "[-] Error: Android build environment is not initialized."
    echo "    Please run 'source build/envsetup.sh' and setup your target first."
    exit 1
fi

# Resolve absolute paths for manifest files
DEFAULT_MANIFEST_FILE="$(cd "$(dirname "${DEFAULT_MANIFEST}")" 2>/dev/null && pwd)/$(basename "${DEFAULT_MANIFEST}")"
MANIFEST_FILE="$(cd "$(dirname "${MANIFEST_SNIPPET}")" 2>/dev/null && pwd)/$(basename "${MANIFEST_SNIPPET}")"

if [ ! -f "${DEFAULT_MANIFEST_FILE}" ]; then
    echo "[-] Error: Default manifest file not found at: ${DEFAULT_MANIFEST_FILE}"
    exit 1
fi

if [ ! -f "${MANIFEST_FILE}" ]; then
    echo "[-] Error: Manifest snippet file not found at: ${MANIFEST_FILE}"
    exit 1
fi

# Extract Default Upstream Branch from default.xml
DEFAULT_UPSTREAM_BRANCH=$(tr '\n' ' ' < "${DEFAULT_MANIFEST_FILE}" | sed -n 's/.*<default[^>]*revision="\([^"]*\)".*/\1/p' | sed 's|^refs/heads/||')

if [ -z "${DEFAULT_UPSTREAM_BRANCH}" ]; then
    echo "[-] Error: Could not parse default revision from ${DEFAULT_MANIFEST_FILE}"
    exit 1
fi

# Extract Default Target Branch from witaqua.xml
DEFAULT_TARGET_BRANCH=$(tr '\n' ' ' < "${MANIFEST_FILE}" | sed -n 's/.*<remote[^>]*name="witaqua"[^>]*revision="\([^"]*\)".*/\1/p' | sed 's|^refs/heads/||')

# Handle the Gerrit topic name argument
if [ -n "$1" ]; then
    TOPIC_NAME="$1"
    echo "=> Using user-specified topic: ${TOPIC_NAME}"
else
    TOPIC_NAME="merge-upstream-$(date +%Y%m%d)"
    echo "=> No argument provided. Using default topic: ${TOPIC_NAME}"
fi

echo "=== Starting Upstream Merge & Gerrit Push Process from Manifest ==="
echo "=> Loading Default Manifest: ${DEFAULT_MANIFEST_FILE}"
echo "=> Loading WitAqua Manifest:  ${MANIFEST_FILE}"
echo "=> Parsed Default Upstream Branch: ${DEFAULT_UPSTREAM_BRANCH}"
echo "=> Parsed Default Target Branch:   ${DEFAULT_TARGET_BRANCH}"

# Progress file path to tracking completed repositories
PROGRESS_FILE="${BASE_DIR}/.merge_from_manifest_progress"

if [ -f "${PROGRESS_FILE}" ]; then
    echo "=> Found active progress file. Resuming previous session..."
fi

# Parse <project ... /> tags from witaqua.xml
grep -E '<project[[:space:]]' "${MANIFEST_FILE}" | while read -r line; do

    # Extract attributes from XML line
    REPO_PATH=$(echo "$line" | sed -n 's/.*path="\([^"]*\)".*/\1/p')
    REPO_REV=$(echo "$line" | sed -n 's/.*revision="\([^"]*\)".*/\1/p')
    REPO_REMOTE=$(echo "$line" | sed -n 's/.*remote="\([^"]*\)".*/\1/p')

    # Skip if path is missing
    [ -z "${REPO_PATH}" ] && continue

    # 1. Skip if remote matches EXCLUDE_REMOTES
    if contains_element "${REPO_REMOTE}" "${EXCLUDE_REMOTES[@]}"; then
        echo "--------------------------------------------------"
        echo "Skipping: ${REPO_PATH} (Excluded remote: ${REPO_REMOTE})"
        echo "--------------------------------------------------"
        continue
    fi

    # 2. Skip if path matches EXCLUDE_PATHS
    if contains_element "${REPO_PATH}" "${EXCLUDE_PATHS[@]}"; then
        echo "--------------------------------------------------"
        echo "Skipping: ${REPO_PATH} (Excluded path in script config)"
        echo "--------------------------------------------------"
        continue
    fi

    IS_PROCESSED=0
    if [ -f "${PROGRESS_FILE}" ]; then
        set +e
        grep -q "^${REPO_PATH}$" "${PROGRESS_FILE}"
        GREP_STATUS=$?
        set -e

        if [ ${GREP_STATUS} -eq 0 ]; then
            IS_PROCESSED=1
        fi
    fi

    if [ ${IS_PROCESSED} -eq 1 ]; then
        echo "--------------------------------------------------"
        echo "Skipping: ${REPO_PATH} (Already processed)"
        echo "--------------------------------------------------"
        continue
    fi
    # -------------------------------------------------------

    echo "--------------------------------------------------"
    echo "Processing Path: ${REPO_PATH}"
    echo "--------------------------------------------------"

    # Target directory validation
    TARGET_DIR="${BASE_DIR}/${REPO_PATH}"
    if [ ! -d "${TARGET_DIR}" ]; then
        echo "[!] Warning: Directory ${TARGET_DIR} does not exist. Skipping."
        continue
    fi

    cd "${TARGET_DIR}"

    # --- Setup Remotes Using environment commands ---
    if command -v gerritremote &> /dev/null; then
        echo "=> Setting up Gerrit remote via 'gerritremote'..."
        gerritremote &> /dev/null || true
    fi

    if command -v upstreamremote &> /dev/null; then
        echo "=> Setting up Upstream remote via 'upstreamremote'..."
        upstreamremote &> /dev/null || true
    fi

    # Determine Target Gerrit Branch and Upstream Branch
    if [ -n "${REPO_REV}" ]; then
        CURRENT_TARGET_BRANCH="${REPO_REV#refs/heads/}"
        CURRENT_UPSTREAM_BRANCH="${CURRENT_TARGET_BRANCH}"
        echo "=> Branch override from project XML: ${CURRENT_TARGET_BRANCH}"
    else
        CURRENT_TARGET_BRANCH="${DEFAULT_TARGET_BRANCH}"
        CURRENT_UPSTREAM_BRANCH="${DEFAULT_UPSTREAM_BRANCH}"
        echo "=> Using Default Branches -> Target: ${CURRENT_TARGET_BRANCH} | Upstream: ${CURRENT_UPSTREAM_BRANCH}"
    fi

    # ------------------ Git Merge & Push Operations ------------------

    # Check if the current local HEAD is already a completed manual merge commit
    PARENT_COUNT=$(git show -s --pretty=%P HEAD | wc -w)
    ALREADY_MERGED=0

    if [ ${PARENT_COUNT} -ge 2 ]; then
        set +e
        UPSTREAM_SHA=$(git rev-parse -q --verify "${UPSTREAM_REMOTE}/${CURRENT_UPSTREAM_BRANCH}" 2>/dev/null || echo "")
        set -e
        
        if [ -n "${UPSTREAM_SHA}" ]; then
            set +e
            git merge-base --is-ancestor "${UPSTREAM_SHA}" HEAD 2>/dev/null
            IS_ANCESTOR=$?
            set -e
            if [ ${IS_ANCESTOR} -eq 0 ]; then
                echo "=> Pre-check: Valid manual merge commit detected on local HEAD."
                ALREADY_MERGED=1
            fi
        fi
    fi

    # 1. Sync target branch with Gerrit
    if [ ${ALREADY_MERGED} -eq 1 ]; then
        echo "[1/4] Skipping checkout reset to preserve manual merge."
    else
        echo "[1/4] Checking out target branch (${CURRENT_TARGET_BRANCH})..."
        git fetch "${GERRIT_REMOTE}" "${CURRENT_TARGET_BRANCH}"
        
        if git show-ref --verify --quiet "refs/heads/${CURRENT_TARGET_BRANCH}"; then
            git checkout "${CURRENT_TARGET_BRANCH}"
            set +e
            git pull "${GERRIT_REMOTE}" "${CURRENT_TARGET_BRANCH}" --ff-only 2>&1
            set -e
        else
            git checkout -b "${CURRENT_TARGET_BRANCH}" "${GERRIT_REMOTE}/${CURRENT_TARGET_BRANCH}"
        fi
    fi

    # 2. Fetch the latest changes from Upstream
    echo "[2/4] Fetching from ${UPSTREAM_REMOTE} branch ${CURRENT_UPSTREAM_BRANCH}..."
    set +e
    FETCH_UPSTREAM_OUT=$(git fetch "${UPSTREAM_REMOTE}" "${CURRENT_UPSTREAM_BRANCH}" 2>&1)
    FETCH_STATUS=$?
    set -e

    if [ ${FETCH_STATUS} -ne 0 ]; then
        echo "[!] Warning: Fetching from upstream failed for ${REPO_PATH}. Skipping merge."
        echo "${FETCH_UPSTREAM_OUT}"
        continue
    fi

    # 3. Execute Merge
    if [ ${ALREADY_MERGED} -eq 1 ]; then
        echo "[3/4] Skipping merge execution (Already resolved manually)."
    else
        echo "[3/4] Merging ${UPSTREAM_REMOTE}/${CURRENT_UPSTREAM_BRANCH} into ${CURRENT_TARGET_BRANCH}..."
        COMMIT_MSG="Merge branch '${UPSTREAM_REMOTE}/${CURRENT_UPSTREAM_BRANCH}' into ${CURRENT_TARGET_BRANCH}"
        
        set +e
        MERGE_OUTPUT=$(git merge "${UPSTREAM_REMOTE}/${CURRENT_UPSTREAM_BRANCH}" -m "${COMMIT_MSG}" 2>&1)
        MERGE_STATUS=$?
        set -e

        echo "${MERGE_OUTPUT}"

        if [ ${MERGE_STATUS} -ne 0 ]; then
            echo "[-] !! Conflict detected in ${REPO_PATH} !!"
            echo "Please resolve conflicts manually, commit the changes, and restart the script."
            exit 1
        fi
    fi

    # 4. Push to Gerrit with dual base parameters for merge review tracking
    echo "[4/4] Pushing to Gerrit..."
    
    FIRST_SHA="$(git show -s --pretty=%P HEAD | cut -d ' ' -f 1)"
    SECOND_SHA="$(git show -s --pretty=%P HEAD | cut -d ' ' -f 2)"
    FINAL_PARENT_COUNT=$(git show -s --pretty=%P HEAD | wc -w)

    if [ ${FINAL_PARENT_COUNT} -ge 2 ]; then
        echo "=> Merge commit verified (Parents: ${FINAL_PARENT_COUNT}). Using dual base parameters."
        PUSH_REF="refs/for/${CURRENT_TARGET_BRANCH}%base=${FIRST_SHA},base=${SECOND_SHA},topic=${TOPIC_NAME}"
    else
        echo "Warning: Not a merge commit (Already up-to-date). Falling back to standard push."
        PUSH_REF="refs/for/${CURRENT_TARGET_BRANCH}%topic=${TOPIC_NAME}"
    fi

    echo "=> Pushing HEAD to ${GERRIT_REMOTE} ${PUSH_REF}..."

    set +e
    PUSH_OUTPUT=$(git push "${GERRIT_REMOTE}" HEAD:"${PUSH_REF}" 2>&1)
    PUSH_STATUS=$?
    set -e

    echo "${PUSH_OUTPUT}"

    if [ ${PUSH_STATUS} -ne 0 ]; then
        if echo "${PUSH_OUTPUT}" | grep -qE "no new changes|commit\(s\) already exists"; then
            echo "=> No new unique changes to push for ${REPO_PATH} (Synchronized with Gerrit). Skipping safely."
        else
            echo "[-] Error: Git push failed for ${REPO_PATH}."
            exit 1
        fi
    fi

    echo "Done with ${REPO_PATH}"
    
    # --- Record Success Progress ---
    echo "${REPO_PATH}" >> "${PROGRESS_FILE}"

    cd "${BASE_DIR}"

done

# --- Cleanup Progress File upon Success ---
if [ -f "${PROGRESS_FILE}" ]; then
    rm "${PROGRESS_FILE}"
fi

echo "--------------------------------------------------"
echo "=== All repositories from witaqua.xml processed and pushed successfully ==="