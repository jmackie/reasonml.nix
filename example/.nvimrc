" WIP
"
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'nix': ['Nixfmt'],
\   'ocaml': ['ocamlformat'],
\   'reason': ['refmt'],
\   'javascript': ['prettier'],
\   'json': ['prettier'],
\}

let g:LanguageClient_serverCommands = {
\ 'reason': ['reason-language-server'],
\}
