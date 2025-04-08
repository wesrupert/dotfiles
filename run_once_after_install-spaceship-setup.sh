#!/usr/bin/env bash

if [[ -n "$ZSH_CUSTOM" && -d "$ZSH_CUSTOM/themes/spaceship-prompt" ]]; then
  ln -s "$ZSH_CUSTOM/themes/spaceship-prompt/spaceship.zsh-theme" "$ZSH_CUSTOM/themes/spaceship.zsh-theme"
fi