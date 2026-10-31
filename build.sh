#!/bin/sh
set -eu
cd "$(dirname "$0")"
mkdir -p out
java -jar tools/apktool.jar b apktool-project -o out/RealPing-V22-unsigned.apk
printf '%s\n' 'Build complete: out/RealPing-V22-unsigned.apk (align and sign before installing).'
