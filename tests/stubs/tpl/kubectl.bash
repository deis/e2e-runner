generate() {
  PODS_OUTPUT=${1}
  NS_OUTPUT=${2}

  cat <<EOF
    case "\${2}" in
      ("pods") echo '"${PODS_OUTPUT:-deis-controller}"' ;;
      ("ns") echo '"${NS_OUTPUT:-deis}"' ;;
    esac
EOF
}
