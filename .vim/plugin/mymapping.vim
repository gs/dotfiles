map ,a :Ag 
map Q :bd!<cr>

map <space> :nohl<cr>
nmap <leader>d :bprevious<CR>:bdelete #<CR>

command W w
nnoremap <silent> [b :bprevious<CR>
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> [B :bfirst<CR>
nnoremap <silent> ]B :blast<CR>


map ,np :e ~/Google\ Drive/project_notes/notes.txt<cr>
map <c-i> <esc>yiw:tjump <c-r>"<cr>
map ?? :CtrlPMRUFiles<cr>
map <c-b> :CtrlPBuffer<cr>
map ,. <esc>:w!<cr>
