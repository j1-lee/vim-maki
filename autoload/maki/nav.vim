function! maki#nav#goto_page(name, ...) " {{{
  " Go to a wiki page.
  "
  " {name} may or may not end with '.wiki'.
  "
  " If the optional {relative} == 1, then the path is relative to the current
  " page. Otherwise the target page is relative to the wiki root.

  let l:name = a:name == '' ? 'index.wiki'
        \ : a:name =~ '\.wiki$' ? a:name
        \ : a:name . '.wiki'
  let l:relative = a:0 ? a:1 : 0
  let l:fname = (l:relative ? expand('%:h') : g:maki_root) . '/' . l:name

  if &modified
    echomsg 'Can''t open the link; write the buffer first.'
    return
  endif

  call maki#nav#add_pos()
  execute 'edit' fnameescape(l:fname)
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
    call add(s:pos_prev, [l:bufnr, l:pos])
  catch /E86/ " no such buffer
  endtry
endfunction
" }}}
function! maki#nav#add_pos() " {{{
  " Add current position to the previous positions stack.

  let s:pos_prev = add(get(s:, 'pos_prev', []), [bufnr(), getcurpos()])
endfunction
" }}}
function! maki#nav#next_heading(backwards) " {{{
  " Jump to the next (or previous) heading.

  let [l:cmp, l:idx] = a:backwards ? ['<', -1] : ['>', 0]
  let l:headings = maki#util#get_headings(1)
  if !empty(filter(l:headings, 'v:val.lnum ' . l:cmp . ' line(".")'))
    execute 'normal!' l:headings[l:idx].lnum . 'Gzvzt'
  endif
endfunction
" }}}
function! maki#nav#next_link(backwards) " {{{
  " Jump to the next (or prev) link in the current line.

  if maki#util#is_pre('.') | return {} | endif
  let l:link = maki#link#get_link(getline('.'))
  while l:link.middle != ''
    let l:next = l:link.next()
    if !a:backwards
      if len(l:link.left) >= col('.')
        call cursor('.', len(l:link.left) + 1)
        return
      endif
    else " backwards
      if len(l:next.left . l:next.middle) >= col('.')
        call cursor('.', min([col('.'), len(l:link.left . l:link.middle)]))
        return
      endif
    endif
    let l:link = l:next
  endwhile
endfunction
" }}}
