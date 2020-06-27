" this file should be added to vimrc 
"    source ~/.vim/plugin/init0_xlog.vim
if exists("g:xlog_loaded")
	finish
endif
let g:xlog_loaded = 1

let s:Util = {}
let g:XLog = s:Util
" 0: nothing
" 1: info
" 2: verbose
" 3: trace
if !exists("g:xdebug")
	if $XDEBUG !=#''
		let g:xdebug=$XDEBUG
	else
		let g:xdebug = 0
	endif
end
function! s:Util.Log(level,msg)
	if a:level > g:xdebug
		return
	endif
	echom a:msg
endfunction

function! s:Util.Info(msg)
	call self.Log(1,a:msg)
endfunction

function! s:Util.Debug(msg)
	call self.Log(2,a:msg)
endfunction

function! s:Util.Trace(msg)
	call self.Log(3,a:msg)
endfunction

function XLogSID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun

" Define command to be used 
" with -bar reports error: Argument Required
"     command! -nargs=1 -bar XInfo call XLrg.Info(<args>)
" with  <CR>
"     command! -nargs=1 XInfo call XLrg.Info(<args>)<CR>
" vim reports ERROR: trailing characters
" NOTE you must add g: prefix,because this command maybe called from a
" function,if not g: prefix,it is considered a local variable
command! -nargs=1 XInfo call g:XLog.Info(<args>)
command! -nargs=1 XDebug call g:XLog.Debug(<args>)
command! -nargs=1 XTrace call g:XLog.Trace(<args>)

XInfo "Load xlog.vim"
