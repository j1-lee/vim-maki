if exists('b:current_syntax') | finish | endif

syntax spell toplevel

" Comment {{{
syntax region makiComment matchgroup=makiCommentDelim start='^\s*<!--\_s' end='\_s-->\s*$'
highlight link makiComment Comment
highlight link makiCommentDelim makiDelim
" }}}
" Heading {{{
for s:i in range(1, 6)
  execute 'syntax region makiHeading'.s:i 'oneline contains=@Spell'
        \ 'matchgroup=makiHeadingMarker'.s:i 'start=/^#\{'.s:i.'}\s\+/' 'end=/$/'
  execute 'highlight link makiHeading'.s:i 'markdownH'.s:i
  execute 'highlight link makiHeadingMarker'.s:i 'makiHeading'.s:i
endfor
" }}}
" Cluster (inline formatting, link, and miscellaneous) {{{
syntax cluster makiText contains=makiItalic,makiBold,makiCode,makiMathInline
syntax cluster makiText add=makiLink
syntax cluster makiText add=makiNumber,makiBr,@Spell
" }}}
" Miscellaneous {{{
" number
syntax match makiNumber '\<\d\+\%(,\d\{3}\)*\%(\.\d\+\)\?\>'
highlight link makiNumber Number
" line break
syntax match makiBr '\\$'
highlight link makiBr makiDelim
" }}}
" Inline formatting {{{
" italic
" match _ not surrounded by \s nor surrounded by alnum
let s:rx = '/\%(\s\@<!_\|_\s\@!\)\&\%([[:alnum:]]\@<!_\|_[[:alnum:]]\@!\)/'
execute 'syntax region makiItalic oneline skip=/\\_/ contains=makiLink,@Spell'
      \ 'matchgroup=makiItalicDelim' 'start='.s:rx 'end='.s:rx
" match * not surrounded by \s
let s:rx = '/\%(\s\@<!\*\|\*\s\@!\)/'
execute 'syntax region makiItalic oneline skip=/\\\*/ contains=makiLink,@Spell'
      \ 'matchgroup=makiItalicDelim' 'start='.s:rx 'end='.s:rx
highlight link makiItalic markdownItalic
highlight link makiItalicDelim makiTextDelim
" bold
syntax region makiBold oneline contains=makiLink,@Spell
      \ matchgroup=makiBoldDelim start='\z(\*\*\)' start='\z(__\)' end='\z1'
highlight link makiBold markdownBold
highlight link makiBoldDelim makiTextDelim
" code
syntax region makiCode oneline matchgroup=makiCodeDelim start='\z(`\+\)' end='\z1'
highlight link makiCode markdownCode
highlight link makiCodeDelim makiTextDelim
" inline math; explicitly depend on lervag/vimtex, fall back on default syntax
syntax region makiMathInline oneline keepend contains=@texMathZoneGroup,@texClusterMath
      \ matchgroup=makiMathInlineDelim start='\$\ze\S' end='\S\zs\$\ze\_D' skip='\\\$'
highlight link makiMathInline Special
highlight link makiMathInlineDelim makiMathDelim
" }}}
" Link {{{
syntax region makiLink oneline nextgroup=makiTarget contains=@Spell
      \ matchgroup=makiLinkDelim start='!\?\[' end='\]'
syntax region makiLink oneline contains=@Spell
      \ matchgroup=makiLinkDelim start='\[\[' end='\]\]'
syntax match makiLink '<https\?://[.a-zA-Z0-9%!?=&#_\-+*/:()]\+>' contains=makiLinkDelim
syntax match makiLinkDelim '[<>]' contained
syntax region makiTarget oneline contained matchgroup=makiTargetDelim start='(' end=')'
syntax region makiTarget oneline contained matchgroup=makiTargetDelim start='\[' end='\]'
highlight link makiLink markdownLinkText
highlight link makiTarget NonText
highlight link makiLinkDelim makiDelim
highlight link makiTargetDelim makiLinkDelim
highlight link makiImageDelim makiLinkDelim
" }}}
" Link reference definition {{{
syntax region makiRefLabel oneline nextgroup=makiRefTarget
      \ matchgroup=makiLinkDelim start='^\[' end='\]:\ze\s\+'
syntax match makiRefTarget '.\+' contained
highlight link makiRefLabel markdownIdDeclaration
highlight link makiRefTarget NonText
" }}}
" Pre block - generic {{{
syntax region makiPre keepend
      \ matchgroup=makiPreDelim start='^\z(\s*`\{3,}\).*$' end='^\z1\s*$'
highlight link makiPre markdownCodeBlock
highlight link makiPreDelim makiDelim
" }}}
" Pre block - nested syntax {{{
" collect filetypes to include
let s:fts = filter(getline(1, '$'), 'v:val =~ ''^\s*`\{3,}\w\+\s*$''')
call map(s:fts, 'matchstr(v:val, ''^\s*`\{3,}\zs\w\+\ze\s*$'')')
call uniq(sort(add(s:fts, 'tex')))
" include the filetypes
for s:ft in s:fts
  let s:cluster = '@makiNested' . toupper(s:ft)
  let s:group = 'makiPre' . toupper(s:ft)
  if exists('b:current_syntax') | unlet b:current_syntax | endif
  try
    execute 'syntax include' s:cluster 'syntax/'.s:ft.'.vim'
    execute 'syntax include' s:cluster 'after/syntax/'.s:ft.'.vim'
  catch
  endtry
  let s:pat_start = '/^\z(\s*`\{3,}\)'.s:ft.'\s*$/'
  let s:pat_end = '/^\z1\s*$/'
  execute 'syntax region' s:group 'keepend contains='.s:cluster
        \ 'matchgroup=makiPreDelim' 'start='.s:pat_start 'end='.s:pat_end
endfor
" }}}
" Math block; define this AFTER makiMathInline {{{
syntax region makiMathDisplay keepend contains=@texMathZoneGroup,@texClusterMath
      \ matchgroup=makiMathDisplayDelim start='\$\$' end='\$\$'
syntax region makiMathDisplay keepend contains=@texMathZoneGroup,@texClusterMath
      \ matchgroup=makiMathDisplayDelim start='\\begin{\z(\w\+\)}' end='\\end{\z1}'
highlight link makiMathDisplay Special
highlight link makiMathDisplayDelim makiMathDelim
" }}}
" Block quote {{{
syntax region makiQuote oneline contains=@makiText
      \ matchgroup=makiQuoteMarker start='^\s*>' end='$'
highlight link makiQuote markdownBlockquote
highlight link makiQuoteMarker NonText
" }}}
" List {{{
syntax region makiList oneline contains=@makiText
      \ matchgroup=makiListMarker start='^\s*\%([-*+]\|\d\+\.\)\ze\_s'
      \ matchgroup=NONE end='$' keepend
highlight link makiListMarker markdownListMarker
" }}}
" Table {{{
syntax match makiTableBody '^\s*|.\+|\s*$' contained
      \ contains=makiTableDelim,@makiText nextgroup=makiTableBody skipnl
syntax match makiTableRule '^\s*|[ -:|]\+|\s*$' contained
      \ contains=makiTableDelim nextgroup=makiTableBody skipnl
syntax match makiTableHead '^\s*|.\+|\s*$'
      \ contains=makiTableDelim,@makiText nextgroup=makiTableRule skipnl
syntax match makiTableDelim '|' contained
highlight link makiTableHead makiBold
highlight link makiTableDelim makiDelim
highlight link makiTableRule makiTableDelim
" }}}
" Delimiters {{{
highlight link makiTextDelim makiDelim
highlight link makiMathDelim makiDelim
highlight link makiDelim NonText
" }}}

let b:current_syntax = 'wiki'
