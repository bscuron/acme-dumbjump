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
		echo "find . -type f | xargs grep -nE"
	else
		echo "git grep -nP"
	fi
}

selection=$(9p read "acme/$winid/rdsel" | sed 's/[][()\.^$?*+]/\\&/g')

if [ -z "$selection" ]; then
	exit 1
fi

file_path=$(9p read "acme/$winid/tag" | paste -sd '\0' - | cut -d ' ' -f1)
file_name=$(basename "$file_path")
file_extension="${file_name##*.}"
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
	# C#/Java/Salesforce Apex
	*.cs|*.java|*.cls|*.apex|*.trigger)
		eval "$grepprg \"^\s*(?:[\w\[\]]+\s+){1,3}$selection\s*\\(\""
		eval "$grepprg \"\s*\b$selection\s*=[^=\n)]+\""
		eval "$grepprg \"(class|interface)\s*$selection\b\""
		;;
	# Python
	*.py)
		eval "$grepprg \"\s*\b$selection\s*=[^=\n]+\""
		eval "$grepprg \"def\s*$selection\b\s*\\(\""
		eval "$grepprg \"class\s*$selection\b\s*\\(?\""
		;;
	# C/C++
	*.c|*.h|*.C|*.H|*.tpp|*.cpp|*.hpp|*.cxx|*.hxx|*.cc|*.hh|*.c++|*.h++)
		eval "$grepprg \"\b$selection(\s|\))*\((\w|[,&*.<>:]|\s)*(\))\s*(const|->|\{|$)|typedef\s+(\w|[(*]|\s)+$selection(\)|\s)*\(\""
		eval "$grepprg \"(\b\w+|[,>])([*&]|\s)+$selection\s*(\[([0-9]|\s)*\])*\s*([=,){;]|:\s*[0-9])|#define\s+$selection\b\""
		eval "$grepprg \"\b(?!(class\b|struct\b|return\b|else\b|delete\b))(\w+|[,>])([*&]|\s)+$selection\s*(\[(\d|\s)*\])*\s*([=,(){;]|:\s*\d)|#define\s+$selection\b\""
		eval "$grepprg \"\b(class|struct|enum|union)\b\s*$selection\b\s*(final\s*)?(:((\s*\w+\s*::)*\s*\w*\s*<?(\s*\w+\s*::)*\w+>?\s*,*)+)?((\{|$))|}\s*$selection\b\s*;\""
		;;
	# Rust
	*.rs)
		eval "$grepprg \"(if|while)\\s+let\\s+([^=\\n]+)?(mut\\s+)?$selection([^=\\n\\\(]+)?\\s*=\\s*[^=\\n]+\""
		eval "$grepprg \"struct\s+[^\n{]+[{][^}]*(\s*$selection\s*:\s*[^\n},]+)[^}]*}\""
		eval "$grepprg \"enum\s+[^\n{]+\s*[{][^}]*\b$selection\b[^}]*}\""
		eval "$grepprg \"\bfn\s+$selection\s*\\(\""
		eval "$grepprg \"\bmacro_rules!\s+$selection\""
		eval "$grepprg \"struct\s+$selection\s*[{\\(]?\""
		eval "$grepprg \"trait\s+$selection\s*[{]?\""
		eval "$grepprg \"\btype\s+$selection([^=\n]+)?\s*=[^=\n]+;\""
		eval "$grepprg \"impl\s+((\w+::)*\w+\s+for\s+)?(\w+::)*$selection\s+[{]?\""
		eval "$grepprg \"mod\s+$selection\s*[{]?\""
		;;
	# Go
	*.go)
		eval "$grepprg \"\s*\b$selection\s*=[^=\n]+\""
		eval "$grepprg \"\s*\b$selection\s*:=\s*\""
		eval "$grepprg \"func\s+\\([^\\)]*\\)\s+$selection\s*\\(\""
		eval "$grepprg \"func\s+$selection\s*\\(\""
		eval "$grepprg \"type\s+$selection\s+struct\s+\\{\""
		;;
	# Default
	*)
		eval "$grepprg \"$selection\""
		;;
esac
