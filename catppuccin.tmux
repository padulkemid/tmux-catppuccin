#!/usr/bin/env bash
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_STATUS_LINE_FILE=src/default.conf
PILL_STATUS_LINE_FILE=src/pill-status-line.conf
POWERLINE_STATUS_LINE_FILE=src/powerline-status-line.conf
POWERLINE_ICONS_STATUS_LINE_FILE=src/powerline-icons-status-line.conf
NO_PATCHED_FONTS_STATUS_LINE_FILE=src/no-patched-fonts-status-line.conf

get_tmux_option() {
  local option value default
  option="$1"
  default="$2"
  value="$(tmux show-option -gqv "$option")"

  if [ -n "$value" ]; then
    echo "$value"
  else
    echo "$default"
  fi
}

set() {
  local option=$1
  local value=$2
  tmux_commands+=(set-option -gq "$option" "$value" ";")
}

setw() {
  local option=$1
  local value=$2
  tmux_commands+=(set-window-option -gq "$option" "$value" ";")
}

build_window_icon() {
  local window_status_icon_enable="$(get_tmux_option "@catppuccin_window_status_icon_enable" "yes")"

  local custom_icon_window_last="$(get_tmux_option "@catppuccin_icon_window_last" "󰖰")"
  local custom_icon_window_current="$(get_tmux_option "@catppuccin_icon_window_current" "󰖯")"
  local custom_icon_window_zoom="$(get_tmux_option "@catppuccin_icon_window_zoom" "󰁌")"
  local custom_icon_window_mark="$(get_tmux_option "@catppuccin_icon_window_mark" "󰃀")"
  local custom_icon_window_silent="$(get_tmux_option "@catppuccin_icon_window_silent" "󰂛")"
  local custom_icon_window_activity="$(get_tmux_option "@catppuccin_icon_window_activity" "󰖲")"
  local custom_icon_window_bell="$(get_tmux_option "@catppuccin_icon_window_bell" "󰂞")"

  if [[ $window_status_icon_enable == "yes" ]]
  then
    local show_window_status="#(printf '%%s\n' '#F' | sed \"s/*/${custom_icon_window_current}/\" | sed \"s/-/${custom_icon_window_last}/\" | sed \"s/#/${custom_icon_window_activity}/\" | sed \"s/#//g\"| sed \"s/~/${custom_icon_window_silent}/\" | sed \"s/!/${custom_icon_window_bell}/\" | sed \"s/M/${custom_icon_window_mark}/\" | sed \"s/Z/${custom_icon_window_zoom}/\")"
  fi

  if [[ $window_status_icon_enable == "no" ]]
  then
    local show_window_status="#F"
  fi

  echo $show_window_status
}

build_window_format() {
  local number="$1"
  local color="$2"
  local background="$3"
  local text="$4"
  local fill="$5"

  if [[ $window_status_enable == "yes" ]]
  then
    local icon="$( build_window_icon )"
    text="$text $icon" 
  fi

  if [[ $fill == "none" ]] 
  then
    local show_left_separator="#[fg=$thm_gray,bg=$thm_bg,nobold,nounderscore,noitalics]$window_left_separator"
    local show_number="#[fg=$thm_fg,bg=$thm_gray]$number"
    local show_middle_separator="#[fg=$thm_fg,bg=$thm_gray,nobold,nounderscore,noitalics]$window_middle_separator"
    local show_text="#[fg=$thm_fg,bg=$thm_gray]$text"
    local show_right_separator="#[fg=$thm_gray,bg=$thm_bg]$window_right_separator"

  fi

  if [[ $fill == "all" ]] 
  then
    local show_left_separator="#[fg=$color,bg=$thm_bg,nobold,nounderscore,noitalics]$window_left_separator"
    local show_number="#[fg=$background,bg=$color]$number"
    local show_middle_separator="#[fg=$background,bg=$color,nobold,nounderscore,noitalics]$window_middle_separator"
    local show_text="#[fg=$background,bg=$color]$text"
    local show_right_separator="#[fg=$color,bg=$thm_bg]$window_right_separator"

  fi
  
  if [[ $fill == "number" ]] 
  then
    local show_number="#[fg=$background,bg=$color]$number"
    local show_middle_separator="#[fg=$color,bg=$background,nobold,nounderscore,noitalics]$window_middle_separator"
    local show_text="#[fg=$thm_fg,bg=$background]$text"

    if [[ $window_number_position == "right" ]]
    then
      local show_left_separator="#[fg=$background,bg=$thm_bg,nobold,nounderscore,noitalics]$window_left_separator"
      local show_right_separator="#[fg=$color,bg=$thm_bg]$window_right_separator"
    fi

    if [[ $window_number_position == "left" ]]
    then
      local show_right_separator="#[fg=$background,bg=$thm_bg,nobold,nounderscore,noitalics]$window_right_separator"
      local show_left_separator="#[fg=$color,bg=$thm_bg]$window_left_separator"
    fi

  fi

  local window_format

  if [[ $window_number_position == "right" ]]
  then
    window_format="$show_left_separator$show_text$show_middle_separator$show_number$show_right_separator"
  fi

  if [[ $window_number_position == "left" ]]
  then
    window_format="$show_left_separator$show_number$show_middle_separator$show_text$show_right_separator"
  fi

  echo $window_format
}

build_status_module() {
  local index="$1"
  local icon="$2"
  local color="$3"
  local text="$4"

  if [[ $index -eq 0 || $status_connect_separator == "no" ]]
  then
    local show_left_separator="#[fg=$color,bg=$thm_bg,nobold,nounderscore,noitalics]$status_left_separator"
  else
    local show_left_separator="#[fg=$color,bg=$thm_gray,nobold,nounderscore,noitalics]$status_left_separator"
  fi

  if [[ $status_fill == "icon" ]]
  then
    local show_icon="#[fg=$thm_bg,bg=$color,nobold,nounderscore,noitalics]$icon "
    local show_text="#[fg=$thm_fg,bg=$thm_gray] $text"
    local show_right_separator="#[fg=$thm_gray,bg=$thm_bg,nobold,nounderscore,noitalics]$status_right_separator"
  fi

  if [[ $status_fill == "all" ]]
  then
    local show_icon="#[fg=$thm_bg,bg=$color,nobold,nounderscore,noitalics]$icon "
    local show_text="#[fg=$thm_bg,bg=$color]$text"
    local show_right_separator="#[fg=$color,bg=$thm_bg,nobold,nounderscore,noitalics]$status_right_separator"
  fi

  if [[ $status_right_separator_inverse == "yes" ]]
  then
    local show_right_separator="#[fg=$thm_bg,bg=$color,nobold,nounderscore,noitalics]$status_right_separator"
  fi

  echo "$show_left_separator$show_icon$show_text$show_right_separator"
}

load_modules() {
  local loaded_modules

  local modules_list=$1
  
  local modules_custom_path=$PLUGIN_DIR/custom
  local modules_status_path=$PLUGIN_DIR/status
  local modules_window_path=$PLUGIN_DIR/window

  local modules_array
  read -a modules_array <<< "$modules_list"

  local module_index=0;
  local module_name
  for module_name in ${modules_array[@]}
  do
    local module_path=$modules_custom_path/$module_name.sh
    source $module_path

    if [[ 0 -eq $? ]]
    then
      loaded_modules="$loaded_modules$( show_$module_name $module_index )"
      module_index=$module_index+1
      continue
    fi

    local module_path=$modules_status_path/$module_name.sh
    source $module_path

    if [[ 0 -eq $? ]]
    then
      loaded_modules="$loaded_modules$( show_$module_name $module_index )"
      module_index=$module_index+1
      continue
    fi

    local module_path=$modules_window_path/$module_name.sh
    source $module_path

    if [[ 0 -eq $? ]]
    then
      loaded_modules="$loaded_modules$( show_$module_name $module_index )"
      module_index=$module_index+1
      continue
    fi

  done

  echo $loaded_modules
}

main() {
  local theme
  theme="$(get_tmux_option "@catppuccin_flavour" "mocha")"

  # Aggregate all commands in one array
  local tmux_commands=()

  # NOTE: Pulling in the selected theme by the theme that's being set as local
  # variables.
  # shellcheck source=catppuccin-frappe.tmuxtheme
  source /dev/stdin <<<"$(sed -e "/^[^#].*=/s/^/local /" "${PLUGIN_DIR}/catppuccin-${theme}.tmuxtheme")"

  # status
  set status "on"
  set status-bg "${thm_bg}"
  set status-justify "left"
  set status-left-length "100"
  set status-right-length "100"

  # messages
  set message-style "fg=${thm_cyan},bg=${thm_gray},align=centre"
  set message-command-style "fg=${thm_cyan},bg=${thm_gray},align=centre"

  # panes
  set pane-border-style "fg=${thm_gray}"
  set pane-active-border-style "fg=${thm_blue}"

  # windows
  setw window-status-activity-style "fg=${thm_fg},bg=${thm_bg},none"
  setw window-status-separator ""
  setw window-status-style "fg=${thm_fg},bg=${thm_bg},none"

  # --------=== Statusline

  local window_left_separator="$(get_tmux_option "@catppuccin_window_left_separator" "█")"
  local window_right_separator="$(get_tmux_option "@catppuccin_window_right_separator" "█")"
  local window_middle_separator="$(get_tmux_option "@catppuccin_window_middle_separator" "█ ")"
  local window_number_position="$(get_tmux_option "@catppuccin_window_number_position" "left")" # right, left
  local window_status_enable="$(get_tmux_option "@catppuccin_window_status_enable" "no")" # right, left

  local window_format=$( load_modules "window_default_format")
  local window_current_format=$( load_modules "window_current_format")

  setw window-status-format "${window_format}"
  setw window-status-current-format "${window_current_format}"

  local status_left_separator="$(get_tmux_option "@catppuccin_status_left_separator" "")"
  local status_right_separator="$(get_tmux_option "@catppuccin_status_right_separator" "█")"
  local status_right_separator_inverse="$(get_tmux_option "@catppuccin_status_right_separator_inverse" "no")"
  local status_connect_separator="$(get_tmux_option "@catppuccin_status_connect_separator" "yes")"
  local status_fill="$(get_tmux_option "@catppuccin_status_fill" "icon")"

  local status_modules="$(get_tmux_option "@catppuccin_status_modules" "application session")"
  local loaded_modules=$( load_modules "$status_modules")

  set status-left ""
  set status-right "${loaded_modules}"

  # --------=== Modes
  #
  setw clock-mode-colour "${thm_blue}"
  setw mode-style "fg=${thm_pink} bg=${thm_black4} bold"

  tmux "${tmux_commands[@]}"
}

main "$@"