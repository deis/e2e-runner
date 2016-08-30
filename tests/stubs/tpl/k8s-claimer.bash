generate() {
  cat <<EOF
    echo '$@'
EOF
}
