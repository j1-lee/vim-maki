function! maki#nav#goto_page(fname, ...) " {{{
  " Go to a wiki page.
  "
  " {fname} should end with '.wiki'. The optional {where} specifies where to
  " find the wiki page; if omitted or a value other than the following, then
  " {fname} is understood to be relative to the wiki root. If {where} ==
  " 'journal', then relative to g:maki_journal. If {where} == 'relative', then
  " relative to the current page.
  let l:prefix = !a:0 ? g:maki_root
        \ : a:1 == 'journal'  ? g:maki_journal
        \ : a:1 == 'relative' ? expand('%:h')
        \ : g:maki_root " else, e.g., 'wiki', then default to g:maki_root

  let l:bufnr = bufnr()
  execute 'edit' fnameescape(l:prefix . '/' . a:fname)
  augroup maki_mkdir_on_writing
    autocmd!
    autocmd BufWritePre <buffer> call mkdir(expand('%:h'), 'p')
  augroup END
  let s:bufnr_prev = get(s:, 'bufnr_prev', []) + [l:bufnr]
endfunction
" }}}
function! maki#nav#prev_page() " {{{
  " Go back to the previously visited page.

  if empty(get(s:, 'bufnr_prev', [])) | return | endif
  try
    let l:bufnr = remove(s:bufnr_prev, -1)
    execute 'buffer' l:bufnr
  catch /E37/
    echomsg 'Can''t go back; write the buffer first.'
    call add(s:bufnr_prev, l:bufnr)
  catch /E86/ " no such buffer
  endtry
endfunction
" }}}
function! maki#nav#next_heading(backwards, visual, ...) " {{{
  " Jump to the next (or previous) heading.
  "
  " Goes backward if {backwards} == 1. Restores visual area if {visual} == 1.

  if a:0 " optional: jump to the line (internal use only)
    call cursor(a:1, 1)
  elseif a:visual
    normal! gv
  endif

  let l:curpos = getcurpos()[1:2]
  let l:next = search('^#\+\s', a:backwards ? 'nWb' : 'nW')
  if !l:next | return | endif
  if !maki#util#is_pre(l:next) " if not in a pre block
    execute 'normal!' l:next . 'Gzvzt'
  elseif !maki#nav#next_heading(a:backwards, a:visual, l:next) " search further
    call cursor(l:curpos)
    return
  endif
  return l:next
endfunction
" }}}
function! maki#nav#next_link(backwards) " {{{
  " Jump to the next link.
  "
  " This is crude; jumps also to inline code areas or pre blocks as well.

  call search('\]\@<!\[[^]]*\]', a:backwards ? 'b' : '')
endfunction
" }}}
