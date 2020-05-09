if !has('python3')
    echo 'vim has to be compiled with +python3 to run vimsence'
    finish
endif

if exists('g:vimsence_loaded')
    finish
endif

if !exists('g:vimsence_discord_flatpak')
    " Flatpak support is disabled by default.
    " This has no effect on Windows.
    let g:vimsence_discord_flatpak=0
endif

let s:plugin_root_dir = fnamemodify(resolve(expand('<sfile>:p')), ':h')

python3 << EOF
import sys
from os.path import normpath, join
import vim
plugin_root_dir = vim.eval('s:plugin_root_dir')
python_root_dir = normpath(join(plugin_root_dir, '..', 'python'))
sys.path.insert(0, python_root_dir)

import vimsence
EOF

let s:vimsence_has_timers = has("timers")
let s:timer = -1

function! DiscordAsyncWrapper(callback)
    if s:vimsence_has_timers
        if s:timer != -1
            " Timer protection; this avoids issues when double events are
            " dispatched.
            " This exists purely to avoid issuing several timers as a result
            " of the autocmd detecting file changes. (see the bottom
            " of this script). Time timer is so low that it shouldn't
            " interfere with several commands being dispatched at once.
            let info = timer_info(s:timer)
            if len(info) == 1 && info[0]["paused"] == 0
                " The timer is running; skip.
                return
            endif
        endif
        " Start the timer to dispatch the event
        let s:timer = timer_start(100, a:callback)
    else
        " Fallback; no timer support, call the function directly.
        call a:callback(0)
    endif
endfunction

" Note on the next functions with a tid argument:
" tid is short for timer id, and it's automatically
" passed to timer callbacks.
function! DiscordUpdatePresence(tid)
    python3 vimsence.update_presence()
    let s:timer = -1
endfunction

function! DiscordReconnect(tid)
    python3 vimsence.reconnect()
    let s:timer = -1
endfunction

function! DiscordDisconnect(tid)
    python3 vimsence.disconnect()
    let s:timer = -1
endfunction

command! -nargs=0 UpdatePresence echo "This command has been deprecated. Use :DiscordUpdatePresence instead."
command! -nargs=0 DiscordUpdatePresence call DiscordAsyncWrapper(function('DiscordUpdatePresence'))
command! -nargs=0 DiscordReconnect call DiscordAsyncWrapper(function('DiscordReconnect'))
command! -nargs=0 DiscordDisconnect call DiscordAsyncWrapper(function('DiscordDisconnect'))

augroup DiscordPresence
    autocmd!
    autocmd BufNewFile,BufRead,BufEnter * :call DiscordAsyncWrapper(function('DiscordUpdatePresence'))
augroup END

let g:vimsence_loaded = 1
