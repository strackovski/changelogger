#!/bin/bash
# ============================================================
#
# ChangeLogger dev setup script
#
# Author:   Vladimir Strackovski <vladimir.strackovski@dlabs.si>
# Year:     2018
#
# ============================================================

# Copy all git hooks to .git/hooks dir
for file in scripts/hooks/*.sh; do
    filename=${file##*/}
    cp -- "$file" ".git/hooks/${filename%%.sh}"
done
