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
alias path.list='echo "$PATH" | tr ":" "\n"'
alias t='tldr --theme ocean'
alias find.dir='find . -type d -iname'
alias find.file='find . -type f -iname'
alias find.inside='grep --exclude-dir={node_modules,.git} -Irlw . -e'
alias find.gzip='find . -iname '''*.gz''' | sort | xargs gzip -dc | grep -Eie'
alias restart='sudo shutdown -r now'

# Node.js

alias ns='node server'
alias na='node app'
alias r='npm run -s'
alias ni='npm install'
alias nid='npm install -D'
# Convert an epoch with or without milliseconds to ISO string
alias ts='node -pe "process.argv[1] ? new Date(+(process.argv[1]+'\''000'\'').slice(0,13)).toISOString() : Date.now()" -- '

# Git

alias g=git

# Bring these aliases from .gitconfig to global scope
for k in s d a p pf pr pop rba rbi lg rhh rh1 rs1 stu stl stc l1 bb; do
	alias $k="git $k"
done

for k in st cmnv rbc ame amne; do
	alias $k="a && git $k"
done

alias stpll='st && pr && pop'
alias stpsh='st && pr && p && pop'
# alias rbm='_br_=$(git rev-parse --abbrev-ref HEAD) && git co master && pr && git co $_br_ && git rebase master'
# alias rbm='git fetch -p && git rebase origin/master'
alias rbm='git com && pr && git co - && git rbm'
alias rbd='git co dev && pr && git co - && git rb dev'
alias rdb=rbd
alias rbp='git co prod && pr && git co - && git rb prod'
alias rpb=rbp
alias rbbranch='git rebase -i $(git merge-base $(git rev-parse --abbrev-ref HEAD) master)'
alias misc='a && git cm "Modified $(git diff --name-only HEAD | grep -Eo ''[^/]+$'')" && p'
alias last_commit='git log -1 --pretty=%B | clip'
#alias first_foreign_commit='git log --graph --pretty=format:"%h %an" | grep -vi "$(git config user.name)" | head -n1 | cut -d" " -f1'
alias first_foreign_commit='git rev-list --boundary ...master | grep "^-" | cut -c2- | tail -n1'
alias rbmine='git rebase -i $(first_foreign_commit)'
alias set_upstream='git branch --set-upstream-to=origin/$(git rev-parse --abbrev-ref HEAD) $(git rev-parse --abbrev-ref HEAD)'
alias git_gc='git fetch --prune && git fsck --unreachable && git reflog expire --expire=now --all && git gc --prune=now --aggressive'
alias git_delete_other_branches="git fetch -p && git branch | grep -ve '*' -e master -e main -e dev -e stg -e prod | xargs git branch -d" # --force
alias todev='git co dev && pr && git fp && git_delete_other_branches -f; git_gc'
alias toprod='git co prod && pr && git fp && git_delete_other_branches -f; git_gc'

# Internet

alias localip='ipconfig | grep -a IPv4 | tr " " "\n" | tail -n1'
# Ping one of Google's DNS servers
alias online='ping 8.8.8.8'
# Ping a domain to also check DNS resolution
alias onlined='ping google.com'
alias dns.blocked="tail -n99 /opt/dnscrypt-proxy/blocked.log | awk '{print \$1,\$2,\$4,\$5}' | sort -r | awk '!a[\$3]++' | sort"
alias dns.queries="tail -n99 /opt/dnscrypt-proxy/query.log | awk '{print \$1,\$2,\$4,\$5,\$6,\$7}' | sort -r | awk '!a[\$3]++' | sort"
alias dns.restart='sudo systemctl restart dnscrypt-proxy.service'
alias dns.whitelist='code /opt/dnscrypt-proxy/domain-whitelist.txt --wait && dns.restart'
alias dns.clear='for f in /opt/dnscrypt-proxy/*.log; do echo "" | sudo tee "$f"; done'
alias dns.logs='sudo journalctl -u dnscrypt-proxy.service'
alias dns.enable='sudo cp /etc/resolv.conf.override /etc/resolv.conf'
alias dns.disable='sudo cp /etc/resolv.conf.bkp /etc/resolv.conf'
# Ollama
alias ollama.restart='sudo systemctl restart ollama'
alias ollama.stop='sudo systemctl stop ollama'
alias ollama.logs='sudo journalctl -u ollama.service'
# History (history.forget is in .bash_functions)
alias history.restore='cp ~/.bash_history.bkp ~/.bash_history'
alias history.grep='history | grep'
alias history.forget='forget'
alias history.edit='code ~/.bash_history'
# Keyboard
alias keyboard.keys="xev | grep -A2 --line-buffered '^KeyRelease' | sed -n '/keycode /s/^.*keycode \([0-9]*\).* (.*, \(.*\)).*$/\1 \2/p'"
alias keyboard.dump='sleep 1; xdotool type "$(xclip -o -selection clipboard)"'
# Other

# Add an "alert" alias for long running commands. Use like so: sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
alias sai='sudo apt install -y'
alias sau='sudo apt update -y && sudo apt upgrade -y'
alias si='snap install'
alias sr='snap refresh'
alias reload='source ~/.bashrc'
alias rs='rsync -vru'
alias dotfiles.sync='find ~ -maxdepth 1 -type f -mtime -1 | grep -e git -e bash | grep -ve history -e extras | parallel cp {} ~/Backup/Home/dotfiles/home; cp ~/bin/*.sh ~/Backup/Home/dotfiles/home/bin'
# Extract prompt from an image
alias prompt="identify -format '%[parameters]'"
