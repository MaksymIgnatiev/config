" Set a highlight group with optional colors and GUI attributes
" For any optional value that needs to be missing - use `''`
" @param {string} group - The highlight group name
" @param {string} [fg] - Foreground color (optional)
" @param {string} [bg] - Background color (optional)
" @param {string} [gui] - GUI attributes like bold, italic, underline (optional, listed coma separated)
function! SetHighlight(group, ...) abort
    let l:cmd = 'highlight ' . a:group

    if a:0 >= 1 && !empty(a:1)
        let l:cmd .= ' guifg=' . a:1
    endif

    if a:0 >= 2 && !empty(a:2)
        let l:cmd .= ' guibg=' . a:2
    endif

    if a:0 >= 3 && !empty(a:3)
        let l:cmd .= ' gui=' . a:3
    endif

    execute l:cmd
endfunction

call SetHighlight()


call SetHighlight('GitSignsAdd'      , '#00FF00')
call SetHighlight('GitSignsChange'   , '#FFFF00')
call SetHighlight('GitSignsDelete'   , '#FF0000')
call SetHighlight('GitSignsAddNr'    , '#00FF00')
call SetHighlight('GitSignsChangeNr' , '#FFFF00')
call SetHighlight('GitSignsDeleteNr' , '#FF0000')
call SetHighlight('GitSignsAddLn'    ,  '', '#003300')
call SetHighlight('GitSignsChangeLn' ,  '', '#333300')
call SetHighlight('GitSignsDeleteLn' ,  '', '#330000')
