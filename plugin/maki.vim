if exists('g:maki_loaded') | finish | else | let g:maki_loaded = 1 | endif

" Path configuration {{{
let g:maki_root = expand(get(g:, 'maki_root', '$HOME/Wiki'))
let g:maki_export = expand(get(g:, 'maki_export', '$HOME/Wiki/export'))
let g:maki_auto_export = expand(get(g:, 'maki_auto_export', 0))
" }}}
" Commands {{{
command! -nargs=? MakiGo call maki#nav#goto_page(<q-args>)
" }}}
" <Plug> definitions {{{
nnoremap <Plug>maki-index :MakiGo<CR>
" }}}
" Key mappings {{{
nmap <silent> <Leader>w <Plug>maki-index
" }}}
