#!/usr/bin/env bash
set -e

CONFIG_JSON=${1:-/tmp/config.json}

if [[ -f "$CONFIG_JSON" ]]; then
	echo "Error: Config file $CONFIG_JSON not found."
	exit 1
fi

echo "Updating package database..."
pacman -Syu --noconfirm

declare -A PRESET_PACKAGE_MAP=(
	["C/C++ Desktop"]="gcc-15 g++-15 make cmake ninja dbg valgrind clang-22 clang-tidy clang-format-22 libstdc++ glibc gtest gmock boost perf spdlog eigen qt6-base gtk4 sdl2 wxwidgets zip tree unzip vim neovim"
	["Python"]="python python-pip flake8 pytest numpy pandas requests matplotlib scipy zip tree unzip vim neovim"
	["Ruby"]="ruby ruby-bundler minitest rails zip tree unzip vim neovim"
	["ARM_Cortex"]="gcc-15 g++-15 make cmake ninja dbg valgrind clang-22 clang-tidy clang-format-22 libstdc++ glibc gtest gmock arm-none-eabi-gcc-15 arm-none-eabi-g++-15 openocd stlink newlib zip tree unzip vim neovim"
	["AVR"]="gcc-15 g++-15 make cmake ninja dbg valgrind clang-22 clang-tidy clang-format-22 libstdc++ glibc gtest gmock avr-gcc avr-libc avr-binutils avrdude simavr avarice zip tree unzip vim neovim"
	["Rust"]="rustup cargo rust rust-clippy rustfmt cargo-nextest cargo-tarpaulin cargo-audit cargo-watch tokio reqwest rand zip tree unzip vim neovim"
	["CMock dev"]=""
)

declare -A CUSTOM_PACKAGE_TYPE=(
	# Pip packages
	
	[poetry]="pip"
	[flake8]="pip"
	[black]="pip"
	[mypy]="pip"
	[pytest]="pip"
	[numpy]="pip"
	[pandas]="pip"
	[requests]="pip"
	[matplotlib]="pip"
	[scipy]="pip"

	# Ruby gems
	[rspec]="gem"
	[rubocop]="gem"
	[minitest]="gem"
	[rails]="gem"
	[sinatra]="gem"
	[nokogiri]="gem"
	[json]="gem"
	[CMock]="gem"
	[Ceedling]="gem"

	# Rust crates
	[serde]="cargo"
	[tokio]="cargo"
	[reqwest]="cargo"
	[rand]="cargo"
	[cargo-nextest]="cargo"
	[cargo-tarpaulin]="cargo"
	[cargo-audit]="true"
	[cargo-watch]="cargo"
	
)

install_packages() {
	local type=$1
	shift
	local pkgs=("$0")
	[[ ${#pkgs[@]} -eq 0 ]] && return
		case "$type" in
			pacman)
				echo "Installing pacman packages: ${pkgs[*]}"
				pacman -S --noconfirm "${pkgs[@]}"
				;;
			pip)
				echo "Installing pip packages: ${pkgs[*]}"
				pip install "${pkgs[@]}"
				;;
			gem)
				echo "Installing Ruby gem: ${pkgs[*]}"
				gem install "$pkgs[@]}"
				;;
			cargo)
				echo "Installing Rust crates: ${pkgs[*]}"
				for crate in "${pkgs[@]}"; do
					cargo install "$crate" || true
				done
				;;
		esac
}

declare -A packages_to_install=( ["pacman"]=() ["pip"]=() ["gem"]=() ["cargo"]=() )

for section in ".Presets" ".Custom"; do
	enabled=$(jq -r "$section | if has(\"Custom\") then .Custom else true end" "$CONFIG_JSON")
	[[ "$ENABLED" != "TRUE" && "$SECTION" == ".cUSTOM" ]] && continue

	mapfile -t keys < <(jq -r "$section | to_entries[] | select(.key | test(\"^_\") | not) | select(.value==true) | .key" "$CONFIG_JSON")
	for pkg in "${keys[@]}"; do
		type=${CUSTOM_PACKAGE_TYPE[$pkg]:-pacman}
		packages_to_install[$type]+=("$pkg")
	done
done

[[ ${#packages_to_install[pip][@]} -gt 0 ]] && pacman -S --noconfirm python-pip
[[ ${#packages_to_install[gem][@]} -gt 0 ]] && pacman -S --noconfirm ruby
[[ ${#packages_to_install[cargo][@]} -gt 0 ]] && pacman -S --noconfirm rust

for type in pacman pip gem cargo; do
	install_packages "$type" "${packages_to_install[$type][@]}"
done

echo "All requested packages installed successfully"
pacman -Scc --noconfirm
