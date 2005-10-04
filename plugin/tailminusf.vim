" File: tailminusf.vim
" Author: Jason Heddings (vim at heddway dot com)
" Version: 1.0
" Last Modified: 04 October, 2005
"
" See ':help tailminusf' for more information.
"   
if exists('g:loaded_tailminusf')
  finish
endif
let g:loaded_tailminusf = 1


" set the default options for the plugin
if !exists("g:Tail_Minus_F_Height")
  let g:Tail_Minus_F_Height = 10
endif
if !exists("g:Tail_Minus_F_Center_Win")
  let g:Tail_Minus_F_Center_Win = 0
endif


" command exports
command -nargs=1 -complete=file Tail call TailMinusF(<q-args>)


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" sets up the preview window to watch the specified file for changes
function! TailMinusF(file)
  let l:file = substitute(expand(a:file), "\\", "/", "g")

  if !filereadable(l:file)
    echohl ErrorMsg | echo "Cannot open for reading: " . l:file | echohl None
    return
  endif

  " if the buffer is already open, kill it
  pclose  " in case there is a preview window already, also removes autocmd's
  if bufexists(bufnr(l:file))
    execute ':' . bufnr(l:file) . 'bwipeout'
  endif

  " set it up to be watched closely
  augroup TailMinusF
    " monitor calls -- try to catch the update as much as possible
    autocmd CursorHold * checktime
    autocmd FocusLost * checktime
    autocmd FocusGained * checktime

    " utility calls
    execute "autocmd BufWinEnter " . l:file . " call TailMinusF_Setup()"
    execute "autocmd BufWinLeave " . l:file . " call TailMinusF_Stop()"
    execute "autocmd FileChangedShell " . l:file . " :call TailMinusF_Refresh()"
  augroup END

  " set up the new window with minimal functionality
  silent execute g:Tail_Minus_F_Height . "new " . l:file
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" used by TailMinusF to set up the preview window settings
function! TailMinusF_Setup()
  setlocal noswapfile
  setlocal noshowcmd
  setlocal bufhidden=delete
  setlocal nobuflisted
  setlocal nomodifiable
  setlocal nowrap
  setlocal nonumber
  setlocal previewwindow

  call TailMinusF_SetCursor()
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" used by TailMinusF to refresh the window contents & position
" use this instead of autoread for silent reloading and better control
function! TailMinusF_Refresh()
  if &previewwindow
    " if the cursor is on the last line, we'll move it with the update
    if line(".") != line("$")
      let l:update_cursor = 0
    else
      let l:update_cursor = 1
    endif

    " do all the necessary updates
    silent execute "edit!"
    if l:update_cursor
      call TailMinusF_SetCursor()
    endif
  else
    " jump to the preview window to reload
    wincmd P

    " do all the necessary updates
    silent execute "edit!"
    call TailMinusF_SetCursor()

    " jump back
    wincmd p
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" used by TailMinusF to set the cursor position in the preview window
" assumes that the correct window has already been selected
function! TailMinusF_SetCursor()
  normal G
  if g:Tail_Minus_F_Center_Win
    normal zz
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" used by TailMinusF to stop watching the file and clean up
function! TailMinusF_Stop()
  autocmd! TailMinusF
  augroup! TailMinusF
endfunction
