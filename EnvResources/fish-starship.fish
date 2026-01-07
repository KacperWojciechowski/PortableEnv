if status --is-interactive
	starship init fish | source
end

set -gx STARSHIP_LOG error
set -gx EDITOR nvim

set -gx LANG pl_PL.UTF-8
set -gx LC_ALL pl_PL.UTF-8
