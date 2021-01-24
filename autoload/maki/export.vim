function! maki#export#export(ext, view) " {{{
  " Export wiki to other formats (determined by {ext}).
  "
  " Preserves wiki directory structure; so can't do it outside the wiki root.
  " If {view} == 1, shows the result afterwards.

  let [l:from_root, l:to_root] = maki#util#relative_to_root()
  if l:from_root == ''
    echomsg 'Cannot export a wiki page outside the wiki root.'
    return
  endif

  let l:md = [] " will contain lines in markdown format
  let l:is_pre = maki#util#is_pre()
  for l:lnum in range(1, line('$'))
    let l:line = getline(l:lnum)
    if l:is_pre[l:lnum - 1] | call add(l:md, l:line) | continue | endif
    let l:link = maki#link#get_link(l:line)
    while l:link.middle != ''
      if l:link.type != 'reflink'
        call l:link.normalize()
        let l:target = substitute(l:link.target, '\.\zswiki$', a:ext, '')
        if l:link.type == 'refdef'
          let l:link.middle = '[' . l:link.text . ']: ' . l:target
        else
          if l:link.type == 'wiki'
            let l:target = simplify(l:to_root . '/' . l:target)
          endif
          let l:link.middle = '[' . l:link.text . '](' . l:target . ')'
        endif
      endif
      let l:link = l:link.next()
    endwhile
    call add(l:md, l:link.left)
  endfor

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
