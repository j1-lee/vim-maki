setlocal foldmethod=expr
setlocal foldexpr=maki#util#foldlevel(v:lnum) foldtext=getline(v:foldstart)

" Commands {{{
command! -buffer MakiExportMarkdown call maki#page#export('md', 0)
command! -buffer MakiExportHtml call maki#page#export('html', 0)
command! -buffer MakiExportHtmlView call maki#page#export('html', 1)
command! -buffer MakiRename call maki#page#rename()
command! -buffer MakiUpdateToc call maki#page#update_toc()
" }}}
" <Plug> definitions {{{
nnoremap <buffer> <Plug>maki-export-markdown :MakiExportMarkdown<CR>
nnoremap <buffer> <Plug>maki-export-html :MakiExportHtml<CR>
nnoremap <buffer> <Plug>maki-export-html-view :MakiExportHtmlView<CR>
nnoremap <buffer> <Plug>maki-update-toc :MakiUpdateToc<CR>

nnoremap <buffer> <Plug>maki-]] :call maki#nav#next_heading(0, 0)<CR>
nnoremap <buffer> <Plug>maki-[[ :call maki#nav#next_heading(1, 0)<CR>
xnoremap <buffer> <Plug>maki-]]-v :<C-u>call maki#nav#next_heading(0, 1)<CR>
xnoremap <buffer> <Plug>maki-[[-v :<C-u>call maki#nav#next_heading(1, 1)<CR>

nnoremap <buffer> <Plug>maki-link :call maki#link#try_link(0)<CR>
xnoremap <buffer> <Plug>maki-link-v :<C-u>call maki#link#try_link(1)<CR>
nnoremap <buffer> <Plug>maki-go-back :call maki#nav#go_back()<CR>

nnoremap <buffer> <Plug>maki-next-link :call maki#nav#next_link(0)<CR>
nnoremap <buffer> <Plug>maki-prev-link :call maki#nav#next_link(1)<CR>
" }}}
" Key mappings {{{
nmap <buffer> <silent> <Leader>we <Plug>maki-export-html
nmap <buffer> <silent> <Leader>wv <Plug>maki-export-html-view

nmap <buffer> <silent> ]] <Plug>maki-]]
nmap <buffer> <silent> [[ <Plug>maki-[[
xmap <buffer> <silent> ]] <Plug>maki-]]-v
xmap <buffer> <silent> [[ <Plug>maki-[[-v

nmap <buffer> <silent> <CR> <Plug>maki-link
xmap <buffer> <silent> <CR> <Plug>maki-link-v
nmap <buffer> <silent> <BS> <Plug>maki-go-back

nmap <buffer> <silent> <Tab> <Plug>maki-next-link
nmap <buffer> <silent> <S-Tab> <Plug>maki-prev-link
" }}}
