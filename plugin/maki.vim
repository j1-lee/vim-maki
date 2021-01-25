if exists('g:maki_loaded') | finish | else | let g:maki_loaded = 1 | endif

" Path configuration {{{
let g:maki_root = expand(get(g:, 'maki_root', '~/Wiki'))
let g:maki_export = expand(get(g:, 'maki_export', '~/Wiki/export'))
" }}}
" Commands {{{
command! MakiIndex call maki#nav#goto_page('index')
" }}}
" <Plug> definitions {{{
nnoremap <Plug>maki-index :MakiIndex<CR>
" }}}
" Key mappings {{{
nmap <silent> <Leader>ww <Plug>maki-index
" }}}
