#!/bin/bash

# Fix compaudit permissions for zsh completions
if command -v compaudit &> /dev/null; then
  compaudit 2>/dev/null | xargs -r chmod g-w,o-w 2>/dev/null
fi
