function! maki#page#export(ext, ...) " {{{
  " Export wiki to other formats (determined by {ext}).
  "
  " Preserves wiki directory structure; so can't do it outside the wiki root.
  " Optional arguments are {showmsg} and {view}:
  "   if {showmsg} == 1, show the message 'Exported the page to ...'
  "   if {view} == 1, view the result afterwards (using xdg-open).

  let [l:from_root, l:to_root] = maki#util#relative_to_root()
  if l:from_root == ''
    echomsg 'Cannot export a wiki page outside the wiki root.'
    return
  endif

  function! s:to_markdown(ext, to_root) dict
    if self.type == 'reflink'
      return
    elseif self.type == 'wiki'
      let l:target = simplify(a:to_root . '/' . self.target . '.' . a:ext)
      let self.middle = '[' . self.text . '](' . l:target . ')'
    else
      let l:target = substitute(self.target, '\.\zswiki$', a:ext, '')
      if self.type == 'refdef'
        let self.middle = '[' . self.text . ']: ' . l:target
      else
        let self.middle = '[' . self.text . '](' . l:target . ')'
      endif
    endif
  endfunction

  let l:md = s:convert_links(getline(1, '$'), function('s:to_markdown'),
        \ a:ext, l:to_root)

  let l:fhead = g:maki_export . '/' . l:from_root
  let l:ftail = expand('%:t:r') . '.' . a:ext
  let l:fname = simplify(l:fhead . '/' . l:ftail)

  try
    call mkdir(fnamemodify(l:fname, ':h'), 'p')
    if a:ext == 'md'
      call writefile(l:md, l:fname)
    else
      let l:cmd = 'pandoc --from=markdown --output=' . shellescape(l:fname)
      let l:cmd .= ' --standalone --shift-heading-level-by=-1'
      let l:cmd .= ' --metadata=title:' . shellescape(expand('%:t:r'))
      if a:ext == 'html' | let l:cmd .= ' --mathjax' | endif
      let l:pipeout = join(systemlist(l:cmd, l:md))
      if v:shell_error | throw l:pipeout | endif
    endif
  catch
    echohl ErrorMsg | echomsg v:exception | echohl None
    return
  endtry

  if a:0 >= 1 && a:1 | echomsg 'Exported the page to' l:fname | endif
  if a:0 >= 2 && a:2 | call system('xdg-open ' . shellescape(l:fname)) | endif
endfunction
" }}}
function! maki#page#rename() " {{{
  " Rename the current page and update all wiki links pointing to it.
  "
  " Does not update non-wiki links; those might need manual updating.

  let l:from_root = maki#util#relative_to_root()[0]
  if l:from_root == ''
    echomsg 'Cannot rename a wiki page outside the wiki root.'
    return
  endif

  let l:from = expand('%:t:r')
  if l:from_root != '.' | let l:from = l:from_root . '/' . l:from | endif

  let l:to = trim(input('Rename this page to: ', l:from))
  if l:to == '' || l:to == l:from | return | endif
  let l:fname = g:maki_root . '/' . l:to . '.wiki'
  if filewritable(l:fname)
        \ && confirm(l:to . ' exists. Overwrite it?', "&Yes\n&No", 2) != 1
    return
  endif

  execute 'saveas!' fnameescape(l:fname)

  function! s:rename_to(from, to, modified) dict
    if self.type == 'wiki' && self.target == a:from
      let self.middle = '[[' . a:to. ']]'
      call add(a:modified, 1)
    endif
  endfunction

  for l:fname in glob(g:maki_root . '/**/*.wiki', 0, 1)
    let l:modified = []
    let l:output = s:convert_links(readfile(l:fname), function('s:rename_to'),
          \ l:from, l:to, l:modified)
    if !empty(l:modified)
      call writefile(l:output, l:fname)
      echomsg 'Updated' l:fname
    endif
  endfor
endfunction
" }}}
function! maki#page#update_toc() " {{{
  " Update the table of contents.
  "
  " Creates or updates toc after a strongly emphasized word 'Contents', e.g.,
  " '**Contents**' or '___Contents___'.

  let l:toc = maki#util#get_headings(2)
  call map(l:toc, '{
        \ "text": "[" . v:val.text . "]",
        \ "indent": (v:val.level - 2) * 2
        \ }')
  call s:update_list('Contents', l:toc)
endfunction
" }}}
function! maki#page#update_subpage() " {{{
  " Update the list of subpages.
  "
  " Creates or updates the list of subpages after a strongly emphasized word
  " 'Subpages'. It might be useful for navigating between journal pages.

  let l:from_root = maki#util#relative_to_root()[0]
  if l:from_root == ''
    echomsg 'Cannot do this outside the wiki root.'
    return
  else
    let l:this_page = expand('%:t:r')
    if l:from_root != '.'
      let l:this_page = l:from_root . '/' . l:this_page
    endif
  endif

  let l:pages = glob(expand('%:p:r') . '/*.wiki', 0, 1)
  call map(l:pages,
        \ '"[[" . l:this_page . "/" . fnamemodify(v:val, ":t:r") . "]]"')

  call s:update_list('Subpages', l:pages)
endfunction
" }}}
function! s:convert_links(lines, func, ...) " {{{
  " Loop over all links in the page and convert them according to {func}.
  "
  " {func} is a dict function which may have auxiliary arguments if necessary;
  " the optional arguments of this function will be passed to {func}. It will
  " have access to each link object, and is expected to convert the link by
  " directly modifying 'self.middle' etc. Returns the converted page as a list.

  let l:output = []
  let l:is_pre = maki#util#is_pre(a:lines)
  for l:idx in range(len(a:lines))
    let l:line = a:lines[l:idx]
    if l:is_pre[l:idx] | call add(l:output, l:line) | continue | endif
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
  " Replaces (or creates) a list after {head: string}, with items given as
  " {body: list}. Each item of {body} is either string or dict. If string, it
  " is added to the list with no indentation. If dict, its 'text' is added
  " with 'indent' number of spaces prepended.

  let l:curpos = getcurpos()[1:2]
  let l:lnum_head = search('^\(\*\{2,3}\|_\{2,3}\)'. a:head . '\1\s*$', 'nc')
  if !l:lnum_head | return | endif
  for l:lnum_until in range(l:lnum_head, line('$'))
    if getline(l:lnum_until + 1) !~ '^\s*$\|^\s*[-*+]\S\@!' | break | endif
  endfor
  let l:add_nl_afterwards = l:lnum_until != line('$')
  let l:cursor_after_list = l:curpos[0] > l:lnum_until
  let l:lines_added = l:lnum_head - l:lnum_until
  if l:lines_added < 0
    execute 'keepjumps' l:lnum_head . '+1,' . l:lnum_until . 'delete _'
  endif
  call map(a:body, 'type(v:val) == v:t_dict
        \ ? repeat(" ", v:val.indent) . "- " . v:val.text : "- " . v:val
        \ ')
  call insert(a:body, '')
  if l:add_nl_afterwards | call add(a:body, '') | endif
  call append(l:lnum_head, a:body)
  let l:lines_added += len(a:body)
  if l:cursor_after_list | let l:curpos[0] += l:lines_added | endif
  call cursor(l:curpos)
endfunction
" }}}
