#!/bin/bash

#--This can be set or not, but to prevent bugs it's more preferred you set your monitor name in this
#--To get your monitor name use the command `xrandr` and check which one says 'connected primary' 
#--or the only working monitor there

PRIM_MONITOR=""


#------ARGUMENT PARSING-------#

LOGGING=0
DO_NOT_BE_ANNOYING=0

if [ $# -gt 2 ]; then
    echo -e "\e[31mTOO MANY ARGUMENTS!\e[0m"
    exit 1
fi

for arg in $@; do
  case $arg in
    -d) DO_NOT_BE_ANNOYING=1 ;;
    -l) LOGGING=1 ;;
    *) echo -e "\e[31mINVALID ARGUMENT!\e[0m" && exit 1 ;;
  esac
done

#-------LOGGING SYSTEM--------#

LOG_DOMAIN="bspafs"

reset="\e[0m"
red="\e[31m"
green="\e[32m"
yellow="\e[33m"

log() {
  if [ $LOGGING -eq 1 ]; then
    case $1 in
      1) echo -e "${red}[ERROR] $LOG_DOMAIN: ${2}${reset}" ;;
      2) echo -e "${yellow}[WARN] $LOG_DOMAIN: ${2}${reset}" ;;
      *) echo -e "[INFO] $LOG_DOMAIN: ${1}${reset}" ;;
    esac
  fi
}

log "logging ${green}enabled!"

#----MONITOR CHECKING & ASSIGNMENT----#

if [ -z $PRIM_MONITOR ]; then
  if [ $(bspc query -M | wc -l) -eq 1 ]; then
    PRIM_MONITOR="DP-2"
  else
    PRIM_MONITOR=$(xrandr | grep primary | awk '{print $1}')
  fi
fi

log "the primary monitor is ${yellow}$PRIM_MONITOR!"

#--------EWW TOGGLING---------#

EWW_INSTALLED=$(command -v eww > /dev/null 2>&1 && echo 1 || echo 0)
EWW_RUNNING=$(pgrep -x eww > /dev/null && echo 1 || echo 0)

toggle_eww() {
  local LOG_DOMAIN="toggle_eww"
  
  #--Error Checking
  if [ $EWW_INSTALLED -eq 0 ]; then
    log "1" "EWW is not installed! please install it: https://elkowar.github.io/eww/"
    return
  fi

  if [[ ! $(bspc query -M -m --names) == $PRIM_MONITOR ]]; then
    return
  fi

  #--FUNCTION ARGUMENT PARSING

  local TOGGLE_TYPE=0
  
  if [ $# -gt 1 ]; then
    log "1" "Too many arguments! Please check parameters!"
    return
  elif [ $# -eq 1 ]; then
    case $1 in
      "enable"|"1") TOGGLE_TYPE=1 ;;
      "disable"|"0") TOGGLE_TYPE=2 ;;
      "") log "2" "Empty argument given, assuming normal toggle type!" ;;
      *) log "1" "Invalid Argument! please check parameter!" ; return ;;
    esac
  else
    log "2" "No arguments given, assuming normal toggle type!"
  fi

  #--TOGGLING FUNCTIONS

  open_eww() {
    if [ $EWW_RUNNING -eq 0 ]; then
      eww open-many left-bar center-bar right-bar > /dev/null 2>&1 &
      FOCUSED_DESKTOPS=$( $HOME/.config/bspwm/scripts/updatemonitors.sh )
      eww update focused-desktops="$FOCUSED_DESKTOPS"
      log "Eww has been ${green}opened!"
      EWW_RUNNING=1
    else
      log "Eww is already running!"
    fi
  }

  close_eww() {
    if [ $EWW_RUNNING -eq 1 ]; then
      eww close-all > /dev/null 2>&1 &
      log "Eww has been ${red}closed!"
      EWW_RUNNING=0
    else
      log "Eww is already closed!"
    fi
  }

  #--Executing toggles

  case $TOGGLE_TYPE in
    1) open_eww && return
    ;;
    2) close_eww && return
    ;;
    0) 
      if [ $EWW_RUNNING -eq 1 ]; then
        close_eww
      else
        open_eww
      fi
    ;;
    *) log "1" "hold on, what? check toggle_eww!"
    ;;
  esac
}

#----CHECK THE NODE STATE-----#

# to be finished
check_state() {
  echo "something"
}

#-------THE GOOD SHIT---------#

EVENTS=("node_add" "node_remove" "node_state" "node_transfer" "desktop_focus")

bspc subscribe "${EVENTS[@]}" | while read -r eve mon des nod out1 out2 out3; do
  NODE_COUNT=$(bspc query -N -d | wc -l)
  # temporary solutions
  IS_FLOATING=$(bspc query -N -n focused.floating > /dev/null 2>&1 && echo 1 || echo 0)
  IS_FULLSCREEN=$(bspc query -N -n focused.fullscreen > /dev/null 2>&1 && echo 1 || echo 0)
  
  case $eve in

    "node_add")
      LOG_DOMAIN="node_add"
      if [ $NODE_COUNT -eq 1 ] && [ $IS_FLOATING -ne 1 ]; then
        log "node currently only one in desktop, Fullscreening!"
        bspc node -t fullscreen
        toggle_eww "disable"
      else
        log "second node detected, Tiling!"
        toggle_eww "enable"
      fi
    ;;


    "node_remove")
      LOG_DOMAIN="node_remove"
      if [ $NODE_COUNT -eq 0 ] || [ $IS_FULLSCREEN -ne 1 ]; then
        log "no nodes are in the current desktop, summoning eww!"
        toggle_eww "enable"
      elif [ $NODE_COUNT -eq 1 ] && [ $IS_FLOATING -ne 1 ] && [ $DO_NOT_BE_ANNOYING -ne 1 ]; then
        log "node currently only one in desktop, Fullscreening!"
        bspc node -t fullscreen
        toggle_eww "disable"
      fi
    ;;


    "node_state")
      LOG_DOMAIN="node_state"
      case "$out1 $out2" in
        "fullscreen on")
          log "node transforming to fullscreen, killing eww!"
          toggle_eww "disable"
        ;;
        "floating on")
          log "node transforming to floating, summoning eww!"
          toggle_eww "enable"
        ;;
        "tiled on")
          log "node transforming to tiled, summoning eww!"
          toggle_eww "enable"
        ;;
      esac
    ;;

    
    "node_transfer")
      if [ $NODE_COUNT -eq 1 ] && [ $IS_FLOATING -ne 1 ]; then
        log "new desktop is empty and free to take, Fullscreening!"
        bspc node -t fullscreen
        toggle_eww "disable"
      fi
    ;; 


    "desktop_focus")
      if [ $NODE_COUNT -eq 1 ] && [ $IS_FLOATING -ne 1 ]; then
        if [ $DO_NOT_BE_ANNOYING -ne 1 ] || [ $IS_FULLSCREEN -eq 1 ]; then
          log "current desktop has one tiled node, Fullscreening!"
          [ $IS_FULLSCREEN -ne 1 ] && bspc node -t fullscreen
          toggle_eww "disable"
        else
          log "current desktop has one tiled node but the user thinks fullscreening is annoying so... summoning eww"
          toggle_eww "enable"
        fi
      elif [ $NODE_COUNT -eq 0 ]; then
        log "current desktop has no nodes, summoning eww!"
        toggle_eww "enable"
      elif [ $IS_FULLSCREEN -eq 1 ]; then
        log "current desktop has a fullscreen node, killing eww!"
        toggle_eww "disable"
      else
        log "current desktop has more than 1 node and is not fullscreen, summoning eww!"
        toggle_eww "enable"
      fi
    ;;


    *)
      log "2" "foreign event type detected! failed to perform actions..."
    ;;


  esac
done
