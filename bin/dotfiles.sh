#!/usr/bin/env bash

declare -ga ignore_regex=(
    "^\.git$" "^\.gitignore" "^README\.md$" "^\.svn.*" "\^.cvs.*" "\..*~swp$" ".*\.bak$"
    "^LICENSE$" "\.swp$" "^\.codeclimate\.yml$" "^\.travis\.yml$"
  )

declare -gA df_sigil_map=(
    ["%"]="distrib-release distrib-codename codename distrib system-release system distrib-family"
    ["@"]="hostname-full hostname-short domain"
  )

declare -gA df_weight_map=(
    ["hostname-full"]=20
    ["hostname-short"]=8
    ["distrib-release"]=5
    ["distrib-codename"]=5
    ["codename"]=3
    ["distrib"]=3
    ["distrib-family"]=2
    ["domain"]=1
    ["system-release"]=1
    ["system"]=1
  )

populate_identity_map () {
  declare -gA df_ident=()
  declare -a illegal_chars=(, + ${!df_sigil_map[@]})

  # See https://en.wikipedia.org/wiki/Uname for examples.
  df_ident["system"]="$(uname -s)"
  df_ident["system-release"]="${df_ident[system]}-$(uname -r)"

  if [[ -r "/etc/lsb-release" ]] ; then
    source "/etc/lsb-release"
    df_ident["distrib-release"]="${DISTRIB_ID}-${DISTRIB_RELEASE}"
    df_ident["distrib-codename"]="${DISTRIB_ID}-${DISTRIB_CODENAME}"
    df_ident["distrib"]="${DISTRIB_ID}"
    df_ident["codename"]="${DISTRIB_CODENAME}"
  fi

  [[ -e "/etc/debian-release" ]] && df_ident["distrib-family"]="debian"
  [[ -e "/etc/redhat-release" ]] && df_ident["distrib-family"]="redhat"
  [[ "${df_ident["distrib"],,}" = "ubuntu" ]] && df_ident["distrib-family"]="debian"
  [[ "${df_ident["distrib"],,}" = "centos" ]] && df_ident["distrib-family"]="redhat"

  df_ident["hostname-full"]="$(hostname -f)"
  df_ident["domain"]="${df_ident[hostname-full]#*.}"
  df_ident["hostname-short"]="$(hostname -s)"

  declare key
  for key in "${!df_ident[@]}" ; do
    [[ -n "$key" ]] || continue
    df_ident[$key]="${df_ident[$key],,}"
    df_ident[$key]="${df_ident[$key]// /-}"
    declare illegal
    for illegal in "${illegal_chars[@]}" ; do
      [[ -n "$illegal" ]] || continue
      df_ident[$key]="${df_ident[$key]//${illegal}/}"
    done
  done
}

populate_identity_map

identity_sigil () {
  declare ident="$1"
  declare sigil
  for sigil in ${!df_sigil_map[@]} ; do
    [[ -n "$sigil" ]] || continue
    declare sigil_ident
    for sigil_ident in ${df_sigil_map[$sigil]} ; do
      if [[ "$ident" = "$sigil_ident" ]] ; then
        echo -n "$sigil"
        return
      fi
    done
  done
}

weight_of_file () {
  declare file="$1"
  declare -i weight=0
  declare -i identity_count=0
  declare ident
  for ident in $(file_identities "$file") ; do      
    identity_count+=1
    declare -i ident_weight="$(weight_of_identity "$ident")"
    if [[ $ident_weight -gt $weight ]] ; then
      weight=$ident_weight
    fi
  done
  if [[ $identity_count -ge 1 && $weight -eq 0 ]] ; then
    weight=-1
  fi
  echo -n "$weight"
}

weight_of_identity () {
  declare ident="$1"
  declare -i weight=0
  for part in ${ident//+/ } ; do
    declare sigil="${part:0:1}"
    part="${part:1}"
    declare key
    for key in ${df_sigil_map[$sigil]:-} ; do
      if [[ "${part,,}" = "${df_ident[$key]:-}" ]] ; then
        weight+=${df_weight_map[$key]:-0}
      fi
    done
  done
  echo -n "$weight"
}

file_identities () {
  declare file="$1"
  if [[ ! "$file" =~ .+~.+ ]] ; then
    return
  fi
  file="${1#*~}"
  file="${file// /}"
  declare ident
  for ident in ${file//,/ } ; do
    echo "$ident"
  done
}

available_identities () {
  declare ident
  for ident in "${!df_ident[@]}" ; do
    printf "%s%s\n" "$(identity_sigil "$ident")" "${df_ident[$ident]}"
  done
}

best_file () {
  declare normalised_file="${1:-}"
  [[ -z "$normalised_file" ]] && return 64
  declare -i best_weight=-2
  declare best
  declare file
  for file in "$normalised_file" "$normalised_file"~* ; do
    [[ ! -e "$file" ]] && continue
    declare -i weight="$(weight_of_file "$file")"
    if [[ -z "${best:-}" || $weight -gt $best_weight ]] ; then
      best="$file"
      best_weight=$weight
    fi
  done
  if [[ $best_weight -ge 0 ]] && [[ -n "${best:-}" ]] ; then
    echo "$best"
  fi
}

normalised_files () {
  declare path="${1:-}"
  [[ -z "$path" || ! -e "$path" ]] && return 64
  declare -A files=()
  for file in "${path%/}"/* ; do
    files["${file%%~*}"]=1
  done
  for file in "${!files[@]}" ; do
    declare -i skip=0
    declare regex
    for regex in "${ignore_regex[@]}" ; do
      if [[ "${file##*/}" =~ $regex ]] ; then
        skip=1 && break
      fi
    done
    [[ $skip -eq 0 ]] && echo "$file"
  done
}

file_weights () {
  declare path="${1:-}"
  [[ -z "$path" || ! -e "$path" ]] && return 64
  declare file
  for file in "${path%/}"/* ; do
    printf "%d %s\n" "$(weight_of_file "$file")" "$file"
  done
}

create_self_symlinks () {
  declare prefix="dotfiles-"
  declare link
  for link in available-identities file-weights symlink-files \
              normalised-files best-file file-identities ; do
    ln -v -f -s ${_df_ln_args:-} "${BASH_SOURCE[0]##*/}" "${BASH_SOURCE[0]%/*}/${prefix}$link"
  done
}

symlink_files () {
  if [[ $# -eq 0 ]] ; then
    declare path="${DOTFILES_SYMLINK_SOURCE:-}"
    declare target="${DOTFILES_SYMLINK_TARGET:-}"
  elif [[ $# -eq 2 ]] ; then
    declare path="$(readlink -f "${1:-}")"
    declare target="$(readlink -f "${2:-}")"
  else
    return 64
  fi
  if [[ -z "$path" || ! -e "$path" || -z "$target" \
                   || "$target" =~ ^$path(/|$) ]] ; then
    return 64
  fi

  declare file
  while read -r file ; do
    if [[ -d "$file" ]] && ! compgen -G "$file~*" >/dev/null ; then
      symlink_files "$file" "${target%/}/${file##*/}"
    else
      declare link_name="${target%/}/${file##*/}"
      declare link_target="$(best_file "$file")"

      [[ -n "$link_target" ]] || continue
      if [[ ! -d "$(dirname "$link_name")" ]] ; then
        mkdir -p "$(dirname "$link_name")" 
      fi

      declare relative_link_target="$(relative_file "$link_name" "$link_target")"
      unset force
      if [[ -h "$link_name" ]] ; then
        declare force=1
      fi
      ln ${force:+-f} -v -s ${_df_ln_args:-} "$relative_link_target" "$link_name"
    fi
  done < <(normalised_files "$path")
}

relative_file () {
  declare src="${1:-}"
  declare tgt="${2:-}"
  [[ -z "$src" || -z "$tgt" ]] && return 64
  declare rel_path="$(relative_path "$(dirname "$src")" "$(dirname "$tgt")")"
  rel_path="${rel_path%/}"
  echo "${rel_path:+$rel_path/}${tgt##*/}"
}

relative_path () {
  # http://stackoverflow.com/questions/2564634/convert-absolute-path-into-relative-path-given-a-current-directory-using-bash
  declare src="$(readlink -m "${1:-}")"
  declare tgt="$(readlink -m "${2:-}")"
  [[ -z "$src" || -z "$tgt" ]] && return 64

  declare common_part="$src" # for now
  declare result="" # for now
  while [[ "${tgt#$common_part}" == "$tgt" ]] ; do
    # No match, means that candidate common part is not correct.
    # Go up one level (reduce common part).
    common_part="${common_part%/*}"
    [[ -z "$common_part" ]] && common_part="/"
    # Record that we went back, with correct / handling.
    if [[ -z "$result" ]]; then
      result=".."
    else
      result="../$result"
    fi
  done

  if [[ $common_part == "/" ]]; then
    # Special case for root (no common path).
    result="$result/"
  fi

  # Since we now have identified the common part, compute the non-common part.
  declare forward_part="${tgt#$common_part}"

  # Now stick all parts together.
  if [[ -n "$result" ]] && [[ -n "$forward_part" ]]; then
    result="$result$forward_part"
  elif [[ -n "$forward_part" ]]; then
    # Extra slash removal.
    result="${forward_part:1}"
  fi

  echo "$result"
}

# TODO(nicolaw): Like the other comment below, it would be better to test for
#                the presence of standard GNU core utils instead of checking
#                the output of uname!
unset _df_ln_args
if [[ "${df_ident[system]}" = "linux" ]] ; then
  declare -r _df_ln_args="-T"
elif [[ "${df_ident[system]}" = "darwin" ]] ; then
  declare -r _df_ln_args="-h"
fi

if [[ "${df_ident[system]}" = "darwin" ]] ; then
  # TODO(nicolaw): Only implement our own readlink function on OS X if there
  #                is not a copy of GNU readlink installed. (Some people might
  #                have installed GNU readlink with Brew).
  #                In fact, we should do better here and test for GNU readlink
  #                explicitly so that this work around is present on things
  #                other than just OS X, (like BSD etc).
  readlink () {
    declare -A args=()
    declare arg
    for arg in "$@" ; do
      if [[ "$arg" = "--" ]]; then
        shift
        break
      elif [[ "${arg:0:1}" = "-" ]] ; then
        shift
        args["${arg:1}"]=1
      fi
    done
    if [[ -z "$1" ]] ; then
      return
    elif [[ -h "$1" ]] ; then
      command readlink "$1"
    elif [[ ! -e "$1" ]] && [[ -n "${args[m]:-}" ]] ; then
      echo "$1"
    #elif [[ -e "$1" ]] ; then
    else
      echo "$1"
    fi
  }
fi

if [[ "$(readlink -f -- "${BASH_SOURCE[0]}")" = "$(readlink -f -- "$0")" ]] ; then
  main () {
    if [[ $# -eq 1 && "$1" = "install" ]] ; then
      create_self_symlinks
      return $?
    fi

    declare syntax
    declare personality="${0##*/}"
    declare -i rc=0
    {
      case "${personality,,}" in
        *available*) available_identities | sort -u ;;
        *file-identities) file_identities "$@" ;;
        *file-weight*) file_weights "$@" ;;
        *best-file) best_file "$@" ;;
        *normali[sz]ed-file*) normalised_files "$@" ;;
        *symlink-file*)
          syntax="<src_dotfiles_path> <links_path>"
          symlink_files "$@" ;;
      esac
    } || rc=$?

    if [[ $rc -eq 64 ]] ; then
      >&2 echo "Syntax: ${0##*/} ${syntax:-<path>}"
    fi
    return $rc
  }

  set -euo pipefail
  shopt -s nullglob dotglob
  #trap caller ERR
  main "$@"
  exit $?
fi

__relative_unit_tests () {
  while read -r src tgt result ; do
    eval "assert 'relative_path \"$src\" \"$tgt\"' '$result'"
    printf '%-40s = "%s"\n' \
      "$(printf 'relative_path "%s" "%s"' "$src" "$tgt")" \
      "$(eval "relative_path \"$src\" \"$tgt\" '$result'")"
  done <<EOF
/A/B/C /A         ../..
/A/B/C /A/B       ..
/A/B/C /A/B/C
/A/B/C /A/B/C/D   D
/A/B/C /A/B/C/D/E D/E
/A/B/C /A/B/D     ../D
/A/B/C /A/B/D/E   ../D/E
/A/B/C /A/D       ../../D
/A/B/C /A/D/E     ../../D/E
/A/B/C /D/E/F     ../../../D/E/F
EOF

  while read -r src tgt result ; do
    eval "assert 'relative_file \"$src\" \"$tgt\"' '$result'"
    printf '%-40s = "%s"\n' \
      "$(printf 'relative_file "%s" "%s"' "$src" "$tgt")" \
      "$(eval "relative_file \"$src\" \"$tgt\" '$result'")"
  done <<EOF
/A/B/C /A         ../../A
/A/B/C /A/B       ../B
/A/B/C /A/B/C     C
/A/B/C /A/B/C/D   C/D
/A/B/C /A/B/C/D/E C/D/E
/A/B/C /A/B/D     D
/A/B/C /A/B/D/E   D/E
/A/B/C /A/D       ../D
/A/B/C /A/D/E     ../D/E
/A/B/C /D/E/F     ../../D/E/F
EOF

  assert_end "${BASH_SOURCE[0]##*/}"
}

