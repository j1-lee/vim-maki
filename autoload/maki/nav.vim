function! maki#nav#goto_page(fname, ...) " {{{
  " Go to a wiki page.
  "
  " {fname} should end with '.wiki'. The optional {where} specifies where to
  " find the wiki page; if omitted or a value other than the following, then
  " {fname} is understood to be relative to the wiki root. If {where} ==
  " 'journal', then relative to g:maki_journal. If {where} == 'relative', then
  " relative to the current page.
  if &modified
    echomsg 'Can''t open the link; write the buffer first.'
    return
  endif

  let l:prefix = !a:0 ? g:maki_root
        \ : a:1 == 'journal'  ? g:maki_journal
        \ : a:1 == 'relative' ? expand('%:h')
        \ : g:maki_root " else, e.g., 'wiki', then default to g:maki_root

  call maki#nav#add_pos()
  execute 'edit' fnameescape(l:prefix . '/' . a:fname)
  augroup maki_mkdir_on_writing
    autocmd!
    autocmd BufWritePre <buffer> call mkdir(expand('%:h'), 'p')
  augroup END
endfunction
" }}}
function! maki#nav#go_back() " {{{
  " Go back to the last saved position.

  if empty(get(s:, 'pos_prev', [])) | return | endif
  try
    let [l:bufnr, l:pos] = remove(s:pos_prev, -1)
    execute 'buffer' l:bufnr
    call setpos('.', l:pos)
  catch /E37/
    echomsg 'Can''t go back; write the buffer first.'
    call add(s:pos_prev, l:pos)
  catch /E86/ " no such buffer
  endtry
endfunction
" }}}
function! maki#nav#add_pos() " {{{
  " Add current position to the previous positions stack.

  let s:pos_prev = add(get(s:, 'pos_prev', []), [bufnr(), getcurpos()])
endfunction
" }}}
function! maki#nav#next_heading(backwards, visual) " {{{
  " Jump to the next (or previous) heading.
  "
  " Goes backward if {backwards} == 1. Restores visual area if {visual} == 1.

  if a:visual
    normal! gv
  endif

  let [l:cmp, l:idx] = a:backwards ? ['<', -1] : ['>', 0]
  let l:headings = maki#util#get_headings(1)
  if !empty(filter(l:headings, 'v:val.lnum ' . l:cmp . ' line(".")'))
    execute 'normal!' l:headings[l:idx].lnum . 'Gzvzt'
  endif
endfunction
" }}}
function! maki#nav#next_link(backwards) " {{{
  " Jump to the next link.
  "
  " This is crude; jumps also to inline code areas or pre blocks as well.

  call search('\]\@<!\[[^]]*\]', a:backwards ? 'b' : '')
endfunction
" }}}
