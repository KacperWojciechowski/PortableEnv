#!/usr/bin/env bash
set -e

CONFIG_JSON=${1:-/tmp/config.json}

if [[ ! -f "$CONFIG_JSON" ]]; then
	echo "Error: Config file $CONFIG_JSON not found."
	exit 1
fi

echo "Updating package database..."
pacman -Syu --noconfirm

declare -A CUSTOM_PACKAGE_TYPE=(
	# pip
	[poetry]=pip [flake8]=pip [black]=pip [mypy]=pip [pytest]=pip [numpy]=pip 
	[pandas]=pip [requests]=pip [matplotlib]=pip [scipy]=pip [pyocd]=pip
	# gem
	[rspec]=gem [rubocop]=gem [minitest]=gem [rails]=gem [sinatra]=gem
	[nokogiri]=gem [json]=gem [CMock]=gem [Ceedling]=gem
	# cargo
	[serde]=cargo [tokio]=cargo [reqwest]=cargo [rand]=cargo [cargo-watch]=cargo
	[cargo-nextest]=cargo [cargo-tarpaulin]=cargo [cargo-audit]=cargo
	#rustup
	[clippy]=rustup [rustfmt]=rustup
)

PACMAN_PKGS=()
PIP_PKGS=()
GEM_PKGS=()
CARGO_PKGS=()
RUSTUP_PKGS=()

install_packages() {
	local type=$1
	shift
	local pkgs=("$@")
	[[ ${#pkgs[@]} -eq 0 ]] && return

	case "$type" in
		pacman)
			echo "Installing pacman packages: ${pkgs[*]}"
			pacman -S --needed --noconfirm "${pkgs[*]}"
			;;
		pip)
			echo "Installing pip packages: ${pkgs[*]}"
			pip install "${pkgs[*]}"
			;;
		gem)
			echo "Installing Ruby gems: ${pkgs[*]}"
			gem install "${pkgs[*]}"
			;;
		cargo)
			echo "Installing Rust crates: ${pkgs[*]}"
			for crate in "${pkgs[*]}"; do
				cargo install "$crate" || true
			done
			;;
		rustup)
			echo "Installing rustup packages: ${pkgs[*]}"
			for rustup_pkg in "${pkgs[*]}"; do
				rustup component add "$rustup_pkg" || true
			done
			;;
	esac
}

mapfile -t enabled_presets < <(jq -r '.Presets | to_entries[] | select(.value==true) | .key' "$CONFIG_JSON")

for preset in "${enabled_presets[@]}"; do
	preset_file="/tmp/presets/$(echo "$preset" | tr '[:upper:]' '[:lower:]' | tr ' /' '_' | tr '+' 'p').json"
	if [[ ! -f "$preset_file" ]]; then
		echo "Warning: Preset file $preset_file not found, skipping."
		continue
	fi

	mapfile -t packages < <(
		jq -r '
		if (.packages | type) == "array" then
			.packages[]
		else
			.packages | to_entries[] | select(.value==true) | .key
		end
		' "$preset_file" | sed '/^\s*$/d')
	if [[ ${#packages[@]} -eq 0 ]]; then
		echo "No packages found in $preset_file, skipping."
		continue
	fi
	for pkg in "${packages[@]}"; do
		[[ -z "$pkg" ]] && continue
		type=${CUSTOM_PACKAGE_TYPE[$pkg]:-pacman}
		case "$type" in
			pacman) PACMAN_PKGS+=("$pkg") ;;
			pip) PIP_PKGS+=("$pkg") ;;
			gem) GEM_PKGS+=("$pkg") ;;
			cargo) CARGO_PKGS+=("$pkg") ;;
			rustup) RUSTUP_PKGS+=("$pkg") ;;
		esac
	done
	echo "Packages to install from preset $preset_file: ${packages[*]}"
done

[[ ${#PIP_PKGS[@]} -gt 0 ]] && pacman -S --needed --noconfirm python-pip
[[ ${#GEM_PKGS[@]} -gt 0 ]] && pacman -S --needed --noconfirm ruby
[[ ${#CARGO_PKGS[@]} -gt 0 ]] && pacman -S --needed --noconfirm rustup && rustup default stable
[[ ${#RUSTUP_PKGS[@]} -gt 0 ]] && pacman -S --needed --noconfirm rustup && rustup default stable

install_packages pacman "${PACMAN_PKGS[@]}"
install_packages pip "${PIP_PKGS[@]}"
install_packages gem "${GEM_PKGS[@]}"
install_packages cargo "${CARGO_PKGS[@]}"
install_packages rustup "${RUSTUP_PKGS[@]}"

echo "All requested packages installed successfully"
pacman -Scc --noconfirm
