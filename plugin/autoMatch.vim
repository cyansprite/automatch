" Vars users can pick {{{1
" search skipper ( we don't like comments and strings
let s:skip ='synIDattr(synID(line("."), col("."), 0), "name") ' .
            \ '=~?	"string\\|comment"'

" By default use these matches
if !has_key(g:,"automatch_matchings")
    let g:automatch_matchings = {
                \ "'" : "'",
                \ '"' : '"',
                \ "(" : ")",
                \ "[" : "]",
                \ "{" : "}"}
endif

if !has_key(g:,"automatch_delimeters")
    let g:automatch_delimeters = [ ',' ]
endif

" by default ignore strings
if !has_key(g:, "automatch_matchInString")
    let g:automatch_matchInString = 0
endif

if !has_key(g:, "automatch_matchInComment")
    let g:automatch_matchInComment = 0
endif

" by default use default ... >.> duh
if !has_key(g:, "autoMatch_useDefaults")
    let g:autoMatch_useDefaults = 1
endif
"}}}1
" Region: helpers
func! s:amICommentOrString(ignoreString, lnnr, col) "{{{1
    " ignore comments and strings given that's the users desire
    let higroup = synIDattr(synIDtrans(synID(a:lnnr,a:col - 1,1)),"name")

    return  (higroup ==# "Comment")
                \ || (a:ignoreString == 0 && (higroup ==# "String"))
endfun "}}}1
func! s:vimComments(char) "{{{1
    " Vim comments are " therefore we need to ignore them
    return &filetype == 'vim' && a:char == '"' && col('.') - 1 == len(getline('.'))
endfun "}}}
func! s:amIApostrophe(char) "{{{1
    " If we are right in front of a-zA-Z then we should not complete, because
    " this is more than likely an apostrophe
    let l:asc = char2nr(getline('.')[col('.') - 2])
    return a:char == "'" && ((l:asc >= char2nr('a') && l:asc <= char2nr('z')) ||
                \ (l:asc >= char2nr('A') && l:asc <= char2nr('Z')))
endfunc "}}}1
func! s:amIBlockCommentForPython(char) " {{{1
    " -------------------------------------------------------------------------
    " NOTE: cases to be valid  | Result |
    " |""       : para behind. |   """|  |so disable for them, insert "
    " "|"       : para inside. |   """|  |so disable for them, insert "
    " ""|       : para front . |   """|  |so disable for them, insert "
    " -------------------------------------------------------------------------
    " NOTE: cases to be invalid  | Result  |
    " |"""       : para behind.   |   """|  |so disable for them, insert "
    " "|""       : para inside.   |   """|  |so disable for them, insert "
    " ""|"       : para inside.   |   """|  |so disable for them, insert "
    " """|       : para front .   |   """|  |so disable for them, insert "
    " -------------------------------------------------------------------------
    let ln = getline('.')
    let front  = a:char == l:ln[col('.') - 3] && a:char == l:ln[col('.') - 2]
    let fab    = a:char != l:ln[col('.') - 4] && a:char != l:ln[col('.') - 1]
    let inside = a:char == l:ln[col('.') - 2] && a:char == l:ln[col('.') - 1]
    let lab    = a:char != l:ln[col('.') - 3] && a:char != l:ln[col('.') - 0]
    let behind = a:char == l:ln[col('.') - 0] && a:char == l:ln[col('.') - 1]
    let bab    = a:char != l:ln[col('.') + 1] && a:char != l:ln[col('.') - 2]

    if l:front && l:fab " ""|
        return 0
    elseif l:inside && l:lab " "|"
        return 1
    elseif l:behind && l:bab " ""|
        return 2
    elseif (l:behind && l:inside) " "|""
        return -2
    elseif (l:front && l:inside) " ""|"
        return -1
    elseif (l:behind) " |"""
        return -3
    elseif (l:front) " """|
        return -4
    endif

    " Doesn't have to do with a block comment
    return -5

endfunc " 1}}}
" EndRegion: helpers

" Region: functions
func! s:beforemain(char) "{{{1
    " -------------------------------------------------------------------------
    " NOTE: cases to be valid  | Result |
    " (|)       : para inside. |   ()|  |
    " -------------------------------------------------------------------------
    " NOTE: python can use block comments
    " refer to s:amIBlockCommentForPython(char)
    " -------------------------------------------------------------------------
    if &filetype == 'python' && a:char == '"'
        let py = s:amIBlockCommentForPython(a:char)
        echom l:py
        if l:py > 0
            let pos = getcurpos()
            let pos[2] = pos[2] + l:py
            let pos[4] = pos[4] + l:py
            call setpos('.', pos)
            return a:char
        elseif l:py > -5
            let pos = getcurpos()
            if l:py > -4
                let l:py = -l:py
                let pos[2] = pos[2] + l:py
                let pos[4] = pos[4] + l:py
                call setpos('.', pos)
            endif
            return ''
        endif
    endif

    if s:amICommentOrString(0, line('.'),col('.')) || s:vimComments(a:char) || s:amIApostrophe(a:char)
        return a:char
    endif

    if a:char == getline('.')[col('.') - 1]
        let pos = getcurpos()
        let pos[2] = pos[2] + 1
        let pos[4] = pos[4] + 1
        call setpos('.', pos)
        return ''
    endif

    " If it's existant, the same thing and it's not an immediate match, go to main...
    if has_key(g:automatch_matchings, a:char)
        return s:main(a:char)
    endif

    return a:char
endfunc
" }}}1
func! s:main(char) "{{{1
    " Initialize
    let l:col = col('.')

    let l:uline = getline('.')
    let l:last = strpart(l:uline, l:col - 1, len(l:uline) - l:col + 1)
    let l:first =  strpart(l:uline, 0, l:col - 1)

    " if comment/string, then return (if user didn't override)
    call setline('.', ' ' . l:first . a:char . l:last . ' ')

    if s:amICommentOrString(0, line('.'),col('.')) || s:vimComments(a:char) || s:amIApostrophe(a:char)
        undo
        return a:char
    endif

    " if it has an unpaired ) somewhere in the future, match it with that

    " set the line..
    call setline('.', l:first . a:char . g:automatch_matchings[a:char] . l:last)
    norm! l

    return ""
endfunc

func! s:dobackspace() "{{{1
    " -------------------------------------------------------------------------
    " NOTE: cases to be valid
    " ()|       : para in front.
    " (|)       : para inside.
    " (| )      : para space in front (rare case).
    " (   )|    : para just expanded, and in front of.
    " (|  )     : para just expanded, and in front of left.
    " -------------------------------------------------------------------------
    " NOTE: Cases that might seem valid but aren't
    " (  |)     : This might be user desire to get rid of spacing by hitting
    "             right, then <bs>
    " ( |)      : This might be user desire to get rid of spacing by hitting
    "             delete then <bs>
    " (  | )    : Some weird amount of space, this seems edge case and maybe
    "             the user wanted the weird spacing such as in strings
    " Any other case I haven't analyzed or have come across.
    " -------------------------------------------------------------------------
    " NOTE: Special Case
    " ( | )     : para just expanded, unexpand it
    " -------------------------------------------------------------------------

    " ignore comments and strings given that's the users desire
    if s:amICommentOrString(1, line('.'),col('.'))
        return ''
    endif

    let pos = getcurpos()
    undo
    let col = col('.')
    let possible = [[3,2], [2,1], [3,0], [5,2], [2,0], [2,-1]]
    let line = getline('.')
    let moveleft = 0
    let redo = 1
    let question = l:line[l:col - 2]

    " loop through each key, if it's one of the positions above, save things.
    for key in keys(g:automatch_matchings)
        for val in possible
            if (l:line[l:col - val[0]] == key &&
            \   l:line[l:col - val[1]] == g:automatch_matchings[key])
                if val[0] == 3 && val[1] == 0
                    call setline('.',
                                \ strpart(l:line, 0, l:col - val[0] + 1) .
                                \ strpart(l:line, l:col, len(l:line) - l:col))
                else
                    " Now set the line
                    call setline('.',
                                \ strpart(l:line, 0, l:col - val[0]) .
                                \ strpart(l:line, l:col - val[1] + 1, len(l:line) - l:col + 1))

                    if val[1] == 2
                        let moveleft = val[0] - val[1]
                    elseif val[1] == 0
                        let moveleft = 1
                    endif
                    let l:redo = 0
                endif

                break
            endif
        endfor
    endfor

    " restore things.
    if l:redo
        redo
    endif
    call setpos('.', pos)

    " if we are at the end of the line there is no need to adjust.
    if len(getline('.')) != col('.') - 1
        if l:moveleft != 0
            exe 'norm ' . l:moveleft . 'h'
        endif
    endif

    " We don't want to return something... a.k.a 0
    return ''
endfunc

func! s:dospacematch() "{{{1
    " -------------------------------------------------------------------------
    " NOTE: cases to be valid
    " (|)       : para inside.
    " -------------------------------------------------------------------------

    " ignore comments and strings given that's the users desire
    if s:amICommentOrString(1, line('.'),col('.'))
        return ''
    endif

    " If inside of para and they haven't expanded yet...
    for key in keys(g:automatch_matchings)
        if getline('.')[col('.') - 3] == key &&
        \  getline('.')[col('.') - 1] == g:automatch_matchings[key]
            "center and insert a space
            norm! h
            return ' '
        endif
    endfor

    return ''
endfunc

func! s:docarriagematch() "{{{1
    " -------------------------------------------------------------------------
    " NOTE: cases to be valid                       (
    " (|)       : para inside.                          |
    " ( | )     : para just expanded.               )
    " -------------------------------------------------------------------------
    " NOTE: special cases to be valid, words after  (
    " (|)xyz    : para inside                           xyz|
    " ( | )xyz  : para just expanded                )
    " -------------------------------------------------------------------------

    " ignore comments and strings given that's the users desire
    if s:amICommentOrString(1, line('.'),col('.'))
        return ''
    endif

    let pos = getcurpos()
    undo
    let col = col('.')
    let possible = [[2,1], [3,0]]
    let line = getline('.')

    " loop through each key, if it's one of the positions above, save things.
    for key in keys(g:automatch_matchings)
        for val in possible
            if (l:line[l:col - val[0]] == key &&
            \   l:line[l:col - val[1]] == g:automatch_matchings[key])

                let diff = val[0] - 2
                let l:uline = getline('.')
                let l:last = strpart(l:uline, l:col + l:diff , len(l:uline) - l:col + l:diff)
                let l:first =  strpart(l:uline, 0, l:col - l:diff - 2)

                call setline('.', l:first . key)
                norm! o
                call setline('.', g:automatch_matchings[key])

                norm! ==
                let l:indent = indent('.')
                norm! O

                " echom "jojo ---------"
                " echom l:last
                " echom "jojo ---------"

                if &expandtab
                    return repeat(' ', (l:indent) + &tabstop) . l:last
                else
                    return repeat('	', (&tabstop + l:indent) / &tabstop) . l:last
                endif
            endif
        endfor
    endfor

    redo
    call setpos('.', pos)
    return ''
endfunc


" TODO make these variables? I don't know man... }}}1
func! s:dotab() " {{{1 {{{2
    return s:doeithertab(1)
endfun
func! s:dostab() "{{{2
    return s:doeithertab(0)
endfun
func! s:dodelim(forward, line, col, inbetween, betweensplit, diffmaker) "{{{2
    " is it just space or more?
    if len(a:betweensplit) == 0
        if a:forward
            return (len(a:inbetween) / 2 + 1) + a:col
        else
            return a:col - (len(a:inbetween) / 2 + 1)
        endif
    else
        if a:forward
            let l:min = 99999

            for lol in g:automatch_delimeters
                let l:new = stridx(a:line, lol, a:col)
                if l:new != -1 && l:new < l:min
                    let l:min = l:new
                endif
            endfor

            echom 'min -- ' . l:min

            if l:min == -1 || l:min == 99999
                return -1
            endif

            return l:min + 1
        else
            let l:max = -99999

            for lol in g:automatch_delimeters
                let l:new = strridx(a:line, lol, a:col - 4)
                if l:new > l:max
                    let l:max = l:new
                endif
            endfor

            echom 'max -- ' . l:max

            if l:max == -99999 || l:max == -1
                return -1
            endif

            return l:max + 1
        endif
    endif
endfunc
func! s:doeithertab(forward) "{{{2
    " -------------------------------------------------------------------------
    " NOTE: Cursor jumps out
    " forward == 1 | right | Example :  ( | )   ->  (   )|
    " forward == 0 | left  | Example :  ( | )  S-> |(   )
    " forward == 1 | right | Example : |(   )   ->  ( | )
    " forward == 0 | left  | Example :  (   )| S->  ( | )
    " -------------------------------------------------------------------------

    " ignore comments and strings given that's the users desire
    if s:amICommentOrString(1, line('.'),col('.'))
        return ''
    endif

    let pos = getcurpos()
    undo

    let col      = col('.')
    let line     = getline('.')
    let min      = 99999
    let minValue = -1
    let keysorted = []

    " loop through each key, if it's one of the positions above, save things.
    " for key in keys(g:automatch_matchings)
    " endfor
    " need to sort these based on how close they are.

    for key in keys(g:automatch_matchings)
        if a:forward
            let diffmaker = 1
        else
            let diffmaker = 2
        endif

        let keyidx = strridx(l:line, key, l:col - l:diffmaker)
        let matchkeyidx = stridx(l:line, g:automatch_matchings[key], l:col - l:diffmaker)
        let recurse = 0
        echom l:keyidx . ' - ' . l:matchkeyidx

        " If we are before or after ()
        if l:keyidx      == (l:col - l:diffmaker) && a:forward  && l:matchkeyidx != -1 ||
         \ l:matchkeyidx == (l:col - l:diffmaker) && !a:forward && l:keyidx      != -1 ||
         \ l:keyidx != -1 && l:matchkeyidx != -1
            " Special case for whenever we are outside the para on right side
            let pos = getcurpos()
            if l:col > l:matchkeyidx + 1
                let pos[2] = l:matchkeyidx + 1
                call setpos('.', pos)
                return ''
            endif

            let l:inbetween = strpart(l:line, l:keyidx + 1, l:matchkeyidx - l:keyidx - 1)
            let l:betweensplit = split(l:inbetween)

            let rtn = s:dodelim(a:forward, l:line, l:col, l:inbetween, l:betweensplit, l:diffmaker)

            if l:rtn != -1
                let l:pos[2] = l:rtn
            else
                if a:forward
                    if l:col <= l:matchkeyidx
                        let l:pos[2] = l:matchkeyidx + 1
                    else
                        let l:pos[2] = l:matchkeyidx + 2
                    endif
                else
                    let l:pos[2] = l:keyidx + 1
                endif
            endif

            let l:pos[4] = l:pos[2]
            call setpos('.', l:pos)
            return ''
        endif
    endfor

    echom l:minValue

    " If we have a find do it
    if l:minValue != -1
        let pos[2] = l:minValue + a:forward + 1
        let pos[4] = l:minValue + a:forward + 1
        call setpos('.', pos)
        return ''
    endif

    redo
    call setpos('.', pos)
    return ''
endfunc "}}}2

func! s:surround(type, ...) "{{{1
    let sel_save = &selection
    let &selection = "inclusive"
    let reg_save = @@
    let savepos = getcurpos()
    let pos  = [0,0]
    let pos2 = [0,0]

    echom "Surround with : "
    let s:surroundChar = getchar()
    let s:surroundChar = nr2char(s:surroundChar)
    let l:passable = 0
    if !has_key(g:automatch_matchings, s:surroundChar)
        for key in keys(g:automatch_matchings)
            if g:automatch_matchings[key] == s:surroundChar
                let s:surroundChar = key
                let l:passable = 1
                break
            endif
        endfor
    else
        let l:passable = 1
    endif

    if !l:passable
        echoe "You don't support this char in g:automatch_matchings : " . s:surroundChar
        return ''
    endif

    if a:0  " Invoked from Visual mode, use `< `>
        silent normal! `<
        let pos  = [line('.'), col('.')]
        silent normal! `>
        let pos2 = [line('.'), col('.')]
    else " Invoked from Normal mode, use `[ `]
        silent normal! `[
        let pos  = [line('.'), col('.')]
        silent normal! `]
        let pos2 = [line('.'), col('.')]
    endif
    let l:line  = getline(l:pos[0])

    if l:pos[0] == l:pos2[0]
        if a:type == "V"
            if l:pos[1] < indent(l:pos[0])
                let l:pos[1] = indent(l:pos[0]) + 1
            endif
        endif

        call setline(l:pos[0], strpart(l:line, 0, l:pos[1] - 1) . s:surroundChar
       \  .  strpart(l:line, l:pos[1] - 1, l:pos2[1] - l:pos[1] + 1) . g:automatch_matchings[s:surroundChar]
       \  .  strpart(l:line, l:pos2[1], len(l:line))
       \)
    else
        if a:type == "V"
            if l:pos[1] < indent(l:pos[0])
                let l:pos[1] = indent(l:pos[0]) + 1
            endif
            if l:pos2[1] < indent(l:pos2[0])
                let l:pos2[1] = indent(l:pos2[0]) + 1
            endif
        endif

        let l:line2 = getline(l:pos2[0])

        call setline(l:pos[0], strpart(l:line, 0, l:pos[1] - 1) . s:surroundChar .
                    \strpart(l:line, l:pos[1] - 1, len(l:line) - l:pos[1] + 1))

        call setline(l:pos2[0], strpart(l:line2, 0, l:pos2[1]) . g:automatch_matchings[s:surroundChar] .
                    \strpart(l:line2, l:pos2[1], len(l:line2) - l:pos2[1]))
    endif



    let &selection = sel_save
    let @@ = reg_save
endfunction


" TODO make these variables? I don't know man... }}}1

" EndRegion: functions

" {{{ Defaults, mappings, and finish

for key in keys(g:automatch_matchings)
    if key ==# "'"
        exe 'inoremap ' . key . " " . "<c-r>=<SID>beforemain(".'"'.key.'"'.")<cr>"
        exe 'inoremap ' . g:automatch_matchings[key] . " " . "<c-r>=<SID>beforemain(".'"'. g:automatch_matchings[key] .'"'.")<cr>"
    else
        exe 'inoremap ' . key . " " . "<c-r>=<SID>beforemain("."'".key."'".")<cr>"
        exe 'inoremap ' . g:automatch_matchings[key] . " " . "<c-r>=<SID>beforemain("."'". g:automatch_matchings[key] ."'".")<cr>"
    endif
endfor

inoremap <Plug>(automatch-space) <space><c-r>=<SID>dospacematch()<cr>
inoremap <Plug>(automatch-back) <c-g>u<bs><c-r>=<SID>dobackspace()<cr>
inoremap <Plug>(automatch-carriage) <c-g>u<cr><c-r>=<SID>docarriagematch()<cr>
inoremap <Plug>(automatch-tab) <c-g>u<tab><c-r>=<SID>dotab()<cr>
inoremap <Plug>(automatch-stab) <c-g>u<s-tab><c-r>=<SID>dostab()<cr>
nnoremap <Plug>(automatch-surround-normal) :set opfunc=<SID>surround<cr>g@
vnoremap <Plug>(automatch-surround-visual) :<c-u>call <SID>surround(visualmode(), 1)<cr>

if g:autoMatch_useDefaults
    imap <silent> <space> <Plug>(automatch-space)
    imap <silent> <bs> <Plug>(automatch-back)
    imap <silent> <cr> <Plug>(automatch-carriage)
    imap <silent> <tab> <Plug>(automatch-tab)
    imap <silent> <s-tab> <Plug>(automatch-stab)
    nmap <silent> <leader>s <Plug>(automatch-surround-normal)
    vmap <silent> <leader>s <Plug>(automatch-surround-visual)
endif
" }}}
