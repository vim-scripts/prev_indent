" File: prev_indent.vim
" Author: Alexey Radkov
" Version: 0.2.2
" Description: Utility functions for custom indentation of line under cursor
" Usage:
"   Command PrevIndent moves line under cursor to the previous indentation
"   level. Normally this command is not really needed as soon as indentation
"   levels in most file types tend to correspond to the value of the
"   shiftwidth and the result is easily achieved by pressing <C-d> in Insert
"   mode. But this is not a case for some programming languages (for example
"   Haskell indentation rules are very specific).
"
"   Command PrevIndent simply aligns the beginning of the current line with
"   the first previous line that starts from a less position.
"
"   Recommended mappings are
"
"   Insert mode:
"
"       imap <silent> <C-d>       <Plug>PrevIndent
"
"   if you want to replace with PrevIndent standard <C-d> Insert mapping or
"
"       imap <silent> <C-g><C-g>  <Plug>PrevIndent
"
"   (press <C-g> twice) otherwise.
"
"   Normal mode:
"
"       nmap <silent> <C-k>k      :PrevIndent<CR>
"
"   Another command provided by the script is AlignWith. It finds a symbol
"   that was specified by user dynamically (i.e. using getchar()) in the right
"   hand side of the previous line and aligns beginning of the current line
"   with the column of the found symbol. If a symbol was not found then it is
"   searched from beginning of the previous line. Repeating AlignWith will
"   cycle alignment of the current line to the right through all searched
"   symbols in the previous line. User can specify an order of symbol to
"   search. For example issuing command
"
"       :AlignWith 2
"
"   and then pressing '(' will skip first found '(' in the previous line and
"   align current line to the second found parenthesis.
"
"   Recommended mappings are
"
"   Insert mode:
"
"       imap <silent> <C-g>g      <Plug>AlignWith
"
"   Normal mode:
"
"       nmap <silent> <C-k>g      :AlignWith<CR>
"
"   In both Insert and Normal modes command AlignWith will wait until user
"   enters a character to align with. So for example in Insert mode user must
"   enter <C-g>g and another character after that.
"
"   Both commands must behave well for different settings of <Tab> expansions.


if exists('g:loaded_PrevIndentPlugin') && g:loaded_PrevIndentPlugin
    finish
endif

let g:loaded_PrevIndentPlugin = 1

function! s:prev_indent(...)
    let save_cursor = getpos('.')
    normal ^
    let start_pos = virtcol('.') - 1
    if start_pos == 0
        let save_cursor[2] -= a:0 ? a:1 : 0
        call setpos('.', save_cursor)
        return ''
    endif
    let rstart_pos = col('.') - 1
    let cur_start_pos = 0
    let subst = ''
    let pass = 0
    while line('.') > 1
        normal k^
        if getline('.') =~ '^\s*$'
            continue
        endif
        let cur_start_pos = virtcol('.') - 1
        let rcur_start_pos = col('.') - 1
        if cur_start_pos < start_pos
            let subst = substitute(getline('.'), '\S.*', '', '')
            let pass = 1
            break
        endif
    endwhile
    if !pass
        let save_cursor[2] -= a:0 ? a:1 : 0
        call setpos('.', save_cursor)
        return ''
    endif
    call setpos('.', save_cursor)
    exe 's/^\s\+/'.subst.'/'
    let save_cursor[2] -= rstart_pos - rcur_start_pos + (a:0 ? a:1 : 0)
    call setpos('.', save_cursor)
    return ''
endfunction

function! s:align_with(symb, ...)
    let add_getchar_shift = a:0 > 0 && a:1 ? 1 : 0
    let save_cursor = getpos('.')
    let add_rstart_pos = getline('.') =~ '^\s*$' && col('.') == col('$') ?
                \ 1 : 0
    let save_cursor[2] -= 1
    normal ^
    let start_pos = virtcol('.') - 1 + add_rstart_pos
    let rstart_pos = col('.') - 1 + add_rstart_pos
    let save_start_pos = 0
    let pass = 0
    while line('.') > 1
        normal k
        if getline('.') =~ '^\s*$'
            continue
        endif
        let pass = 1
        break
    endwhile
    if !pass
        let save_cursor[2] += add_getchar_shift
        call setpos('.', save_cursor)
        return ''
    endif
    let last_symb_match = (col('.') + add_rstart_pos >= col('$') - 1) &&
                \ getline('.')[col('$') - 2] == a:symb
    normal l
    if add_rstart_pos == 1
        normal l
    endif
    let n_repeat = a:0 > 1 && a:2 =~ '^\d\+$' && a:2 > 0 ? a:2 : 1
    let save_n_repeat = n_repeat
    let save_cursor1 = getpos('.')
    if getline('.')[col('.') - 1] == a:symb
        let n_repeat -= 1
    endif
    if n_repeat > 0
        exe 'normal '.n_repeat.'f'.a:symb
    endif
    let n_repeat = save_n_repeat
    if (col('.') == save_cursor1[2] &&
                \ getline('.')[col('.') - 1] != a:symb) || last_symb_match
        normal ^
        let save_cursor1 = getpos('.')
        if getline('.')[col('.') - 1] == a:symb
            let n_repeat -= 1
        endif
        if n_repeat > 0
            exe 'normal '.n_repeat.'f'.a:symb
        endif
        if col('.') == save_cursor1[2] && n_repeat > 0
            let save_start_pos = 1
        endif
        if col('.') == save_cursor1[2] && getline('.')[col('.') - 1] != a:symb
            let save_cursor[2] += add_getchar_shift
            call setpos('.', save_cursor)
            return ''
        endif
    endif
    let cur_start_pos = virtcol('.') - 1
    call setpos('.', save_cursor)
    let offset = save_start_pos ? 0 : cur_start_pos - start_pos
    if offset == 0
        let save_cursor[2] += add_getchar_shift
        call setpos('.', save_cursor)
        return ''
    endif
    if offset > 0
        exe 's/^\s*/\=submatch(0).repeat(" ", '.offset.')/'
    else
        exe 's/^\s*/\=repeat(" ", '.(start_pos + offset).')/'
    endif
    retab!
    normal ^
    let save_cursor[2] += col('.') - 1 - rstart_pos + add_rstart_pos +
                \ add_getchar_shift
    call setpos('.', save_cursor)
    return ''
endfunction

function! s:getchar_align_with(...)
    while getchar(1)
        call getchar()
    endwhile
    let symb = nr2char(getchar())
    return s:align_with(symb, 1, a:0 ? a:1 : 1)
endfunction

command! -nargs=* PrevIndent  call s:prev_indent(<f-args>)
command! -nargs=? AlignWith   call s:getchar_align_with(<f-args>)

imap <silent> <Plug>PrevIndent  <C-r>=<SID>prev_indent(1)<CR><Right>
imap <silent> <Plug>AlignWith   <C-r>=<SID>getchar_align_with()<CR><Right>

