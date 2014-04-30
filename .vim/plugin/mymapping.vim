map ,a :Ag 
map Q :bd!<cr>

map <space> :nohl<cr>
nmap <leader>d :bprevious<CR>:bdelete #<CR>

command W w
nnoremap <silent> [b :bprevious<CR>
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> [B :bfirst<CR>
nnoremap <silent> ]B :blast<CR>


map ,nn :e ~/Google\ Drive/project_notes/notes.txt<cr>
map ,np :e ~/Google\ Drive/project_notes/
map <c-i> <esc>yiw:tjump <c-r>"<cr>
map ?? :CtrlPMRUFiles<cr>
map ,r :CtrlBufTag<cr>
map <c-b> :CtrlPBuffer<cr>
map ,. <esc>:w!<cr>
imap ,. <esc>:w!<cr>
map <C-s> <esc>:w<CR>
imap <C-s> <esc>:w<CR>
map <C-t> <esc>:tabnew<CR>
map ,F <esc>:FuzzyFinderTag<cr>
map <C-x> <C-w>c
