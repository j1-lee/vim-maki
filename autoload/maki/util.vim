function! maki#util#foldlevel(lnum) " {{{
  " Get the fold level.

  if getline(a:lnum) =~ '^#\+\s' && !maki#util#is_pre(a:lnum)
    return '>' . (len(matchstr(getline(a:lnum), '#\+')) - 1)
  endif
  return '='
endfunction
" }}}
function! maki#util#is_pre(...) " {{{
  " Check whether a line is inside a pre block.

  " The optional argument {lnum} can be a number, '.', or '$'. If no argument
  " is given, returns a list for all lines in the buffer.

  " The syntax rule is more stringent than pandoc markdown; the corresponding
  " fences must have the same indent and the same number of backticks.

  let l:output = []
  let l:is_pre = 0
  for l:line in getline(1, a:0 ? a:1 : '$')
    let l:match = matchlist(l:line, '^\(\s*\)\(`\{3,}\)\s*\(.*\)')
    if empty(l:match) | call add(l:output, l:is_pre) | continue | endif
    if l:is_pre
      if l:match[1:2] == l:last_match[1:2] && l:match[3] == ''
        let l:is_pre = 0
      endif
      call add(l:output, 1)
    else
      let l:last_match = l:match
      let l:is_pre = 1
      call add(l:output, 1)
    endif
  endfor

  return a:0 ? l:output[-1] : l:output
endfunction
" }}}
function! maki#util#relative_to_root() " {{{
  " Get the path from/to the wiki root.
  "
  " Returns a list [{from}, {to}]. If called at 'wikiroot/foo/bar.wiki',
  " returns ['foo', '..']. If called at 'wikiroot/baz.wiki', returns ['.',
  " '.']. If the current page is not under the wiki root, returns ['', ''].

  let l:cwd = getcwd()
  execute 'noautocmd cd' fnameescape(g:maki_root)
  let l:from_root = expand('%:.:h')
  execute 'noautocmd cd' fnameescape(l:cwd)
  if l:from_root =~ '^/' | let l:from_root = '' | endif " not under wiki root
  let _ = split(l:from_root, '/')
  call map(_, '(v:val == "." || v:val == "") ? v:val : ".."')
  return [l:from_root, join(_, '/')]
endfunction
" }}}
function! maki#util#get_headings(minlevel) " {{{
  " Get the list of headings
  "
  " Returns headings of level {minlevel}, {minlevel} + 1, ...

  let l:is_pre = maki#util#is_pre()
  let l:headings = []
  for l:lnum in range(1, line('$'))
    if l:is_pre[l:lnum - 1] | continue | endif
    let l:match = matchlist(getline(l:lnum), '^\(#\+\)\(\s\+.*\)\?\s*$')
    if empty(l:match) || len(l:match[1]) < a:minlevel | continue | endif
    call add(l:headings,
          \ {'lnum': l:lnum, 'level': len(l:match[1]), 'text': trim(l:match[2])}
          \ )
  endfor
  return l:headings
endfunction
" }}}
