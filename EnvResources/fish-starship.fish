if status --is-interactive
	starship init fish | source
end

set -gx STARSHIP_LOG error
set -gx EDITOR nvim
