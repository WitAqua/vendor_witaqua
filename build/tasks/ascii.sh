#!/bin/bash

# gradation colors inspired by oh-my-logo(https://github.com/shinshin86/oh-my-logo)
START_R=78
START_G=168
START_B=255
END_R=127
END_G=136
END_B=255

ascii=(
" ██╗    ██╗ ██╗ ████████╗  █████╗   ██████╗  ██╗   ██╗  █████╗"
" ██║    ██║ ██║ ╚══██╔══╝ ██╔══██╗ ██╔═══██╗ ██║   ██║ ██╔══██╗"
" ██║ █╗ ██║ ██║    ██║    ███████║ ██║   ██║ ██║   ██║ ███████║"
" ██║███╗██║ ██║    ██║    ██╔══██║ ██║▄▄ ██║ ██║   ██║ ██╔══██║"
" ╚███╔███╔╝ ██║    ██║    ██║  ██║ ╚██████╔╝ ╚██████╔╝ ██║  ██║"
"  ╚══╝╚══╝  ╚═╝    ╚═╝    ╚═╝  ╚═╝  ╚══▀▀═╝   ╚═════╝  ╚═╝  ╚═╝"
)

for line in "${ascii[@]}"; do
    len=${#line}
    out=""
    for ((i=0; i<$len; i++)); do
        char="${line:$i:1}"
        ratio=$(awk "BEGIN {print $i/($len-1)}")
        r=$(awk "BEGIN {printf \"%d\", $START_R + ($END_R - $START_R)*$ratio}")
        g=$(awk "BEGIN {printf \"%d\", $START_G + ($END_G - $START_G)*$ratio}")
        b=$(awk "BEGIN {printf \"%d\", $START_B + ($END_B - $START_B)*$ratio}")
        out+="\e[38;2;${r};${g};${b}m${char}\e[0m"
    done
    echo -e "$out"
done
