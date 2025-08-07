if !has('nvim')
  echohl Error
  echom 'This plugin only works with Neovim'
  echohl clear
  finish
endif

" The send statement/definition command.
command! GhClone              lua require("github_nvim").clone()
" Remove default mappings
nnoremap <silent> <leader>n :GhClone<CR>
" nnoremap <silent> <leader>e :ToggleExecuteOnSend<CR>
" nnoremap <silent> <leader>nr :SendPyBuffer<CR>
" vnoremap <silent> <leader>n :<C-U>SendPySelection<CR>
