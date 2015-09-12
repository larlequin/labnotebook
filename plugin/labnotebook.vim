" Vim plug-in
" Laboratory Notebook plugin
" Version: 0.1
" Author: Guillaume T Vallet <gtvallet[a]gmail.com>
" Created: 2014-07-20
" Last change: 2015-06-20

" --------------------------------
"  Ensure that Vim support Python
" --------------------------------
if !has('python')
    echo "Error: Required vim compiled with +python"
	finish
endif

" --------------------------------
" Load Python plugins
" --------------------------------
python import re
python import os
python import csv
python import vim
python import yaml
python import glob
python from subprocess import call
python import datetime
python from time import strftime

" --------------------------------
"  Expose our commands to the user
" --------------------------------
command! -nargs=? LabNote call labnotebook#StartNoteBook(<f-args>)
command! -nargs=? Nsearch call labnotebook#SearchNote(<f-args>)
command! -nargs=1 Notify call labnotebook#ExportNotes(<f-args>)

" --------------------------------
"  Custom commands
" --------------------------------
" Update date and commit on git when leaving Vim
autocmd VimLeave *.lab :call labnotebook#UpdateNote()
autocmd BufWrite *.lab :call labnotebook#UpdateNote()
" Navigate inside searched notes with ctl-f and ctl-d
nnoremap <C-f> :cnext<CR>
nnoremap <C-d> :cprev<CR>
" Call the note search functions
nnoremap <leader>[ :Nsearch 
nnoremap <leader>] :LabNote 
nnoremap <leader>h :Notify html

augroup filetypedetect
    autocmd BufNew,BufNewFile,BufRead *.txt,*.text,*.md,*.markdown,*.lab :setfiletype markdown
augroup END
