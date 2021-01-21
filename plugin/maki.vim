if exists('g:maki_loaded') | finish | else | let g:maki_loaded = 1 | endif

" Path configuration {{{
let g:maki_root = expand(get(g:, 'maki_root', '~/Wiki'))
let g:maki_journal = expand(get(g:, 'maki_journal', '~/Wiki/journal'))
let g:maki_export = expand(get(g:, 'maki_export', '~/Wiki/export'))
" }}}
" Commands {{{
command! MakiIndex call maki#nav#goto_page('index.wiki')
command! MakiJournal call maki#nav#goto_page('index.wiki', 'journal')
command! MakiToday call maki#nav#goto_page(strftime('%F') . '.wiki', 'journal')
" }}}
" <Plug> definitions {{{
nnoremap <Plug>maki-index :MakiIndex<CR>
nnoremap <Plug>maki-journal :MakiJournal<CR>
nnoremap <Plug>maki-today :MakiToday<CR>
" }}}
" Key mappings {{{
nmap <silent> <Leader>ww <Plug>maki-index
nmap <silent> <Leader>wi <Plug>maki-journal
nmap <silent> <Leader>w<Leader>w <Plug>maki-today
" }}}
