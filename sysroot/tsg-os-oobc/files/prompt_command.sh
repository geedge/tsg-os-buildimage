oobc_enable_file_path="/var/lib/.tsg-os-oobc-enable"

read_oobc_value()
{
    if [ -e "$oobc_enable_file_path" ]; then
        echo "(OOBC) "
    fi
}
PROMPT_COMMAND='printf "\033]0;%s@%s:%s\007" "${USER}" "${HOSTNAME%%.*}" "${PWD/#$HOME/\~}"; PS1="[\\u@\\h $(read_oobc_value)\\W]\\$ "'
