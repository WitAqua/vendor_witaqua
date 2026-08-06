#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# ==================== CONFIGURATION ====================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Relative Path to witaqua.xml ---
MANIFEST_SNIPPET="${SCRIPT_DIR}/../../../.repo/manifests/snippets/witaqua.xml"

# --- Remote Setting ---
GERRIT_REMOTE="gerrit"
# =======================================================

# --- Try to resolve BASE_DIR using Android build environment (gettop) ---
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

# Resolve absolute path for manifest snippet
MANIFEST_FILE="$(cd "$(dirname "${MANIFEST_SNIPPET}")" 2>/dev/null && pwd)/$(basename "${MANIFEST_SNIPPET}")"

if [ ! -f "${MANIFEST_FILE}" ]; then
    echo "[-] Error: Manifest snippet file not found at: ${MANIFEST_FILE}"
    exit 1
fi

# --- Dynamically Extract Default Branch from <remote name="witaqua" ... /> ---
DEFAULT_TARGET_BRANCH=$(grep -E '<remote[[:space:]]+name="witaqua"' "${MANIFEST_FILE}" | sed -n 's/.*revision="\([^"]*\)".*/\1/p' | sed 's|^refs/heads/||')

# Fallback if not found in remote definition
if [ -z "${DEFAULT_TARGET_BRANCH}" ]; then
    DEFAULT_TARGET_BRANCH="16.2"
fi

if [ -n "$1" ]; then
    TOPIC_NAME="$1"
    echo "=> Using user-specified topic: ${TOPIC_NAME}"
else
    TOPIC_NAME="merge-upstream-$(date +%Y%m%d)"
    echo "=> No argument provided. Using default topic: ${TOPIC_NAME}"
fi

echo "=== Starting Review Push Process (refs/for/) from Manifest ==="
echo "=> Loading Manifest: ${MANIFEST_FILE}"
echo "=> Default Manifest Branch for 'witaqua': ${DEFAULT_TARGET_BRANCH}"

# Progress file path to tracking completed repositories
PROGRESS_FILE="${BASE_DIR}/.progress"

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

    # Skip external remotes that are not target for Gerrit (e.g., gitlab for FaceUnlock)
    if [ "${REPO_REMOTE}" = "gitlab" ]; then
        echo "--------------------------------------------------"
        echo "Skipping: ${REPO_PATH} (Remote is gitlab)"
        echo "--------------------------------------------------"
        continue
    fi

    # ------------------ Safe Resume Check ------------------
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
        echo "Skipping: ${REPO_PATH} (Already pushed)"
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

    # --- Setup Gerrit Remote Using environment command ---
    if command -v gerritremote &> /dev/null; then
        echo "=> Executing 'gerritremote'..."
        gerritremote &> /dev/null || true
    fi

    # Determine Target Branch
    if [ -n "${REPO_REV}" ]; then
        CURRENT_TARGET_BRANCH="${REPO_REV#refs/heads/}"
        echo "=> Branch derived from project XML: ${CURRENT_TARGET_BRANCH}"
    else
        CURRENT_TARGET_BRANCH="${DEFAULT_TARGET_BRANCH}"
        echo "=> Branch derived from default remote XML: ${CURRENT_TARGET_BRANCH}"
    fi

    # ------------------ Git Push Operation ------------------
    # Detect parent commits to format dual base parameters if a merge commit exists
    FIRST_SHA="$(git show -s --pretty=%P HEAD | cut -d ' ' -f 1)"
    SECOND_SHA="$(git show -s --pretty=%P HEAD | cut -d ' ' -f 2)"
    PARENT_COUNT=$(git show -s --pretty=%P HEAD | wc -w)

    if [ ${PARENT_COUNT} -ge 2 ]; then
        echo "=> Merge commit detected (Parents: ${PARENT_COUNT}). Using dual base parameters."
        PUSH_REF="refs/for/${CURRENT_TARGET_BRANCH}%base=${FIRST_SHA},base=${SECOND_SHA},topic=${TOPIC_NAME}"
    else
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
echo "=== All repositories from witaqua.xml pushed to Gerrit refs/for/ successfully ==="