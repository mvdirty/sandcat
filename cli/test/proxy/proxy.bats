#!/usr/bin/env bats

setup() {
	load test_helper

	# shellcheck source=../../libexec/proxy/proxy
	source "$SCT_LIBEXECDIR/proxy/proxy"

	mkdir -p "$BATS_TEST_TMPDIR/.devcontainer"
	COMPOSE_FILE="$BATS_TEST_TMPDIR/.devcontainer/compose-all.yml"
	touch "$COMPOSE_FILE"
}

teardown() {
	unstub_all
}

@test "proxy attaches in TUI mode" {
	stub docker \
		"compose -f $COMPOSE_FILE config --format json : echo '{\"services\":{\"mitmproxy\":{\"stdin_open\":true}}}'" \
		"compose -f $COMPOSE_FILE ps -q mitmproxy : echo container-id" \
		"attach container-id : :"

	cd "$BATS_TEST_TMPDIR"
	run proxy
	assert_success
	assert_output --partial "Attaching to mitmproxy console"
}

@test "proxy shows URL in web mode" {
	stub docker \
		"compose -f $COMPOSE_FILE config --format json : echo '{\"services\":{\"mitmproxy\":{}}}'" \
		"compose -f $COMPOSE_FILE port mitmproxy 8081 : echo 0.0.0.0:12345"

	cd "$BATS_TEST_TMPDIR"
	run proxy
	assert_success
	assert_output --partial "http://0.0.0.0:12345"
}

@test "proxy fails when not running in TUI mode" {
	stub docker \
		"compose -f $COMPOSE_FILE config --format json : echo '{\"services\":{\"mitmproxy\":{\"stdin_open\":true}}}'" \
		"compose -f $COMPOSE_FILE ps -q mitmproxy : echo ''"

	cd "$BATS_TEST_TMPDIR"
	run proxy
	assert_failure
	assert_output --partial "not running"
}

@test "proxy fails when not running in web mode" {
	stub docker \
		"compose -f $COMPOSE_FILE config --format json : echo '{\"services\":{\"mitmproxy\":{}}}'" \
		"compose -f $COMPOSE_FILE port mitmproxy 8081 : exit 1"

	cd "$BATS_TEST_TMPDIR"
	run proxy
	assert_failure
	assert_output --partial "not running"
}
