#!/usr/bin/env bash

clear
WALLDIR_FILE="$HOME/.config/walliwalli/walldir"
CACHE="$HOME/.cache/walliwalli/we-wallpapers"
HIDDEN="$HOME/.config/walliwalli/hidden"
SCREENS_FILE="$HOME/.config/walliwalli/screens"
SCREEN_FILE="$HOME/.config/walliwalli/screen"
WE_ARGS_FILE="$HOME/.config/walliwalli/we-args"
COLOR_TOOL_FILE="$HOME/.config/walliwalli/color-tool"
PYWAL_BACKEND_FILE="$HOME/.config/walliwalli/pywal-backend"
COLOR_TOOL_DEFAULT="none"
PYWAL_BACKEND_DEFAULT="haishoku"
LAST_DIR="$HOME/.cache/walliwalli"
FZF_OPTS=(--height=90% --layout=reverse --border --delimiter="|" --with-nth=1,2)
FZF_MENU_OPTS=(--height=40% --layout=reverse --border)
WE_ARGS_DEFAULT="--volume 100"
FILTER_TYPE=""
FILTER_RATING=""
FILTER_TAGS=""
STATUS_FILE="$HOME/.cache/walliwalli/.status"
WE_WORKSHOP_PATHS=(
    "$HOME/.steam/steam/steamapps/workshop/content/431960"
    "$HOME/.local/share/Steam/steamapps/workshop/content/431960"
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/workshop/content/431960"
    "$HOME/snap/steam/common/.local/share/Steam/steamapps/workshop/content/431960"
)

find_walldir() {
    for path in "${WE_WORKSHOP_PATHS[@]}"; do
        if [[ -d "$path" ]]; then
            WALLDIR="$path"
            printf '%s\n' "$WALLDIR" > "$WALLDIR_FILE"
            return 0
        fi
    done
    echo "Error: Wallpaper Engine workshop directory not found." >&2
}

load_walldir() {
    if [[ -f "$WALLDIR_FILE" ]]; then
        IFS= read -r WALLDIR < "$WALLDIR_FILE"
        [[ -d "$WALLDIR" ]] && return 0
    fi
    find_walldir
}

get_screens() {
    if command -v hyprctl &>/dev/null; then
        hyprctl monitors -j | jq -r '.[].name'
    elif command -v wlr-randr &>/dev/null; then
        wlr-randr --json | jq -r '.[].name'
    elif command -v xrandr &>/dev/null; then
        xrandr | awk '/ connected/ {print $1}'
    else
        echo "HDMI-1"
    fi
}

load_screens() {
    get_screens > "$SCREENS_FILE"
}

load_screen() {
    if [[ -f "$SCREEN_FILE" ]]; then
        IFS= read -r SCREEN < "$SCREEN_FILE"
    else
        IFS= read -r SCREEN < "$SCREENS_FILE"
        printf '%s\n' "$SCREEN" > "$SCREEN_FILE"
    fi
}

select_screen() {
    local selected
    selected=$(fzf "${FZF_MENU_OPTS[@]}" --prompt="Select screen > " < "$SCREENS_FILE")
    [[ -z "$selected" ]] && return
    SCREEN="$selected"
    printf '%s\n' "$SCREEN" > "$SCREEN_FILE"
}

load_we_args() {
    if [[ ! -f "$WE_ARGS_FILE" ]]; then
        printf '%s\n' "$WE_ARGS_DEFAULT" > "$WE_ARGS_FILE"
    fi
    IFS= read -r WE_ARGS < "$WE_ARGS_FILE"
    WE_ARGS_ARR=($WE_ARGS)
}

load_color_tool() {
    if [[ ! -f "$COLOR_TOOL_FILE" ]]; then
        printf '%s\n' "$COLOR_TOOL_DEFAULT" > "$COLOR_TOOL_FILE"
    fi
    IFS= read -r COLOR_TOOL < "$COLOR_TOOL_FILE"
    if [[ ! -f "$PYWAL_BACKEND_FILE" ]]; then
        printf '%s\n' "$PYWAL_BACKEND_DEFAULT" > "$PYWAL_BACKEND_FILE"
    fi
    IFS= read -r PYWAL_BACKEND < "$PYWAL_BACKEND_FILE"
}

apply_colors() {
    local image="$1"
    case "$COLOR_TOOL" in
        wallust)  wallust -q run "$image" ;;
        pywal)    wal -q --backend "$PYWAL_BACKEND" -i "$image" ;;
        pywal16)  wal -q --backend "$PYWAL_BACKEND" -i "$image" ;;
        matugen)  matugen -q image "$image" ;;
        none)     ;;
        *)        echo "Unknown color tool: $COLOR_TOOL" >&2 ;;
    esac
}

select_pywal_backend() {
    local selected
    selected=$(printf 'colorz\ncolorthief\nhaishoku\nschemer2\nwal\nfast_colorthief' | fzf \
        "${FZF_MENU_OPTS[@]}" --prompt="pywal backend (current: $PYWAL_BACKEND) > ")
    [[ -z "$selected" ]] && return
    PYWAL_BACKEND="$selected"
    printf '%s\n' "$PYWAL_BACKEND" > "$PYWAL_BACKEND_FILE"
}

select_color_tool() {
    local selected
    selected=$(printf 'wallust\npywal\npywal16\nmatugen\nnone' | fzf \
        "${FZF_MENU_OPTS[@]}" --prompt="Color tool (current: $COLOR_TOOL) > ")
    [[ -z "$selected" ]] && return
    COLOR_TOOL="$selected"
    printf '%s\n' "$COLOR_TOOL" > "$COLOR_TOOL_FILE"
    [[ "$COLOR_TOOL" == pywal* ]] && select_pywal_backend
}

edit_walldir() {
    local new_path fzf_exit
    new_path=$(fzf "${FZF_MENU_OPTS[@]}" --prompt="Wallpaper dir > "         --print-query --no-info --query "$WALLDIR" < /dev/null)
    fzf_exit=$?
    [[ $fzf_exit -ne 0 && $fzf_exit -ne 1 ]] && return
    new_path="${new_path%%$'\n'*}"
    [[ -z "$new_path" ]] && return
    if [[ ! -d "$new_path" ]]; then
        printf '%s' "Error: directory does not exist." > "$STATUS_FILE"
        return
    fi
    WALLDIR="$new_path"
    printf '%s\n' "$WALLDIR" > "$WALLDIR_FILE"
    reload_cache
}

edit_we_args() {
    local raw fzf_exit
    raw=$(fzf "${FZF_MENU_OPTS[@]}" --prompt="WE args > "         --print-query --no-info --query "$WE_ARGS" < /dev/null)
    fzf_exit=$?
    [[ $fzf_exit -ne 0 && $fzf_exit -ne 1 ]] && return
    WE_ARGS="${raw%%$'\n'*}"
    WE_ARGS_ARR=($WE_ARGS)
    printf '%s\n' "$WE_ARGS" > "$WE_ARGS_FILE"
}

kill_wallpaper() {
    pkill -f "linux-wallpaperengine.*--screen-root[[:space:]]$SCREEN" 2>/dev/null
}

launch_wallpaper() {
    local wallpath="$1"
    local wallpaper_jpeg="$LAST_DIR/wallpaper-${SCREEN}.jpeg"
    setsid linux-wallpaperengine --screen-root "$SCREEN" "${WE_ARGS_ARR[@]}" \
        --screenshot "$wallpaper_jpeg" --bg "$wallpath"
}

toggle_audio() {
    if [[ "$WE_ARGS" =~ --volume\ 0([^-9]|$) ]]; then
        WE_ARGS="${WE_ARGS/--volume 0/--volume 100}"
    else
        shopt -s extglob
        WE_ARGS="${WE_ARGS/--volume +([0-9])/--volume 0}"
        shopt -u extglob
    fi
    WE_ARGS_ARR=($WE_ARGS)
    printf '%s\n' "$WE_ARGS" > "$WE_ARGS_FILE"
    [[ ! -f "$LAST_DIR/we-last-wallpaper-${SCREEN}" ]] && return
    local wallpath
    IFS= read -r wallpath < "$LAST_DIR/we-last-wallpaper-${SCREEN}"
    [[ -z "$wallpath" ]] && return
    kill_wallpaper
    launch_wallpaper "$wallpath" &>/dev/null &
}

stop_wallpaper() {
    kill_wallpaper
    printf '%s' "Wallpaper stopped on $SCREEN." > "$STATUS_FILE"
}

show_current_wallpaper() {
    if [[ ! -f "$LAST_DIR/we-last-wallpaper-${SCREEN}" ]]; then
        printf '%s' "No wallpaper has been launched yet." > "$STATUS_FILE"
        return
    fi
    local wallpath
    IFS= read -r wallpath < "$LAST_DIR/we-last-wallpaper-${SCREEN}"
    local title type
    IFS='|' read -r title type _ < <(grep -F "$wallpath" "$CACHE")
    if [[ -z "$title" ]]; then
        printf '%s' "Current wallpaper not found in cache." > "$STATUS_FILE"
        return
    fi
    printf '%s' "Title: $title | Type: $type | Path: $wallpath" > "$STATUS_FILE"
}

manage_hidden_list() {
    while true; do
        local choice
        choice=$(printf 'Export hidden list\nImport hidden list\nBack' | fzf_menu "Hidden list")
        case "$choice" in
            "Export hidden list")
                local dest fzf_exit
                dest=$(fzf "${FZF_MENU_OPTS[@]}" --prompt="Export to > "                     --print-query --no-info --query "$HOME/walliwalli-hidden.txt" < /dev/null)
                fzf_exit=$?
                [[ $fzf_exit -ne 0 && $fzf_exit -ne 1 ]] && continue
                dest="${dest%%$'\n'*}"
                [[ -z "$dest" ]] && continue
                cp "$HIDDEN" "$dest" && printf '%s' "Exported to $dest." > "$STATUS_FILE" || printf '%s' "Export failed." > "$STATUS_FILE"
                ;;
            "Import hidden list")
                local src fzf_exit
                src=$(fzf "${FZF_MENU_OPTS[@]}" --prompt="Import from > "                     --print-query --no-info < /dev/null)
                fzf_exit=$?
                [[ $fzf_exit -ne 0 && $fzf_exit -ne 1 ]] && continue
                src="${src%%$'\n'*}"
                [[ -z "$src" ]] && continue
                if [[ ! -f "$src" ]]; then
                    printf '%s' "File not found." > "$STATUS_FILE"
                    continue
                fi
                cp "$src" "$HIDDEN" && printf '%s' "Imported from $src." > "$STATUS_FILE" || printf '%s' "Import failed." > "$STATUS_FILE"
                ;;
            "Back"|"") return ;;
        esac
    done
}

collect_wallpaper_files() {
    shopt -s nullglob
    WALLPAPER_FILES=("$WALLDIR"/*/project.json)
    shopt -u nullglob
}

needs_rebuild() {
    [[ ! -f "$CACHE" ]] && return 0
    [[ "${#WALLPAPER_FILES[@]}" -ne $(wc -l < "$CACHE") ]] && return 0
    for f in "${WALLPAPER_FILES[@]}"; do
        [[ "$f" -nt "$CACHE" ]] && return 0
    done
    return 1
}

build_cache() {
    printf '%s' "Building wallpaper cache..." > "$STATUS_FILE"
    [[ ${#WALLPAPER_FILES[@]} -eq 0 ]] && > "$CACHE" && return
    jq -rn 'inputs | "\(.title // "Unknown")|\(.type // "unknown")|\(.contentrating // "Everyone")|\((.tags // []) | join(","))|\(input_filename | gsub("/project\\.json$"; "/"))"' \
        "${WALLPAPER_FILES[@]}" > "$CACHE"
}

reload_cache() {
    collect_wallpaper_files
    build_cache
    unset WALLPAPER_FILES
}

refresh_screens() {
    load_screens
    load_screen
}

fzf_menu() {
    local header_opt=()
    if [[ -s "$STATUS_FILE" ]]; then
        header_opt=(--header "$(< "$STATUS_FILE")")
        > "$STATUS_FILE"
    fi
    fzf "${FZF_MENU_OPTS[@]}" --prompt="$1 > " "${header_opt[@]}"
}

wallpaper_menu() {
    while true; do
        local audio_label="Toggle audio (currently: ON)"
        [[ "$WE_ARGS" =~ --volume\ 0([^-9]|$) ]] && audio_label="Toggle audio (currently: OFF)"
        local choice
        choice=$(printf '%s\nShow current wallpaper\nStop wallpaper\nBack' "$audio_label" | fzf_menu "Wallpaper")
        case "$choice" in
            Toggle\ audio*) toggle_audio ;;
            "Show current wallpaper") show_current_wallpaper ;;
            "Stop wallpaper") stop_wallpaper ;;
            "Back"|"") return ;;
        esac
    done
}

screens_menu() {
    while true; do
        local choice
        choice=$(printf 'Select screen (current: %s)\nRefresh screens\nBack' "$SCREEN" | fzf_menu "Screens")
        case "$choice" in
            Select\ screen*) select_screen ;;
            "Refresh screens") refresh_screens ;;
            "Back"|"") return ;;
        esac
    done
}

library_menu() {
    while true; do
        local choice
        choice=$(printf 'Manage hidden wallpapers\nManage hidden list\nEdit wallpaper directory\nReload cache\nBack' | fzf_menu "Library")
        case "$choice" in
            "Manage hidden wallpapers") manage_hidden ;;
            "Manage hidden list") manage_hidden_list ;;
            "Edit wallpaper directory") edit_walldir ;;
            "Reload cache") reload_cache ;;
            "Back"|"") return ;;
        esac
    done
}

filter_menu() {
    while true; do
        local choice
        choice=$(printf 'By type (current: %s)\nBy rating (current: %s)\nBy tag (current: %s)\nClear all filters\nBack' \
            "${FILTER_TYPE:-All}" "${FILTER_RATING:-All}" "${FILTER_TAGS:-All}" | fzf_menu "Filter")
        case "$choice" in
            By\ type*)   filter_by_type ;;
            By\ rating*) filter_by_rating ;;
            By\ tag*)    filter_by_tags ;;
            "Clear all filters") FILTER_TYPE=""; FILTER_RATING=""; FILTER_TAGS="" ;;
            "Back"|"") return ;;
        esac
    done
}

settings_menu() {
    while true; do
        local backend_opt=""
        [[ "$COLOR_TOOL" == pywal* ]] && backend_opt=$'\n'"pywal backend (current: $PYWAL_BACKEND)"
        local choice
        choice=$(printf 'Wallpaper\nScreens\nLibrary\nEdit wallpaper engine arguments\nColor tool (current: %s)%s\nFilters\nBack' "$COLOR_TOOL" "$backend_opt" | fzf_menu "Settings")
        case "$choice" in
            "Wallpaper") wallpaper_menu ;;
            "Screens") screens_menu ;;
            "Library") library_menu ;;
            "Edit wallpaper engine arguments") edit_we_args ;;
            Color\ tool*) select_color_tool ;;
            "Filters") filter_menu ;;
            pywal\ backend*) select_pywal_backend ;;
            "Back"|"") return ;;
        esac
    done
}

manage_hidden() {
    while true; do
        local choice
        choice=$(printf 'Hide a wallpaper\nUnhide a wallpaper\nBack' | fzf_menu "Hidden wallpapers")
        case "$choice" in
            "Hide a wallpaper")
                [[ ! -s "$CACHE" ]] && continue
                to_hide=$(grep -vFf "$HIDDEN" "$CACHE" | fzf \
                    "${FZF_OPTS[@]}" --prompt="Hide > ")
                [[ -z "$to_hide" ]] && continue
                echo "${to_hide##*|}" >> "$HIDDEN"
                ;;
            "Unhide a wallpaper")
                [[ ! -s "$HIDDEN" ]] && continue
                to_unhide=$(grep -Ff "$HIDDEN" "$CACHE" | fzf \
                    "${FZF_OPTS[@]}" --prompt="Unhide > ")
                [[ -z "$to_unhide" ]] && continue
                grep -vF "${to_unhide##*|}" "$HIDDEN" > "$HIDDEN.tmp" && mv "$HIDDEN.tmp" "$HIDDEN"
                ;;
            "Back"|"") return ;;
        esac
    done
}

filter_by_type() {
    local selected
    selected=$({ printf 'All\n'; awk -F'|' '{v=tolower($2); gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); if(v!="" && !seen[v]++) print v}' "$CACHE"; } | fzf_menu "Filter by type")
    [[ -z "$selected" ]] && return
    [[ "$selected" == "All" ]] && FILTER_TYPE="" || FILTER_TYPE="$selected"
}

filter_by_rating() {
    local selected
    selected=$({ printf 'All\n'; awk -F'|' '{v=tolower($3); gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); if(v!="" && !seen[v]++) print v}' "$CACHE"; } | fzf_menu "Filter by rating")
    [[ -z "$selected" ]] && return
    [[ "$selected" == "All" ]] && FILTER_RATING="" || FILTER_RATING="$selected"
}

filter_by_tags() {
    local selected
    selected=$({ printf 'All\n'; awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4); n=split($4,a,","); for(i=1;i<=n;i++) {v=tolower(a[i]); if(v!="" && !seen[v]++) print v}}' "$CACHE"; } | fzf_menu "Filter by tag")
    [[ -z "$selected" ]] && return
    [[ "$selected" == "All" ]] && FILTER_TAGS="" || FILTER_TAGS="$selected"
}

get_input() {
    { grep -vFf "$HIDDEN" "$CACHE" || < "$CACHE"; } | \
        awk -F'|' -v t="$FILTER_TYPE" -v r="$FILTER_RATING" -v g="$FILTER_TAGS" \
            '(t=="" || tolower($2)==t) && (r=="" || tolower($3)==r) && (g=="" || index(tolower($4),g))'
}

# --- init ---

mkdir -p "$HOME/.cache/walliwalli" "$HOME/.config/walliwalli"
touch "$HIDDEN" "$STATUS_FILE"
load_walldir

[[ -n "$WALLDIR" ]] && collect_wallpaper_files
unset WE_WORKSHOP_PATHS
BUILD_PID=""
if [[ -n "$WALLDIR" ]] && needs_rebuild; then
    build_cache &
    BUILD_PID=$!
fi

load_we_args
load_color_tool
[[ ! -f "$SCREENS_FILE" ]] && load_screens
load_screen
[[ -n "$BUILD_PID" ]] && wait "$BUILD_PID"
unset WALLPAPER_FILES

# --- main ---

sleep 0.02
while true; do
    if [[ -s "$STATUS_FILE" ]]; then
        selection=$({ printf '⚙ Settings\n'; get_input; } | fzf             "${FZF_OPTS[@]}" --prompt="Wallpaper > " --header "$(< "$STATUS_FILE")")
        > "$STATUS_FILE"
    else
        selection=$({ printf '⚙ Settings\n'; get_input; } | fzf             "${FZF_OPTS[@]}" --prompt="Wallpaper > ")
    fi
    [[ -z "$selection" ]] && exit

    if [[ "$selection" == "⚙ Settings" ]]; then
        settings_menu
        continue
    fi
    break
done

wallpath="${selection##*|}"
WALLPAPER_JPEG="$LAST_DIR/wallpaper-${SCREEN}.jpeg"
echo "Launching wallpaper on $SCREEN..."
printf '%s\n' "$wallpath" > "$LAST_DIR/we-last-wallpaper-${SCREEN}"

kill_wallpaper

inotifywait -q -e close_write "$WALLPAPER_JPEG" &
INOTIFY_PID=$!

launch_wallpaper "$wallpath" &

wait "$INOTIFY_PID"

apply_colors "$WALLPAPER_JPEG"

kill "$PPID"
