#!/usr/bin/env zsh


function doQuietly() {
    "$@" > /dev/null 2>&1;
    ret=$?
    if [ $ret != 0 ]; then
        echo "\n🤬 Command [ $@ ] failed with return code: $ret\n";
    fi
}

function preFlight() {
    echo "\n=== 🚀 Running Pre-Flight Checks 🚀 === \n"

    echo "🔦 Looking for git..."
    if ! command -v git &> /dev/null; then
        echo "😳 Git binary is not on path!";
        case `uname` in
            Darwin)
                echo "🛠 Installing XCode Command Line tools...";
                xcode-select --install;
                while ! command -v git &> /dev/null; do
                    echo "\n⌛ Waiting for installation to finish...";
                    sleep 10;
                done;
            ;;
            Linux)
                # I only use Fedora and CentOS...
                echo "🛠 Installing Git...";
                sudo dnf install -y git-all
            ;;
        esac
    fi

    if [ "$(uname)" = "Darwin" ]; then
        echo "🍺 Looking for brew...";
        if ! command -v brew &> /dev/null; then
            echo "\n🥛 That isn't beer... Going to the bar to get some brew!\n"
            echo "Kindly provide your sudo password to install Homebrew. ^C to skip this step."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)";
        fi
    fi

    echo "\n✅ Pre-Flight Checks Passed!\n"
}


function doIt() {
    echo "\n=== 📥 Installing Dot Files 📥 === \n";
    returnTo="$PWD";
    cd ~/.dotfiles;   
    echo "🌎 Fetching changes from remote repository..."
    doQuietly git pull origin primary;
    echo "✨ Updating submodule libraries and themes..."
    doQuietly git submodule update --init --recursive;
    doQuietly git submodule update --remote;
    echo "🏠 Synchronizing home directory:\n"
    rsync --exclude ".git/" \
        --exclude ".DS_Store" \
        --exclude ".osx" \
        --exclude "custom" \
        --exclude ".gitmodules" \
        --exclude "bootstrap.sh" \
        --exclude ".tmux-themepack" \
        --exclude ".oh-my-zsh" \
        --exclude "README.md" \
        --exclude "LICENSE-MIT.txt" \
        -avh --no-perms ~/.dotfiles/ ~;

    echo "\n🐚 Sourcing ZSH RC to update current shell...";
    # Temporarily disable autocompletion warnings.
    ZSH_DISABLE_COMPFIX=true;
    source ~/.zshrc;

    echo "🛡 Ensuring proper permissions on auto-complete directories...";
    compaudit | xargs chmod g-w,o-w;
    unset ZSH_DISABLE_COMPFIX;
    
    cd "$returnTo";

    echo "\n✅ Dot Files Pulled and Updated!\n"
}

if [ "$1" = "--force" -o "$1" = "-f" ]; then
    preFlight;
    doIt;
else
    read "REPLY?This may overwrite existing files in your home directory. Are you sure? (y/n) ";
    echo "";
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        preFlight;
        doIt;
    fi;
fi;
unset doIt;
