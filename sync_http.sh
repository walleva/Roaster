#!/bin/bash

set -e

export src="https://cdn.gea.esac.esa.int/Gaia/gdr1/tgas_source"
export dst="/media/Matrix/Data/ESA/Gaia/gdr1/tgas_source"
export conn=128

export meta=$(mktemp -d)
echo "Use \"$meta\" for metadata."

echo '/' > "$meta/dirs.txt"
truncate -s0 "$meta/files.txt"

while [ $(cat "$meta/dirs.txt" | wc -l) -gt 0 ]; do
    rm -rf "$meta/"{children,dirs,files}".d"
    mkdir -p "$meta/"{children,dirs,files}".d"

    parallel -j"$conn" --line-buffer --bar 'bash -c '"'"'
        meta="'"$meta"'"
        esc="$(sed "s/\([\/\.]\)/\\\\\1/g" <<< "{}")"
        curl -sSL "'"$src"'{}" | sed -n "s/.*[[:space:]]href[[:space:]]*=[[:space:]]*\"\([^\.\"][^\"]*\).*/\1/p" | sed "s/^/$esc/" >> "$meta/children.d/{%}.txt"
    '"'" :::: "$meta/dirs.txt"

    parallel -j"$(nproc)" --line-buffer --bar 'bash -c '"'"'
        meta="'"$meta"'"
        cat "{}" | sed -n "/[^\/]$/p" >> "$meta/files.d/{%}.txt"
        cat "{}" | sed -n "/[\/]$/p" >> "$meta/dirs.d/{%}.txt"
    '"'" ::: $(ls "$meta/children.d/"*.txt)

    rm -f "$meta/dirs.txt"
    parallel -j0 --line-buffer --bar 'bash -c '"'"'
        meta="'"$meta"'"
        cat "$meta/{}.d/"*.txt >> "$meta/{}.txt"
        rm -rf "$meta/{}.d"
    '"'" ::: dirs files
done

rm -rf "$meta/"{children,dirs,files}".d" "$meta/"{children,dirs}".txt"
echo "File list is ready in \"$meta/files.txt\"."

export ROUTE='10.0.0.$([ $(expr $RANDOM % 11) -lt 7 ] && echo 12 || echo 11)'
parallel -j"$conn" --line-buffer --bar 'bash -c '"'"'
    mkdir -p "'"$dst"'/{}"
    cd $_
    wget -cq --bind-address='$ROUTE' "'"$src"'{}"
'"'" ::: "$meta/files.txt"

rm -rf "$meta"
