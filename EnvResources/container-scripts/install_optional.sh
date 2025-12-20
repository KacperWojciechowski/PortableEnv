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

declare -A PRESET_PACKAGE_MAP=(
	["C/C++ Desktop"]="gcc g++ make cmake ninja dbg valgrind clang \
	       glibc gtest boost perf spdlog eigen qt6-base gtk4 sdl2 wxwidgets"
	["Python"]="python python-pip flake8 pytest numpy pandas requests \
	       matplotlib scipy"
	["Ruby"]="ruby ruby-bundler minitest rails"
	["ARM_Cortex"]="gcc g++ make cmake ninja dbg valgrind clang glibc gtest \
	       arm-none-eabi-gcc openocd stlink ruby Ceedling"
	["AVR"]="gcc g++ make cmake ninja dbg valgrind clang \
	       glibc gtest avr-gcc avr-libc \
	       avr-binutils avrdude simavr avarice"
	["Rust"]="rustup clippy rustfmt cargo-nextest cargo-tarpaulin \
	       cargo-audit cargo-watch tokio reqwest rand"
	["CMock dev"]=""
)

PACMAN_PKGS=()
PIP_PKGS=()
GEM_PKGS=()
CARGO_PKGS=()
RUSTUP_PKGS=()

add_pkg() {
    local pkg="$1"
    local type="${CUSTOM_PACKAGE_TYPE[$pkg]:-pacman}"

    case "$type" in
	    pacman) PACMAN_PKGS+=("$pkg") ;;
	    pip) PIP_PKGS+=("$pkg") ;;
	    gem) GEM_PKGS+=("$pkg") ;;
	    cargo) CARGO_PKGS+=("$pkg") ;;
	    rustup) RUSTUP_PKGS+=("$pkg") ;;
    esac
}

echo "PRocessing presets..."

mapfile -t ENABLED_PRESETS < <(
	jq -r '.Presets | to_entries[] | select(.value==true) | .key' "$CONFIG_JSON"
)

for preset in "${ENABLED_PRESETS[@]}"; do
	[[ "$preset" == "Custom" ]] && continue

	pkgs="${PRESET_PACKAGE_MAP[$preset]}"
	if [[ -z "$pkgs" ]]; then
		echo "Warning: preset '$preset' has no package mapping"
		continue
	fi

	for pkg in $pkgs; do
		add_pkg "$pkg"
	done
done

CUSTOM_ENABLED=$(jq -r '.Presets.Custom // false' "$CONFIG_JSON")

if [[ "$CUSTOM_ENABLED" == "true" ]]; then
	echo "Processing custom packages..."

	mapfile -t CUSTOM_KEYS < <(
		jq -r '.Custom | to_entries[] |
			select(.key | test("^_") | not) |
			select(.value==true) |
			.key' "$CONFIG_JSON"
	)

	for pkg in "${CUSTOM_KEYS[@]}"; do
		add_pkg "$pkg"
	done
fi

[[ ${#PIP_PKGS[@]} -gt 0 ]] && pacman -S --noconfirm python python-pip
[[ ${#GEM_PKGS[@]} -gt 0 ]] && pacman -S --noconfirm ruby
[[ ${#CARGO_PKGS[@]} -gt 0 ]] && pacman -S --noconfirm rust
[[ ${#RUSTUP_PKGS[@]} -gt 0 ]] && pacman -S --noconfirm rustup && rustup default stable

install_packages() {
	local type=$1; shift
	local pkgs=("$@")
	[[ ${#pkgs[@]} -eq 0 ]] && return

	echo "Installing $type packages: ${pkgs[*]}"

	case "$type" in
		pacman) pacman -S --needed --noconfirm "${pkgs[@]}" ;;
		pip) pip install "${pkgs[@]}" ;;
		gem) gem install "${pkgs[@]}" ;;
		cargo)
			for crate in "${pkgs[@]}"; do
				cargo install "$crate" || true
			done
			;;
		rustup)
			rustup component add "${pkgs[@]}" ;;
	esac
}

install_packages pacman "${PACMAN_PKGS[@]}"
install_packages pip "${PIP_PKGS[@]}"
install_packages gem "${GEM_PKGS[@]}"
install_packages cargo "${CARGO_PKGS[@]}"
install_packages rustup "${CARGO_PKGS[@]}"

echo "All requested packages installed successfully"
pacman -Scc --noconfirm
