# Auto-activate .venv when entering a directory and deactivate when leaving
auto_activate_venv() {
    # If there's a .venv directory and no virtualenv is active, activate it
    if [ -d ".venv" ] && [ -z "$VIRTUAL_ENV" ]; then
        echo "Activating virtual environment (.venv)..."
        
        # Check the OS and set the correct activation path
        case "$(uname -s)" in
            (Linux|Darwin)  # Linux or macOS
                source .venv/bin/activate
                ;;
            (CYGWIN*|MINGW*|MSYS*|MINGW64*)  # Windows (Git Bash or MINGW)
                source .venv/Scripts/activate
                ;;
            (*)
                echo "Unsupported OS for auto-activation."
                ;;
        esac
    fi
}

auto_deactivate_venv() {
    # If a virtualenv is active and we leave the directory, deactivate it
    if [ -n "$VIRTUAL_ENV" ]; then
        echo "Deactivating virtual environment..."
        deactivate
    fi
}

# Redefine the 'cd' command to include activation and deactivation logic
cd() {
    auto_deactivate_venv  # Deactivate before changing directories
    builtin cd "$@" && auto_activate_venv  # Activate if needed
}

# Custom functions for prompt
get_memory_usage() {
    case "$(uname -s)" in
        (Linux|Darwin)
            free -h | awk '/^Mem/ {print $3 "/" $2}'
            ;;
        (CYGWIN*|MINGW*|MSYS*|MINGW64*)
            wmic OS get FreePhysicalMemory,TotalVisibleMemorySize /Format:List 2>/dev/null | awk -F= '
            /FreePhysicalMemory/ {free=$2} 
            /TotalVisibleMemorySize/ {total=$2} 
            END {if (total > 0) printf "%.1fG/%.1fG", (total-free)/1024/1024, total/1024/1024; else print "N/A"}'
            ;;
        (*)
            echo "N/A"
            ;;
    esac
}

get_git_remote() {
    git config --get remote.origin.url 2>/dev/null || echo "No Remote"
}

get_python_version() {
    python --version 2>/dev/null | awk '{print $2}'
}

get_os_emoji() {
    case "$(uname -s)" in
        (Linux)
            echo "🐧"  # Penguin for Linux
            ;;
        (Darwin)
            echo "🍎"  # Apple for macOS
            ;;
        (CYGWIN*|MINGW*|MSYS*|MINGW64*)
            echo "🪟"  # Window for Windows
            ;;
        (*)
            echo "❓"  # Unknown OS
            ;;
    esac
}

get_git_branch() {
    local branch=$(git branch --show-current 2>/dev/null || echo "No Branch")
    if [ "$branch" != "No Branch" ]; then
        echo "$branch"  # Add branch emoji
    else
        echo "$branch"
    fi
}

get_venv_status() {
    if [ -n "$VIRTUAL_ENV" ]; then
        echo "🟢 venv active"  # Green dot if venv is active
    else
        echo "🔴 venv inactive"  # Red dot if venv is inactive
    fi
}

# Update prompt dynamically
update_prompt() {
    local mem_usage=$(get_memory_usage)
    local git_remote=$(get_git_remote)
    local git_branch=$(get_git_branch)
    local python_version=$(get_python_version)
    local os_emoji=$(get_os_emoji)
    local venv_status=$(get_venv_status)

    PS1='\[\e[38;5;45m\]'"$os_emoji"' \u \[\e[38;5;208m\]💻 @\h \[\e[38;5;220m\]🧠 '"$mem_usage"' \[\e[38;5;82m\]🌐 '"$git_remote"' \[\e[38;5;226m\]['"$git_branch"'] \[\e[38;5;129m\]🐍 Python '"$python_version"' \[\e[38;5;202m\]'"$venv_status"' \[\e[38;5;33m\]📁 \w\n\[\e[38;5;15m\]➜ '
}

deactivate() {
    # reset old environment variables
    if [ -n "$_OLD_VIRTUAL_PATH" ] ; then
        PATH="$_OLD_VIRTUAL_PATH"
        export PATH
        unset _OLD_VIRTUAL_PATH
    fi
    if [ -n "$_OLD_VIRTUAL_PYTHONHOME" ] ; then
        PYTHONHOME="$_OLD_VIRTUAL_PYTHONHOME"
        export PYTHONHOME
        unset _OLD_VIRTUAL_PYTHONHOME
    fi

    # This should detect bash and zsh, which have a hash command that must
    # be called to get it to forget past commands.  Without forgetting
    # past commands the $PATH changes we made may not be respected
    if [ -n "$BASH" -o -n "$ZSH_VERSION" ] ; then
        hash -r
    fi

    if [ -n "$_OLD_VIRTUAL_PS1" ] ; then
        PS1="$_OLD_VIRTUAL_PS1"
        export PS1
        unset _OLD_VIRTUAL_PS1
    fi

    unset VIRTUAL_ENV
    if [ ! "$1" = "nondestructive" ] ; then
        # Self destruct!
        unset -f deactivate
    fi
}

PROMPT_COMMAND=update_prompt