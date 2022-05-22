# Command-line tools for managing Spyder development environments

# ---- Path variables
SPYROOT=$(cd $(dirname ${BASH_SOURCE:-${(%):-%x}})/../ 2> /dev/null && pwd -P)
SPYREPO=$SPYROOT/spyder
EXTDEPS=$SPYREPO/external-deps

alias spy-install-subrepo="$SPYROOT/spyder-dev/spy-install-subrepo.sh"
alias spy-install-subrepos="$SPYROOT/spyder-dev/spy-install-subrepos.sh"
alias spy-env="$SPYROOT/spyder-dev/spy-env.sh"
alias spy-clone-subrepo="$SPYROOT/spyder-dev/spy-clone-subrepo.sh"
