#!/bin/sh

in_git_repo() {
	if [ -d .git ]; then
		echo ".git"
	else
		git rev-parse --git-dir 2>/dev/null
	fi
	# Not in git repo
}

get_grepprg() {
	gitrepo=$(in_git_repo)
	if [ -z "$gitrepo" ]; then
		echo "git grep -nP"
	else
		echo "find . -type f | xargs grep -nE"
	fi
}

selection=$(9p read "acme/$winid/rdsel" | sed 's/[][()\.^$?*+]/\\&/g')

if [ -z "$selection" ]; then
	exit 1
fi

file_path=$(9p read "acme/$winid/tag" | paste -sd '\0' - | cut -d ' ' -f1)
file_name=$(basename "$file_path")
grepprg=$(get_grepprg)


case "$file_name" in
	# Shell
	*.sh)
		eval "$grepprg \"function\s*$selection\s*\""
		eval "$grepprg \"$selection\(\)\s*\{\""
		eval "$grepprg \"\b$selection\s*=\s*\""
		;;
	# Javascript
	*.js|*.jsx|*.html|*.css)
		echo testing
		eval "$grepprg \"(service|factory)\\(['\']$selection['\']\""
		eval "$grepprg \"\b$selection\s*[=:]\s*\\([^\\)]*\\)\s+=>\""
		eval "$grepprg \"\b$selection\s*\([^()]*\)\s*[{]\""
		eval "$grepprg \"class\s*$selection\s*[\\(\\{]\""
		eval "$grepprg \"class\s*$selection\s+extends\""
		eval "$grepprg \"\s*\b$selection\s*=[^=\n]+' \""
		eval "$grepprg \"\bfunction\b[^\(]*\\(\s*[^\)]*\b$selection\b\s*,?\s*\\)?\""
		eval "$grepprg \"function\s*$selection\s*\\(\""
		eval "$grepprg \"\b$selection\s*:\s*function\s*\\(\""
		eval "$grepprg \"\b$selection\s*=\s*function\s*\\(\""
		;;
	*)
		eval "$grepprg \"$selection\""
esac
