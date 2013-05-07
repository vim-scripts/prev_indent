" File: prev_indent.vim
" Author: Alexey Radkov
" Version: 0.1
" Description: A function to move to the previous indentation level
" Usage:
"   Command :PrevIndent to move to the previous indent level. Normally this
"   command is not really needed as soon as indentation levels normally
"   correspond to the value of the shiftwidth and result is easily achieved by
"   pressing <C-d> in Insert mode. But this is not a case for some programming
"   languages (for example Haskell indentation rules are very specific).
"
"   Command :PrevIndent simply aligns the beginning of the current line with
"   the first previous line that starts from a less position.
"
"   The command is supposed to be used in Insert mode. Recommended mappings:
"
"       imap <silent> <C-g><C-g>  <Plug>PrevIndent
"
"   if you want to replace with PrevIndent standard <C-d> Insert mapping or
"
"       imap <silent> <C-g><C-g>  <Plug>PrevIndent
"
"   (press <C-g> twice) otherwise.


if exists('g:loaded_PrevIndentPlugin') && g:loaded_PrevIndentPlugin
    finish
endif

let g:loaded_PrevIndentPlugin = 1

function! s:prev_indent()
    let save_cursor = getpos('.')
    normal ^
    let start_pos = virtcol('.') - 1
    if start_pos == 0
        return ''
    endif
    let rstart_pos = col('.') - 1
    let cur_start_pos = 0
    let cur_lnum = line('.') - 1
    let subst = ''
    while cur_lnum > 0
        normal k^
        let cur_start_pos = virtcol('.') - 1
        let rcur_start_pos = col('.') - 1
        if cur_start_pos < start_pos
            let subst = substitute(getline('.'), '\S.*', '', '')
            break
        endif
        let cur_lnum -= 1
    endwhile
    call setpos('.', save_cursor)
    exe 's/^\s\+/'.subst.'/'
    let save_cursor[2] -= rstart_pos - rcur_start_pos + 1
    call setpos('.', save_cursor)
    return ''
endfunction

command! PrevIndent call s:prev_indent()

imap <silent> <Plug>PrevIndent  <C-r>=<SID>prev_indent()<CR><Right>

