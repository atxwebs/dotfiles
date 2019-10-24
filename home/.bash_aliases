# Shell

alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias b='cd -'
alias ~='cd ~'
alias zz='z -c'
alias rr='rm -r'
alias rrf='rr -f'
alias mkp='mkdir -p'
alias pathlist='echo "$PATH" | tr ":" "\n"'

# Node.js

alias ns='node server'
alias na='node app'
alias prod='NODE_ENV=production'
alias r='npm run -s'
# Convert an epoch with or without milliseconds to ISO string
alias ts='node -pe "new Date(+(process.argv[1]+'\''000'\'').slice(0,13)).toISOString()" -- '

# Git Bash aliases node to 'winpty node.exe' which is needed for repl but breaks piping
unalias node &>/dev/null
alias repl='winpty node'

# Git

# Bring these aliases from .gitconfig to global scope
for k in s d a undo rev discard cma p pf pr pop rba rbi lg; do
	alias $k="git $k"
done

alias st='a && git stash'
alias stpll='st && pr && pop'
alias stpsh='st && pr && p && pop'
alias rbm='_br_=$(git rev-parse --abbrev-ref HEAD) && git co master && pr && git co $_br_ && git rebase master'
alias rbc='a && git rbc'
alias rbbranch='git rebase -i $(git merge-base $(git rev-parse --abbrev-ref HEAD) master)'
alias misc='a && git cm "Modified $(git diff --name-only HEAD | grep -Eo ''[^/]+$'')" && p'
alias last_commit='git log -1 --pretty=%B | clip'
alias cmnv='git commit --no-verify -m'
#alias first_foreign_commit='git log --graph --pretty=format:"%h %an" | grep -vi "$(git config user.name)" | head -n1 | cut -d" " -f1'
alias first_foreign_commit='git rev-list --boundary ...master | grep "^-" | cut -c2-'
alias rbmine='git rebase -i $(first_foreign_commit)'
alias set_upstream='git branch --set-upstream-to=origin/$(git rev-parse --abbrev-ref HEAD) $(git rev-parse --abbrev-ref HEAD)'
alias ame='a && git ame'
alias amne='a && git amne'
alias git_gc='git fetch --prune && git fsck --unreachable && git reflog expire --expire=now --all && git gc --prune=now'
alias git_delete_other_branches="git branch | grep -ve '*' -e master | xargs git branch -D"

# Internet

alias localip='ipconfig | grep -a IPv4 | tr " " "\n" | tail -n1'
# Ping one of Google's DNS servers
alias online='ping 8.8.8.8'
# Ping a domain to also check DNS resolution
alias onlined='ping google.com'

# Dotfiles

alias reload='source ~/.bashrc'
alias dotfiles='sh -eui ~/dotfiles/install.sh && reload'
