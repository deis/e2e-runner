#!/usr/bin/env bats

setup() {
  . "${BATS_TEST_DIRNAME}/../scripts/functions.sh"
}

@test "check-vars : none given" {
  components=()
  run check-vars "${components[@]}"
  echo "${output}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

@test "check-vars : none to export" {
  components=("FOO_COMPONENT" "BAR_COMPONENT")
  run check-vars "${components[@]}"
  echo "${output}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

@test "check-vars : some to export" {
  components=("FOO_COMPONENT" "BAR_COMPONENT")
  export FOO_COMPONENT_SHA="1234abcd"
  run check-vars "${components[@]}"
  echo "${output}"
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}" -eq 1 ]
  [ "${output}" == "Setting ${components[0]}_GIT_TAG to git-${FOO_COMPONENT_SHA:0:7}" ]
}

@test "check-vars : all to export" {
  components=("FOO_COMPONENT" "BAR_COMPONENT")
  export FOO_COMPONENT_SHA="1234abcd"
  export BAR_COMPONENT_SHA="5678efgh"
  run check-vars "${components[@]}"
  echo "${output}"
  [ "${status}" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
  [ "${lines[0]}" == "Setting ${components[0]}_GIT_TAG to git-${FOO_COMPONENT_SHA:0:7}" ]
  [ "${lines[1]}" == "Setting ${components[1]}_GIT_TAG to git-${BAR_COMPONENT_SHA:0:7}" ]
}
