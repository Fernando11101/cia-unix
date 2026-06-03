#!/bin/bash

run_tool() {
    local tool="$1"
    shift

    ./"$tool" "$@" 2>&1
    local status=${PIPESTATUS[0]}

    if [ $status -ne 0 ]; then
        echo "$tool failed with exit code $status"
        exit 1
    fi
}

check_decrypt() {
    local name="$1"
    local ext="$2"

    if [ -f "${name}-decrypted.${ext}" ]; then
        echo "Decryption completed"
    else
        echo "Decryption failed"
    fi
}

remove_cache() {
    echo "Removing cache..."

    rm -f *.ncch

    for cia in *"(Game)-decrypted.cia"; do
        [ -e "$cia" ] || continue

        cci="${cia%.cia}.cci"

        if [ -f "$cci" ]; then
            rm -f "$cia"
        fi
    done
}

gen_args() {
    local name="$1"
    local count="$2"

    local args=()

    for ((i=0;i<count;i++)); do
        if [ -f "${name}.${i}.ncch" ]; then
            args+=("-i" "${name}.${i}.ncch:${i}:${i}")
        fi
    done

    printf '%s\n' "${args[@]}"
}

shopt -s nullglob

cias=( *.cia )
threeds=( *.3ds )

if [ ${#cias[@]} -eq 0 ] && [ ${#threeds[@]} -eq 0 ]; then
    echo "No CIA/3DS roms were found."
    exit 1
fi

for ds in *.3ds; do
    [ -e "$ds" ] || continue

    [[ "$ds" == *decrypted* ]] && continue

    dsn="${ds%.3ds}"

    echo "Decrypting: $ds"

    run_tool ctrdecrypt "$ds"

    args=(-f cci -ignoresign -target p -o "${dsn}-decrypted.3ds")

    for ncch in "${dsn}".*.ncch; do
        [ -e "$ncch" ] || continue

        case "$ncch" in
            "${dsn}.Main.ncch") i=0 ;;
            "${dsn}.Manual.ncch") i=1 ;;
            "${dsn}.DownloadPlay.ncch") i=2 ;;
            "${dsn}.Partition4.ncch") i=3 ;;
            "${dsn}.Partition5.ncch") i=4 ;;
            "${dsn}.Partition6.ncch") i=5 ;;
            "${dsn}.N3DSUpdateData.ncch") i=6 ;;
            "${dsn}.UpdateData.ncch") i=7 ;;
            *) continue ;;
        esac

        args+=(-i "${ncch}:${i}:${i}")
    done

    echo "Building decrypted 3DS..."

    run_tool makerom "${args[@]}"

    check_decrypt "${dsn}" 3ds

    remove_cache
done

for cia in *.cia; do
    [ -e "$cia" ] || continue

    [[ "$cia" == *decrypted* ]] && continue

    cutn="${cia%.cia}"

    echo "Decrypting: $cia"

    content=$(run_tool ctrtool --seeddb=seeddb.bin "$cia")

    titlever=$(echo "$content" | sed -n 's/.*TitleVersion:.*(\([0-9]\+\)).*/\1/p')

    if echo "$content" | grep -qiE '0004000e'; then
        echo "CIA Type: Update"

        run_tool ctrdecrypt "$cia"

        args=(-f cia -ignoresign -target p \
              -ver "$titlever" \
              -o "${cutn} (Update)-decrypted.cia")

        count=$(find . -maxdepth 1 -name "${cutn}.*.ncch" | wc -l)

        while read -r line; do
            args+=("$line")
        done < <(gen_args "$cutn" "$count")

        run_tool makerom "${args[@]}"

        check_decrypt "${cutn} (Update)" cia

    elif echo "$content" | grep -qiE '0004008c'; then
        echo "CIA Type: DLC"

        run_tool ctrdecrypt "$cia"

        args=(-f cia -dlc -ignoresign -target p \
              -ver "$titlever" \
              -o "${cutn} (DLC)-decrypted.cia")

        count=$(find . -maxdepth 1 -name "${cutn}.*.ncch" | wc -l)

        while read -r line; do
            args+=("$line")
        done < <(gen_args "$cutn" "$count")

        run_tool makerom "${args[@]}"

        check_decrypt "${cutn} (DLC)" cia

    elif echo "$content" | grep -qE '00040000'; then
        echo "CIA Type: Game"

        run_tool ctrdecrypt "$cia"

        args=(-f cia -ignoresign -target p \
              -ver "$titlever" \
              -o "${cutn} (Game)-decrypted.cia")

        count=$(find . -maxdepth 1 -name "${cutn}.*.ncch" | wc -l)

        while read -r line; do
            args+=("$line")
        done < <(gen_args "$cutn" "$count")

        run_tool makerom "${args[@]}"

        check_decrypt "${cutn} (Game)" cia

        read -rp "Convert CIA to CCI? (y/n): " answer

        if [[ "$answer" =~ ^[Yy]$ ]]; then
            echo "Building decrypted CCI..."

            run_tool makerom \
                -ciatocci "${cutn} (Game)-decrypted.cia" \
                -o "${cutn} (Game)-decrypted.cci"

            check_decrypt "$cutn (Game)" cci
        fi
    else
        echo "Unsupported CIA"
    fi

remove_cache

done

read -rp "Press Enter to exit"
