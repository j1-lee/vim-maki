function! maki#page#export(ext, view) " {{{
  " Export wiki to other formats (determined by {ext}).
  "
  " Preserves wiki directory structure; so can't do it outside the wiki root.
  " If {view} == 1, shows the result afterwards.

  let [l:from_root, l:to_root] = maki#util#relative_to_root()
  if l:from_root == ''
    echomsg 'Cannot export a wiki page outside the wiki root.'
    return
  endif

  function! s:to_markdown(ext, to_root) dict
    if self.type == 'reflink' | return | endif
    call self.normalize()
    let l:target = substitute(self.target, '\.\zswiki$', a:ext, '')
    if self.type == 'refdef'
      let self.middle = '[' . self.text . ']: ' . l:target
    else
      if self.type == 'wiki'
        let l:target = simplify(a:to_root . '/' . l:target)
      endif
      let self.middle = '[' . self.text . '](' . l:target . ')'
    endif
  endfunction

  let l:md = s:convert_links(function('s:to_markdown'), a:ext, l:to_root)

  let l:fhead = g:maki_export . '/' . l:from_root
  let l:ftail = expand('%:t:r') . '.' . a:ext
  let l:fname = simplify(l:fhead . '/' . l:ftail)
  call mkdir(fnamemodify(l:fname, ':h'), 'p')

  try
    if a:ext == 'md'
      call writefile(l:md, l:fname)
    else
      let l:cmd = 'pandoc --from=markdown --output=' . shellescape(l:fname)
      let l:cmd .= ' --standalone --shift-heading-level-by=-1'
      if a:ext == 'html' | let l:cmd .= ' --mathjax' | endif
      let l:pipeout = join(systemlist(l:cmd, l:md))
      if v:shell_error | throw l:pipeout | endif
    endif
  catch
    echohl ErrorMsg | echomsg v:exception | echohl None
    return
  endtry
  echomsg 'Exported the page to' l:fname
  if a:view | call system('xdg-open ' . shellescape(l:fname)) | endif
endfunction
" }}}
function! maki#page#update_toc() " {{{
  " Update the table of contents.
  "
  " Creates or updates toc after a strongly emphasized word 'Contents', e.g.,
  " '**Contents**' or '___Contents___'.

  let l:toc = maki#util#get_headings(2)
  call map(l:toc, 'repeat("  ", v:val.level - 2) . "- [" . v:val.text . "]"')
  call s:update_list('^\(\*\{2,3}\|_\{2,3}\)Contents\1\s*$', l:toc)
endfunction
" }}}
function! s:convert_links(func, ...) " {{{
  " Loop over all links in the page and convert them according to {func}.
  "
  " {func} is a dict function which may have auxiliary arguments if necessary;
  " the optional arguments of this function will be passed to {func}. It will
  " have access to each link object, and is expected to convert the link by
  " directly modifying 'self.middle' etc. Returns the converted page as a list.

  let l:output = []
  let l:is_pre = maki#util#is_pre()
  for l:lnum in range(1, line('$'))
    let l:line = getline(l:lnum)
    if l:is_pre[l:lnum - 1] | call add(l:output, l:line) | continue | endif
    let l:link = maki#link#get_link(l:line)
    while l:link.middle != ''
      call call(a:func, a:000, l:link)
      let l:link = l:link.next()
    endwhile
    call add(l:output, l:link.left)
  endfor
  return l:output
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
