#!/usr/bin/env bash
# shellcheck shell=bash
set -uex -o pipefail

workDir=$(mktemp -d)
trap 'rm -rf "${workDir}"' EXIT

for hostname in $(echo "${HOSTS}" | jq -c -r 'keys.[]'); do
    host=$(echo "${HOSTS}" | jq -c ".\"${hostname}\"")
    target_user=$(echo "${host}" | jq -r '.target_user')
    target_port=$(echo "${host}" | jq -r '.target_port')
    healthcheck_script=$(echo "${host}" | jq -r '.healthcheck_script')
    ignore_systemd_errors=$(echo "${host}" | jq -r '.ignore_systemd_errors')
    system_closure=$(echo "${SYSTEM_CLOSURES}" | jq -r ".[\"${hostname}\"].result.out")

    sshOpts=(-p "${target_port}")
    sshOpts+=(-o UserKnownHostsFile=/dev/null)
    sshOpts+=(-o StrictHostKeyChecking=no)
    target="${target_user}@${hostname}"
    remote_profiles_before_switch=$(ssh -n "${sshOpts[@]}" "${target}" "ls /nix/var/nix/profiles")

    # 1. Copy closure
    # 2. Activate
    # Re-use nixos-anywhere for now
    "${MODULEPATH}"/../nixos-rebuild/deploy.sh "${system_closure}" "${target_user}" "${hostname}" "${target_port}" "${ignore_systemd_errors}"

    # 3. Run healthcheck
    set +e
    echo "${healthcheck_script}" | ssh "${sshOpts[@]}" "${target}" "bash -s"
    healthcheck_status="${PIPESTATUS[1]}"
    set -e
    if [[ ${healthcheck_status} != 0 ]]; then
        echo "healthcheck script failed with status ${healthcheck_status}"
        echo "rollbacking to previous NixOS system closure"
        remote_profiles=$(ssh -n "${sshOpts[@]}" "${target}" "ls /nix/var/nix/profiles")
        # Before rollbacking, we should make sure we actually jumped
        # onto a new system closure. We could end up in a situation
        # where the nixos-rebuild switch command did not produce any
        # new generation. In that case, a rollback would switch two
        # terraform generations ago.
        set +e
        diff <(echo "$remote_profiles_before_switch") <(echo "$remote_profiles")
        hasnewprofile=$?
        set -e
        if [[ ${hasnewprofile} == 0 ]]; then
            echo "Healthcheck failed, but the NixOS generation hasn't been updated by nixos-rebuild switch"
            exit 1
        fi
        # TODO: ssh -n "${sshOpts[@]}" "${target}" 'ln -s /nix/var/nix/profiles /tmp/i-screwed-up-my-rollback-script-plz-help-me'
        # TODO: add Numtide telemetry here.
        # NOTE: you could get your telemetry here as well, get in touch $$$

        # We already activated the new profile.
        # Let's list all the available profiles on the machine and
        # take the second to last one.
        # shellcheck disable=SC2010
        previous_system="/nix/var/nix/profiles/$(echo "${remote_profiles}" | grep -e "system-[0-9]*-link" | sort | tail -2 | head -1)"
        rollback_command="${previous_system}/bin/switch-to-configuration switch"
        if [[ $target_user != "root" ]]; then
            rollback_command="sudo bash -c '${rollback_command}'"
        fi
        # shellcheck disable=SC2029
        ssh "${sshOpts[@]}" "${target}" "${rollback_command}"
        echo "Rolled back the system"
        exit 1
    fi
    echo "healthcheck succeeded"
done
