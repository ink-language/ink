#!/bin/bash

set -eu

SCRIPT_NAME="${BASH_SOURCE[0]}"
MANIFEST_PATH=$1

function usage {
  cat << EOF
Usage: ${SCRIPT_NAME} MANIFEST_PATH

Succeeds if the crate at MANIFEST_PATH is *probably* contract crate, fails otherwise. The heuristic used is:
  - Find the root package of the crate
  - Find the source file of the root package that is a lib
  - Check for the presence of the `#[ink::contract]` attribute macro

MANIFEST_PATH
  Path to the Cargo.toml manifest file for a possible contract project

EXAMPLES
  ${SCRIPT_NAME} ./Cargo.toml

EOF
}

if [ -z "$MANIFEST_PATH" ]; then
  usage
  exit 1
fi

cargo metadata --format-version=1 --manifest-path "$MANIFEST_PATH" | jq -r '.resolve.root'
ROOT_PACKAGE=$(cargo metadata --format-version=1 --manifest-path "$MANIFEST_PATH" |
  jq -r '.resolve.root')

echo "---0"

cargo metadata --format-version=1 --manifest-path "$MANIFEST_PATH" |
  jq -r --arg ROOT_PACKAGE "$ROOT_PACKAGE" '
    .packages[]
    | select(.id == $ROOT_PACKAGE).targets[]
    | select(.kind[] | contains("lib")).src_path'

echo "---1"
SOURCE_PATH=$(cargo metadata --format-version=1 --manifest-path "$MANIFEST_PATH" |
  jq -r --arg ROOT_PACKAGE "$ROOT_PACKAGE" '
    .packages[]
    | select(.id == $ROOT_PACKAGE).targets[]
    | select(.kind[] | contains("lib")).src_path')
echo "---2"

# Check if SOURCE_PATH is empty
if [ -z "$SOURCE_PATH" ]; then
  echo "Error: Source path is empty."
  exit 1
fi

echo "---3"

# Check for the #[ink::contract] macro in the source file
if grep -qE '^#\[(::)?ink::contract([^]]*)\]' "$SOURCE_PATH"; then
echo "---4"
    exit 0
else
echo "---5"
    exit 3
fi
