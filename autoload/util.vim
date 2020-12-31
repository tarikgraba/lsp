vim9script

# Display a warning message
export def WarnMsg(msg: string)
  :echohl WarningMsg
  :echomsg msg
  :echohl None
enddef

# Display an error message
export def ErrMsg(msg: string)
  :echohl Error
  :echomsg msg
  :echohl None
enddef

# Lsp server trace log directory
var lsp_log_dir: string
if has('unix')
  lsp_log_dir = '/tmp/'
else
  lsp_log_dir = $TEMP .. '\\'
endif
export var lsp_server_trace: bool = v:false

# Log a message from the LSP server. stderr is v:true for logging messages
# from the standard error and v:false for stdout.
export def TraceLog(stderr: bool, msg: string)
  if !lsp_server_trace
    return
  endif
  if stderr
    writefile(split(msg, "\n"), lsp_log_dir .. 'lsp_server.err', 'a')
  else
    writefile(split(msg, "\n"), lsp_log_dir .. 'lsp_server.out', 'a')
  endif
enddef

# Empty out the LSP server trace logs
export def ClearTraceLogs()
  if !lsp_server_trace
    return
  endif
  writefile([], lsp_log_dir .. 'lsp_server.out')
  writefile([], lsp_log_dir .. 'lsp_server.err')
enddef

# Convert a LSP file URI (file://<absolute_path>) to a Vim file name
export def LspUriToFile(uri: string): string
  # Replace all the %xx numbers (e.g. %20 for space) in the URI to character
  var uri_decoded: string = substitute(uri, '%\(\x\x\)',
				'\=nr2char(str2nr(submatch(1), 16))', 'g')

  # File URIs on MS-Windows start with file:///[a-zA-Z]:'
  if uri_decoded =~? '^file:///\a:'
    # MS-Windows URI
    uri_decoded = uri_decoded[8:]
    uri_decoded = uri_decoded->substitute('/', '\\', 'g')
  else
    uri_decoded = uri_decoded[7:]
  endif

  return uri_decoded
enddef

# Convert a Vim filenmae to an LSP URI (file://<absolute_path>)
export def LspFileToUri(fname: string): string
  var uri: string = fnamemodify(fname, ':p')

  var on_windows: bool = v:false
  if uri =~? '^\a:'
    on_windows = v:true
  endif

  if on_windows
    # MS-Windows
    uri = uri->substitute('\\', '/', 'g')
  endif

  uri = uri->substitute('\([^A-Za-z0-9-._~:/]\)',
			'\=printf("%%%02x", char2nr(submatch(1)))', 'g')

  if on_windows
    uri = 'file:///' .. uri
  else
    uri = 'file://' .. uri
  endif

  return uri
enddef

# vim: shiftwidth=2 softtabstop=2
