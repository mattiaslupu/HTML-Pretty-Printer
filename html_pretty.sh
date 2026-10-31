#!/usr/bin/env bash

if [ -z "$1" ]; then
    printf "Folosire: %s <fisier.html>\n" "$0" >&2
    exit 1
fi

if [ ! -f "$1" ] || [ ! -r "$1" ]; then
    printf "Eroare: Fișierul '%s' nu există sau nu poate fi citit.\n" "$1" >&2
    exit 1
fi

INDENT_STR="  "
nivel=0
VOID_TAGS=" area base br col command embed hr img input keygen link meta param source track wbr "

printeaza_indentare() {
    local n=$1
    local i
    for ((i=0; i<n; i++)); do
        printf "%s" "$INDENT_STR"
    done
}

awk '
BEGIN {
    in_comment = 0
    in_raw = 0
    raw_tag = ""
    buf = ""
}
{
    buf = buf $0 "\n"

    while (length(buf) > 0) {
        if (in_comment) {
            idx = index(buf, "-->")
            if (idx > 0) {
                out = substr(buf, 1, idx + 2)
                gsub(/\r/, "", out)
                n = split(out, clines, "\n")
                for (i = 1; i <= n; i++) {
                    print "COMMENT:" clines[i]
                }
                buf = substr(buf, idx + 3)
                in_comment = 0
            } else {
                break
            }
            continue
        }

        if (in_raw) {
            low_buf = tolower(buf)
            end_pat = "</" raw_tag ">"
            idx = index(low_buf, end_pat)
            if (idx > 0) {
                content = substr(buf, 1, idx - 1)
                n = split(content, lines, "\n")
                for (i = 1; i <= n; i++) {
                    gsub(/\r/, "", lines[i])
                    if (raw_tag == "pre" || raw_tag == "textarea") {
                        print "PRE:" lines[i]
                    } else if (length(lines[i]) > 0) {
                        print "RAW:" lines[i]
                    }
                }
                close_tag = substr(buf, idx, length(end_pat))
                print "TOKEN:" close_tag
                buf = substr(buf, idx + length(end_pat))
                in_raw = 0
                raw_tag = ""
            } else {
                break
            }
            continue
        }

        lt = index(buf, "<")
        if (lt == 0) {
            txt = buf
            gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", txt)
            gsub(/[ \t\r\n]+/, " ", txt)
            if (length(txt) > 0) print "TEXT:" txt
            buf = ""
            break
        }

        if (lt > 1) {
            txt = substr(buf, 1, lt - 1)
            gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", txt)
            gsub(/[ \t\r\n]+/, " ", txt)
            if (length(txt) > 0) print "TEXT:" txt
            buf = substr(buf, lt)
        }

        if (substr(buf, 1, 4) == "<!--") {
            in_comment = 1
            continue
        }

        gt = 0
        in_q = ""
        len = length(buf)
        for (i = 2; i <= len; i++) {
            c = substr(buf, i, 1)
            if (in_q != "") {
                if (c == in_q) in_q = ""
            } else {
                if (c == "\"" || c == "\047") in_q = c
                else if (c == ">") { gt = i; break }
            }
        }

        if (gt == 0) {
            break
        }

        tag = substr(buf, 1, gt)
        gsub(/[ \t\r\n]+/, " ", tag)
        print "TOKEN:" tag
        buf = substr(buf, gt + 1)

        low_tag = tolower(tag)
        if (low_tag ~ /^<(script|style|pre|textarea)([ \t>]|$)/ && low_tag !~ /\/>$/) {
            in_raw = 1
            raw_tag = low_tag
            sub(/^</, "", raw_tag)
            sub(/[ \t>].*$/, "", raw_tag)
        }
    }
}
' "$1" | \
while IFS= read -r linie || [ -n "$linie" ]; do

    tip="${linie%%:*}"
    continut="${linie#*:}"

    if [ "$tip" = "PRE" ]; then
        printf "%s\n" "$continut"
        continue
    fi

    if [ "$tip" = "RAW" ]; then
        continut_trim="${continut#"${continut%%[![:space:]]*}"}"
        continut_trim="${continut_trim%"${continut_trim##*[![:space:]]}"}"
        if [ -n "$continut_trim" ]; then
            printeaza_indentare "$nivel"
            printf "%s\n" "$continut_trim"
        fi
        continue
    fi

    if [ "$tip" = "COMMENT" ]; then
        continut="${continut#"${continut%%[![:space:]]*}"}"
        continut="${continut%"${continut##*[![:space:]]}"}"
        [ -z "$continut" ] && continue
        printeaza_indentare "$nivel"
        printf "%s\n" "$continut"
        continue
    fi

    continut="${continut#"${continut%%[![:space:]]*}"}"
    continut="${continut%"${continut##*[![:space:]]}"}"
    [ -z "$continut" ] && continue

    if [[ "$tip" == "TOKEN" && "$continut" == "</"* ]]; then
        nivel=$((nivel - 1))
        [ "$nivel" -lt 0 ] && nivel=0
    fi

    printeaza_indentare "$nivel"
    printf "%s\n" "$continut"

    if [[ "$tip" == "TOKEN" ]] && \
       [[ "$continut" == "<"* ]] && \
       [[ "$continut" != "</"* ]] && \
       [[ "$continut" != *"/>" ]] && \
       [[ "$continut" != "<!"* ]] && \
       [[ "$continut" != "<?"* ]]; then

        tag_fara_start="${continut#<}"
        nume_tag="${tag_fara_start%%[[:space:]>/]*}"
        nume_tag="${nume_tag,,}"

        if [[ "$VOID_TAGS" != *" $nume_tag "* ]]; then
            nivel=$((nivel + 1))
        fi
    fi

done
