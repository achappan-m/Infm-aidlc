#!/usr/bin/env bash
# Initialise and push this AI-DLC scaffold to your repo.
set -euo pipefail
git init
git add .
git commit -m "AI-DLC: orchestrator + six lifecycle agents, skills, commands, CI gates"
git branch -M main
git remote add origin https://github.com/achappan-m/Infm-aidlc.git
git push -u origin main
