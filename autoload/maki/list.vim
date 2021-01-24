function! maki#list#update_toc() " {{{
  " Update the table of contents.
  "
  " Creates or updates toc after a strongly emphasized word 'Contents', e.g.,
  " '**Contents**' or '___Contents___'.

  let l:toc = maki#util#get_headings(2)
  call map(l:toc, 'repeat("  ", v:val.level - 2) . "- [" . v:val.text . "]"')
  call s:update_list('^\(\*\{2,3}\|_\{2,3}\)Contents\1\s*$', l:toc)
endfunction
" }}}
function! s:update_list(head, body) " {{{
  " Update a list following a specified marker (or 'head').
  "
  " Replaces a list that follows {head: regex} with {body: list}. Creates one
  " if no such list is found.

  let l:curpos = getcurpos()[1:2]
  call cursor([1, 1])
  let l:lnum_head = search(a:head, 'nc')
  if !l:lnum_head | call cursor(l:curpos) | return | endif
  for l:lnum_until in range(l:lnum_head, line('$'))
    if getline(l:lnum_until + 1) !~ '^\s*$\|^\s*[-*+]\S\@!' | break | endif
  endfor
  let l:add_nl_afterwards = l:lnum_until != line('$')
  let l:cursor_after_toc = l:curpos[0] > l:lnum_until
  let l:lines_added = l:lnum_head - l:lnum_until
  if l:lines_added < 0
    execute 'keepjumps' l:lnum_head . '+1,' . l:lnum_until . 'delete _'
  endif
  let l:body = insert(a:body, '')
  if l:add_nl_afterwards | call add(l:body, '') | endif
  call append(l:lnum_head, l:body)
  let l:lines_added += len(l:body)
  if l:cursor_after_toc | let l:curpos[0] += l:lines_added | endif
  call cursor(l:curpos)
endfunction
" }}}
