setlocal foldmethod=expr
setlocal foldexpr=maki#util#foldlevel(v:lnum) foldtext=getline(v:foldstart)

" Commands {{{
command! -buffer MakiExportMarkdown call maki#page#export('md', 1)
command! -buffer MakiExportHtml call maki#page#export('html', 1)
command! -buffer MakiExportHtmlView call maki#page#export('html', 1, 1)
command! -buffer MakiRename call maki#page#rename()
command! -buffer MakiUpdateToc call maki#page#update_toc()
command! -buffer MakiUpdateSubpage call maki#page#update_subpage()
command! -buffer MakiToggleCheckbox call maki#util#toggle_checkbox()
" }}}
" <Plug> definitions {{{
nnoremap <buffer> <Plug>maki-export-markdown :MakiExportMarkdown<CR>
nnoremap <buffer> <Plug>maki-export-html :MakiExportHtml<CR>
nnoremap <buffer> <Plug>maki-export-html-view :MakiExportHtmlView<CR>
nnoremap <buffer> <Plug>maki-update-toc :MakiUpdateToc<CR>
nnoremap <buffer> <Plug>maki-toggle-checkbox :MakiToggleCheckbox<CR>

map <buffer> <Plug>maki-]] <Cmd>call maki#nav#next_heading(0)<CR>
map <buffer> <Plug>maki-[[ <Cmd>call maki#nav#next_heading(1)<CR>

map <buffer> <Plug>maki-link <Cmd>call maki#link#try_link()<CR>
nnoremap <buffer> <Plug>maki-go-back :call maki#nav#go_back()<CR>

nnoremap <buffer> <Plug>maki-next-link :call maki#nav#next_link(0)<CR>
nnoremap <buffer> <Plug>maki-prev-link :call maki#nav#next_link(1)<CR>
" }}}
" Key mappings {{{
nmap <buffer> <silent> <Leader>we <Plug>maki-export-html
nmap <buffer> <silent> <Leader>wv <Plug>maki-export-html-view
nmap <buffer> <silent> <Leader>wc <Plug>maki-toggle-checkbox

map <buffer> ]] <Plug>maki-]]
map <buffer> [[ <Plug>maki-[[

map <buffer> <CR> <Plug>maki-link
nmap <buffer> <silent> <BS> <Plug>maki-go-back

nmap <buffer> <silent> <Tab> <Plug>maki-next-link
nmap <buffer> <silent> <S-Tab> <Plug>maki-prev-link
" }}}
" Autocmds {{{
augroup MakiAutoExport
  autocmd! * <buffer>
  if g:maki_auto_export
    autocmd BufWritePost <buffer> call maki#page#export('html')
  endif
augroup END
" }}}
