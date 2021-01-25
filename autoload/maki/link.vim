function! maki#link#try_link(visual) " {{{
  " Get a link at the cursor position or create one.
  "
  " Restores visual area if {visual} == 1.

  let l:link = maki#link#get_link()
  if empty(l:link)
    call s:create_link(a:visual)
  else
    try
      call l:link.open()
    catch /E37/
      echomsg 'Can''t open the link; write the buffer first.'
    endtry
  endif
endfunction
" }}}
function! maki#link#get_link(...) " {{{
  " Get a link at the cursor or in a string.
  "
  " If no argument is given, returns a link object found at the cursor
  " position. If not found, returns {}. If an argument {str} is given, returns
  " the first link found in {str}. In this case a dictionary is returned even
  " when no link is found; one can check {return}.middle == ''.

  if !a:0 " no argument given
    if maki#util#is_pre('.') | return {} | endif
    let l:link = maki#link#get_link(getline('.'))
    while l:link.middle != '' && len(l:link.left) < col('.')
      if len(l:link.left . l:link.middle) >= col('.') | return l:link | endif
      let l:link = l:link.next()
    endwhile
    return {} " nothing found
  endif

  let l:link_rxs = [
        \ ['none',     '\(`\+\).\{-}\1'],
        \ ['wiki',     '\[\[\([^]]\+\)\]\]'],
        \ ['markdown', '\[\([^]]\+\)\](\([^)]*\))'],
        \ ['refdef',   '^\[\([^]]\+\)\]:\s\+\(.\+\)'],
        \ ['reflink',  '\[\([^]]\+\)\]\%(\[\([^]]*\)\]\)\?'],
        \ ] " 'none' is not a link type; just used to skip code areas

  let l:rx = join(map(copy(l:link_rxs), 'v:val[1]'), '\|')
  let [l:middle, l:start, l:end] = matchstrpos(a:1, l:rx)
  if l:middle == '' | return {'left': a:1, 'middle': ''} | endif
  let l:left = strpart(a:1, 0, l:start)
  let l:right = strpart(a:1, l:end)

  for [l:type, l:rx] in l:link_rxs " parse the matched string
    let l:match = matchlist(l:middle, (l:rx =~ '^^' ? l:rx : '^' . l:rx))
    if !empty(l:match) | break | endif
  endfor

  if l:type == 'none'
    return call('s:next', [],
          \ {'left': l:left, 'middle': l:middle, 'right': l:right})
  else
    let l:text = l:match[1]
    let l:target = trim((l:match[2] == '') ? l:text : l:match[2])
    return {
          \ 'type': l:type,
          \ 'text': l:text, 'target': l:target,
          \ 'left': l:left, 'middle': l:middle, 'right': l:right,
          \ 'next': function('s:next'),
          \ 'open': function('s:open'),
          \ }
  endif
endfunction
" }}}
function! s:create_link(visual) " {{{
  " Create a (wiki) link at the cursor position or the visual area.
  "
  " If {visual} == 1, then restores the visual area.

  if a:visual
    let l:rx = visualmode() ==# 'V' ? '.\+' : '\%(\%V.\)\+'
  else
    let l:rx = '\k*\%' . col('.') . 'c\k*'
  endif

  let [l:match, l:start, l:end] = matchstrpos(getline('.'), l:rx)
  if l:match == '' | return | endif

  let l:left = strpart(getline('.'), 0, l:start)
  let l:right = strpart(getline('.'), l:end)
  let l:middle = '[[' . l:match . ']]'
  call setline('.', l:left . l:middle . l:right)
endfunction
" }}}
function! s:next() dict " {{{
  " Get the next link object in the string.

  let l:link = maki#link#get_link(self.right)
  let l:link.left = self.left . self.middle . l:link.left
  return l:link
endfunction
" }}}
function! s:open() dict " {{{
  " Well, open the link.

  if self.type == 'wiki'
    call maki#nav#goto_page(self.target)
    return
  elseif self.type == 'reflink' " resolve reference link
    let [l:lnum, l:col] = searchpos('^\[\c' . self.target . '\]:\s\+', 'ne')
    if l:lnum " if definition exists
      let l:target = trim(strpart(getline(l:lnum), l:col))
    else " try headings
      let l:lnum = search('^#\+\s\+' . self.target, 'n')
      if l:lnum
        call maki#nav#add_pos()
        execute 'normal!' l:lnum . 'Gzvzt'
      endif
      return
    endif
  else
    let l:target = self.target
  endif

  if l:target == ''
    return
  elseif l:target =~ '\.wiki$'
    call maki#nav#goto_page(l:target, 1)
  else
    if l:target !~ '^https\?://\|^/'
      let l:target = expand('%:h') . '/' . l:target
    endif
    let l:pipeout = join(systemlist('xdg-open ' . shellescape(l:target)))
    if v:shell_error | echohl ErrorMsg | echomsg l:pipeout | echohl None | endif
  endif
endfunction
" }}}
