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
  " the first link occurrence in {str}. In this case a dictionary is returned
  " even when no link is found; one can check {return}.middle == ''.
  "
  " The link target is not normalized; call {return}.normalize() before use.

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
        \ {'type': 'wiki',     'rx': '\[\[\([^]]\+\)\]\]'},
        \ {'type': 'markdown', 'rx': '!\?\[\([^]]\+\)\](\([^)]*\))'},
        \ {'type': 'refdef',   'rx': '^\[\([^]]\+\)\]:\s\+\(.\+\)'},
        \ {'type': 'reflink',  'rx': '!\?\[\([^]]\+\)\]\%(\[\([^]]*\)\]\)\?'},
        \ {'type': 'none',     'rx': '\(`\+\).\{-}\1'},
        \ ] " 'none' is not a link type; just used for ignoring code area
  let _ = copy(l:link_rxs)
  call map(_, '{''key'': v:key, ''idx'': match(a:1, v:val.rx)}')
  call sort(_, {a, b -> a.idx < 0 ? 1 : b.idx < 0 ? -1 : a.idx - b.idx})
  let l:first = _[0] " get the earliest match

  if l:first.idx < 0 | return {'left': a:1, 'middle': ''} | endif

  let l:first.type = l:link_rxs[l:first.key].type
  let l:first.match = matchlist(a:1, l:link_rxs[l:first.key].rx, l:first.idx)

  let l:left = strpart(a:1, 0, l:first.idx)
  let l:middle = l:first.match[0]
  let l:right = strpart(a:1, l:first.idx + len(l:middle))

  if l:first.type == 'none' " if first match is not valid, search further
    return call('s:next', [],
          \ {'left': l:left, 'middle': l:middle, 'right': l:right})
  else
    let l:text = l:first.match[1]
    let l:target = (l:first.match[2] == '') ? l:text : l:first.match[2]
    return {
          \ 'type': l:first.type,
          \ 'text': l:text, 'target': l:target,
          \ 'left': l:left, 'middle': l:middle, 'right': l:right,
          \ 'next': function('s:next'),
          \ 'normalize': function('s:normalize'),
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
function! s:normalize() dict " {{{
  " Make the link target more readily usable.
  "
  " For {type} == 'wiki', normalize the filename and add '.wiki'; for this
  " type, the target is still relative to the wiki root (not to the current
  " page). For {type} == 'reflink', fetch the definition.

  if self.type == 'wiki'
    let _ = substitute(self.target, '[^-_/0-9a-zA-Z\u0100-\uFFFF]', '-', 'g')
    let _ = substitute(_, '-\{2,}', '-', 'g')
    let _ = trim(tolower(_), '-')
    let self.target = _ . (_ =~ '/$' ? 'index.wiki' : '.wiki')
  elseif self.type == 'reflink'
    let [l:lnum, l:col] = searchpos('^\[\c' . self.target . '\]:\s\+', 'ne')
    let self.target = strpart(getline(l:lnum), l:col)
  endif
  let self.target = trim(self.target)
endfunction
" }}}
function! s:open() dict " {{{
  " Well, open the link.

  call self.normalize()
  if self.target == ''
    return
  elseif self.target =~ '\.wiki$'
    let l:where = (self.type == 'wiki') ? 'wiki' : 'relative'
    call maki#nav#goto_page(self.target, l:where)
  else
    let l:target = self.target
    if l:target !~ '^https\?://'
      let l:target = expand('%:h') . '/' . l:target
    endif
    let l:pipeout = join(systemlist('xdg-open ' . shellescape(l:target)))
    if v:shell_error | echohl ErrorMsg | echomsg l:pipeout | echohl None | endif
  endif
endfunction
" }}}
