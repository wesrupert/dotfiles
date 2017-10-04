;setlocal sidescrolloff=0 bufhidden=hide buftype=nofile
;%s/^\(.\{-}\)\([^\\]\+\):\([0-9]\+\):\s*\(.*\)\n/\4 · \2 · \1\2 \3\r/g
;%EasyAlign */·/
;%s/^\([^·]\{92}\).\{-}·/\1 ·/
;%s/· \([^·]\{40}\).\{-}·/· \1 ·/
;noh
;noremap <buffer> gf 0f·;llgF
;map <buffer> <return> gf
;map <buffer> <space> gf
;syn match VimfindCol /·\zs.*\ze·/
;hi! VimfindCol guibg=gray
;syn match VimfindEnd /· \zs[^·]*$/
;hi! VimfindEnd guifg=gray
