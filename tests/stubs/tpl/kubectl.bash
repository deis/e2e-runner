generate() {
  NS_OUTPUT=${1}

  cat <<EOF
    case "\${2}" in
      ("ns") echo '"${NS_OUTPUT:-deis}"' ;;
    esac
EOF
}
