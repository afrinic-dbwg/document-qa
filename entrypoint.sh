#!/usr/bin/env bash

set -e
set -o pipefail
shopt -sq globstar

# Set the working directory
workspace="${GITHUB_WORKSPACE:-$WORKING_DIR}"

# Choose the language
language="en_US"

# Set up the local dictionary
local_dict="local"
global_wordlist="${ACTION_DIR}/dictionary"
local_wordlist="${workspace}/.dictionary-local"
wordlist="$(mktemp)"
dict_file="${workspace}/${local_dict}.dic"
cat "${global_wordlist}" "${local_wordlist}" | sort | uniq > "${wordlist}"
wc -l "${wordlist}" > "${dict_file}"
cat "${wordlist}" >> "${dict_file}"

# Colorized output helpers
colored() {
    color="${1}"
    shift
    if [ -t 1 ]; then
        printf "$(tput setaf ${color})$@$(tput sgr0)"
    elif [ -n ${GITHUB_ACTIONS} ]; then
        term="xterm-256color"
        printf "$(tput -T${term} setaf ${color})$@$(tput -T${term} sgr0)"
    else
        printf "$@"
    fi
}
red() {
    colored 1 "$@"
}
green() {
    colored 2 "$@"
}
yellow() {
    colored 3 "$@"
}

spellcheck() {
    file="${1}"
    printf "\nRunning spelling check for ${file}"
    lineno=0
    misses=0
    codeblock=0
    while read -r line; do
        (( ++lineno ))
        if echo "${line}" | grep -Eq '^```'; then
            let codeblock^=1 || true
            continue
        fi
        if [ ${codeblock} -eq 0 ]; then
            sline="$(echo "${line}" | sed -E 's/`.+`\s?//g')"
            while read -r out; do
                case "${out}" in
                    "&"*)
                        pattern='^& (.+) ([0-9]+) ([0-9]+): (.+)$'
                        result="$(echo "${out}" | sed -E "s/${pattern}/\1 \2 \3/")"
                        suggestions="$(echo "${out}" | sed -E "s/${pattern}/\4/")"
                        bad="$(echo "${result}" | cut -d ' ' -f 1)"
                        count="$(echo "${result}" | cut -d ' ' -f 2)"
                        offset="$(echo "${result}" | cut -d ' ' -f 3)"
                        printf "\nmisspelled word in line ${lineno}:\n"
                        printf "    $(echo "${line}" | sed -E "s/${bad}/$(red ${bad})/g")\n"
                        printf "   %${offset}s▲\n"
                        printf "   %${offset}s└─ found ${count} suggestions: $(green ${suggestions})\n"
                        (( ++misses ))
                        ;;
                    "#"*)
                        pattern='^# (.+) ([0-9]+)$'
                        result="$(echo "${out}" | sed -E "s/${pattern}/\1 \2/")"
                        bad="$(echo "${result}" | cut -d ' ' -f 1)"
                        offset="$(echo "${result}" | cut -d ' ' -f 2)"
                        printf "\nmisspelled word in line ${lineno}:\n"
                        printf "    $(echo "${line}" | sed -E "s/${bad}/$(red ${bad})/g")\n"
                        printf "   %${offset}s▲\n"
                        printf "   %${offset}s└─ no suggestions found\n"
                        (( ++misses ))
                        ;;
                    *)
                        ;;
                esac
            done < <(echo "^${sline}" | hunspell -d "${language},${local_dict}" \
                                                -p "${local_wordlist}" -a)
        fi
    done < ${file}
    if [ ${misses} -eq 0 ]; then
        printf "$(green "  [OK]")\n"
    else
        let errors=+misses
    fi
}

stylecheck() {
    file="${1}"
    printf "\nRunning style check for ${file}"
    issues=0
    while read -r line; do
        printf "\n$(yellow ${line})"
        (( ++issues ))
    done < <(markdownlint --config "${ACTION_DIR}/markdownlint.yml" \
                            "${file}" 2>&1)
    if [ ${issues} -eq 0 ]; then
        printf "$(green "  [OK]")\n"
    else
        printf "\n"
        let errors=+issues
    fi
}

# Switch to the workspace directory
cd "${workspace}"
# Get a list of tracked, modified and untracked files from git
files="$(git ls-files -cmo --exclude-standard **/*.md | uniq)"
# Parse CLI args
cmd="${1}"
case "${cmd}" in
    # Interactive spell checking
    --interactive|-i)
        for file in ${files}; do
            hunspell -d "${language},${local_dict}" \
                     -p "${local_wordlist}" \
                     "${file}"
         done
        ;;
    # Non-interactive spelling and style checks
    *)
        errors=0
        for file in ${files}; do
            spellcheck "${file}"
            stylecheck "${file}"
        done
        if [ ${errors} -gt 0 ]; then
            printf "\n$(red "Found ${errors} errors")\n\n"
            exit 1
        else
            printf "\n$(green "All tests passed")\n\n"
        fi
        ;;
esac

exit 0
