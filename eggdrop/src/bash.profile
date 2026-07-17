HISTCONTROL=ignoreboth:erasedups     # Ignore duplicates + lines starting with space
HISTSIZE=10000                       # Number of commands in memory
HISTFILESIZE=20000                   # Number of commands saved to file
HISTTIMEFORMAT='%F %T '              # Timestamp in history

shopt -s histappend                  # Append to history, don't overwrite
shopt -s cmdhist                     # Save multi-line commands as one
shopt -s lithist                     # (optional) Save with newlines

shopt -s autocd                      # cd by typing directory name only
shopt -s cdspell                     # Fix minor spelling errors in cd
shopt -s dirspell                    # Fix spelling in tab completion
shopt -s nocaseglob                  # Case-insensitive globbing
shopt -s globstar                    # ** for recursive globbing (e.g. ls **/*.txt)

shopt -s checkwinsize                # Update LINES/COLUMNS on resize
shopt -s expand_aliases              # Expand aliases in non-interactive shells
shopt -s extglob                     # Extended glob patterns
shopt -s progcomp                    # Programmable completion
shopt -s promptvars

set -o notify

export EDITOR=nano

ln -sf /etc/tclshrc $HOME/.tclshrc

source /etc/bash/bash_completion.sh

alias ls='ls --color=auto'
alias grep='grep --color=auto'

PS1='\[\e[01;32m\]\u@\h\[\e[00m\]:\[\e[01;34m\]\w\[\e[00m\]\$ '
