# Uncomment first and last line to enable profiling
# zmodload zsh/zprof

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=/Users/$(whoami)/.oh-my-zsh

# Custom ZSH paths
export ZSH_CUSTOM=$ZSH/custom
export ZSH_CUSTOM_PLUGINS=$ZSH_CUSTOM/plugins

# Helpers
BLACK='\033[0;30m';         DARK_GRAY='\033[1;30m';
RED='\033[0;31m';           L_RED='\033[1;31m';
GREEN='\033[0;32m';         L_GREEN='\033[1;32m';
BROWN_ORANGE='\033[0;33m';  YELLOW='\033[1;33m';
BLUE='\033[0;34m';          L_BLUE='\033[1;34m';
PURPLE='\033[0;35m';        L_PURPLE='\033[1;35m';
CYAN='\033[0;36m';          L_CYAN='\033[1;36m';
L_GRAY='\033[0;36m';        WHITE='\033[1;36m';
NC='\033[0m'; # No Color

installed_count=0;
# Brew Tools
CLI_TOOLS=(
  n 
  jq 
  fzf 
  fzy
  terminal-notifier 
  python 
  thefuck
);

# Oh-My-Zsh Custom Plugins - format "<git author>:<package name>"
CUSTOM_PLUGINS=(
  "zsh-users:zsh-autosuggestions"
  "zsh-users:zsh-syntax-highlighting"
  "l4u:zsh-output-highlighting"
  "lukechilds:zsh-better-npm-completion"
  "mango-tree:zsh-recall"
  "jimmijj:chromatic-zsh"
);

# Python Packages to Install
PYTHON_PACKAGES=(
  "pygments"
);

# Gems to Install
GEMS=(
  colorls
);

# Short had print for color output
e() {
  printf $1;
}

gathering() {
  e "${CYAN}Gathering ${NC}$1 ${CYAN}$2 ...${NC}\n";
}

installing() {
  e "\t${CYAN}Installing ${RED}$1${NC} ...";
}

already-installed () {
  e " ${PURPLE}ALREADY INSTALLED\n";
}

success() {
 e " ${GREEN}DONE\n"
}

error ()  {
  e " ${RED}ERROR\n"
}

finished-task-with-count() {  
  e "\t${GREEN}Done${NC}: Installed ${RED}$1 ${GREEN}$2(s)${NC}\n";
}


finished-task() {
  e "\t${GREEN}Done${NC}: Installed ${GREEN}$1${NC}\n";
}

fetching() {
  e "\t${CYAN}Fetching ${L_GREEN}$2${NC}:${GREEN}$1 ${NC}...";
}

# Times the run of a single function 
timed() {
  start=$(($(gdate +%s%N)/1000000));
  run-function $1 $2;
  end=$(($(gdate +%s%N)/1000000));
  elapsed=$(($end-$start));
  e "${NC}Finished ${GREEN}$1${NC}. Took ${RED}$elapsed ${NC}ms\n\n";
}

# Prints the task name and runs the function provided
run-function() {
  printf "${BLUE}==== ${NC}"
  e "Running: ${GREEN}$1 ${NC}...\n"; $2;
}

# Downloads and installs PIP
get-pip() {
  curl https://bootstrap.pypa.io/get-pip.py -o ~/get-pip.py && python3 ~/get-pip.py 
} #2>/dev/null

# Downloads all missing Oh-My-Zsh Custom Plugins
get-zsh-plugins() {
  gathering "Oh-My-Zsh" "Plugins"
  count=0;
  _ifs=$IFS;
  IFS=":";

  install() {
    git clone "git@github.com:$1/$2.git" "$ZSH_CUSTOM_PLUGINS/$2" && success;
    count=$((count + 1));
  }

  [ ! -d $ZSH_CUSTOM/themes/powerlevel10k ] && {git clone --depth=1 git@github.com:romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k} && count=$((count+1));

  for plugin ($CUSTOM_PLUGINS); do
    read -r -A entry <<< $plugin 
    author=${entry[1]};
    package=${entry[2]};

    fetching $package $author;
    if [ -d "$ZSH_CUSTOM_PLUGINS/$package" ]; then 
      e " ${PURPLE}ALREADY INSTALLED\n";
    else
      install "$author" "$package";
    fi
  done

  installed_count=$((installed_count + $count));
  finished-task-with-count $count "ZSH Plugin"
  IFS=$_ifs
} 2>/dev/null

# Installs Brew
get-brew() {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
} 2>/dev/null

# Downloads all brew packages
get-brew-packages() {
  gathering "Brew" "Casks"
  count=0;
  total=0;
  list=$(brew list);
  
  not-in-list() {
    return $(! echo $list | grep -q $1)
  }

  install() {
    { brew install ${$1} &>/dev/null && e "${GREEN}DONE"; count=$((count+1));} || e "${RED}ERROR\n";
  }

  run-list() {
    for tool ($CLI_TOOLS); do
      installing $tool
      if $(not_in_list $tool); then 
        install $tool && success
      else
        already-installed
      fi
    done
  }

  # Coreutils required for gdate and other processes
  if not-in-list coreutils; then
    install "coreutils"
  fi
  
  run-list;
  installed_count=$((installed_count + $count));
  finished-task-with-count $count "Brew Package";
} 2>/dev/null

get-python-packages(){
  gathering "Python" "Packages"
  e "\t Current not implemented \n"
} #2>/dev/null

get-gems() {
  gathering "Ruby" "Gems"
  count=0;
  for gem ($GEMS); do
    installing $gem;
    if [ gem list -i "^$tool$" ]; then 
      { gem install ${tool} && success; count=$((count+1));} || error;
    else 
      already-installed
    fi 
  done

  installed_count=$((installed_count + $count));
  finished-task-with-count $count "Ruby Gem"
} 2>/dev/null

get-nerd-fonts() {
  gathering "Nerd Fonts"
  fetching "nerd-fonts" "ryanoasis";
  if [ -d "~/nerd-fonts" ]; then
    e "\t${RED}Nerd Fonts may have already been installed.\n\t${NC}Try running \"source ~/nerd-fonts/install.sh\" to manually install them again"
  else
    git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git ~/nerd-fonts && \. ~/nerd-fonts/install.sh;
    {success; finished-task "Nerd Fonts";} ||
    e "\n${RED}Error${NC}: Failed to Install ${GREEN} Nerd Fonts${NC}.\n" 
  fi
} 2>/dev/null

get-iterm2-shell-integration() {
  fetching 'iTerm2 Oh-My-Zsh Shell Integration' 'iTerm2';

  if [ -f "~/.iterm2_shell_integration.zsh" ]; then
    e "\t${RED}iTerm2 Oh-My-Zsh Shell integration may have already been installed.\n\t${NC}Check ~/.iterm2_shell_integration.zsh for more information"
  else
    curl -L https://iterm2.com/shell_integration/zsh -o ~/.iterm2_shell_integration.zsh && 
    {success; finished-task "iTerm2 Oh-My-Zsh Shell Integration";} ||
    e "\n${RED}Error${NC}: Failed to Install ${GREEN}iTerm2 Oh-My-Zsh Shell integration${NC}.\n" 
  fi

} 2>/dev/null

setup-env() {
  installed_count=0;
  tool_count=$(echo "${#CLI_TOOLS[*]} + ${#GEMS[*]} + ${#PYTHON_PACKAGES[*]}" | bc)
  e "${YELLOW}Installing $tool_count CLI Tool(s)\n${NC}";
  timed "ZSH Plugins" get-zsh-plugins;
  timed "Brew Packages" get-brew-packages;
  timed "Python Packages" get-python-packages;
  timed "Gems" get-gems;
  timed "Nerd Fonts" get-nerd-fonts;
  timed "iTerm2 Integration" get-iterm2-shell-integration;
  e "${GREEN}Successfully Installed ${RED}${installed_count} ${YELLOW}CLI Tool(s) \n${NC}";
  exec zsh;
} 

quick-clean() {
  rm -rf $ZSH_CUSTOM_PLUGINS;
  brew uninstall n jq fzf terminal-notifier python thefuck;
  gem uninstall colorls --silent;
  rm -rf ~/nerd-fonts;
  rm -rf ~/.iterm2_shell_integration.zsh;
}
## ZSH Settings
# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# Disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Enable command auto-correction.
ENABLE_CORRECTION="true"

# Other Settings
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=white'
ZSH_COLORIZE_STYLE="colorful"

# ZSH System Plugins
plugins+=( 
  bgnotify                # Cross-platform background notifications for long running commands                                           -- https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/bgnotify
  colorize                # Syntax-highlight file contents of over 300 supported languages and other text formats.                      -- https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/colorize
  command-not-found       # Provides suggested packages to be installed if a command cannot be found.                                   -- https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/command-not-found
  copydir                 # Copies the path of your current folder to the system clipboard.                                             -- https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/copydir
  copyfile                # Puts the contents of a file in your system clipboard so you can paste it anywhere.                          -- https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/copyfile
  dircycle                # Enables directory navigation similar to using back and forward on browsers                                  -- https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/dircycle
  dirhistory              # Allows you to navigate the history of previous current-working-directories using OPT + Arrow                -- https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/dirhistory
  git-auto-fetch          # Automatically fetches all changes from all remotes while you are working in a git-initialized directory   -- https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git-auto-fetch
  osx                     # Provides a few utilities to make it more enjoyable on macOS                                                 -- https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/osx
  per-directory-history   # Adds per-directory history for zsh, as well as a global history                                             -- https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/per-directory-history
  thefuck                 # The Fuck plugin — magnificent app which corrects your previous console command                              -- https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/thefuck
  zsh-interactive-cd      # Adds a fish-like interactive tab completion for the cd command                                              -- https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/zsh-interactive-cd
  zsh_reload              # Defines a function to reload the zsh session                                                                -- https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/zsh_reload
)

# Fun ZSH Plugins
plugins+=(
  lol # Plugin for adding catspeak aliases, because why not. -- https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/lol
)

# ZSH Addon Plugins for personalization
plugins+=( 
  zsh-syntax-highlighting     # Enables highlighting of commands whilst they are typed          -- https://github.com/zsh-users/zsh-syntax-highlighting
  zsh-autosuggestions         # Suggests commands as you type based on history and completions  -- https://github.com/zsh-users/zsh-autosuggestions
  zsh-output-highlighting     # Syntax highlighting for command's output in zsh                 -- https://github.com/l4u/zsh-output-highlighting
  zsh-better-npm-completion   # Better completion for npm                                       -- https://github.com/lukechilds/zsh-better-npm-completion
  zsh-recall                  # zsh plugin to use history command more comfortably              -- https://github.com/mango-tree/zsh-recall
)

# Load oh-my-zsh and respective plugins
# See resources/notes for profiling script(s)
source $ZSH/oh-my-zsh.sh

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# Enable colorls tab completion
[ -s $(dirname $(gem which colorls))/tab_complete.sh ] && \. $(dirname $(gem which colorls))/tab_complete.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Enable Fuzzy Finder
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Load Chromatic Zsh Plugin
[[ -f $ZSH_CUSTOM_PLUGINS/chromatic-zsh/chromatic-zsh.zsh ]] && source $ZSH_CUSTOM_PLUGINS/chromatic-zsh/chromatic-zsh.zsh


autoload -U compinit && compinit
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select

# Aliases
alias love="/Applications/love.app/Contents/MacOS/love"
alias c="clear"
alias l='colorls -A --tree=1 --git-status --sd $1'
alias icode="code-insiders"

# Enable iTerm2 Shell Integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" || {e "${RED}Error:${CYAN} iTerm2 Shell Integration Not Found. Installing now:\n" && get-iterm2-shell-integration; source "~/.iterm2_shell_integration"} 

### Related Resources/Notes: 

## bgnotify: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/bgnotify
# Requires terminal-notifier via brew install terminal-notifier or gem install terminal-notifier

## Add the following to ~/.oh-my-zsh/oh-my-zsh.sh to get per plugin profiling
# for plugin ($plugins); do
#   timer=$(($(gdate +%s%N)/1000000))
#   if [ -f $ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh ]; then
#     source $ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh
#   elif [ -f $ZSH/plugins/$plugin/$plugin.plugin.zsh ]; then
#     source $ZSH/plugins/$plugin/$plugin.plugin.zsh
#   fi
#   now=$(($(gdate +%s%N)/1000000))
#   elapsed=$(($now-$timer))
#   echo $elapsed":" $plugin
# done

## Colorize: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/colorize
# Requires Chroma or Pygments
# [ZSH_COLORIZE_TOOL, ZSH_COLORIZE_STYLE]
# ccat <file> [files]: colorize the contents of the file (or files, if more than one are provided). 
# If no files are passed it will colorize the standard input.
# 
# cless [less-options] <file> [files]: colorize the contents of the file (or files, if more than one are provided) and open less. 
# If no files are passed it will colorize the standard input. The LESSOPEN and LESSCLOSE will be overwritten for this to work, but only in a local scope.

# Uncomment first and following line to enable zsh profiling
# zprof