private variable colors = [
%comments
  3,
% api functins
  11,
% intrinsic functions
  14,
%conditional
  13,
%type
  12,
%errors
  17,
];

private variable regexps = [
%comments
  pcre_compile ("((^\s*%.*)|((?<=[\)|;|\s])% .*))"R, 0),
% api public functions and vars
  pcre_compile ("\
((?<=\s|\[\()(keys(?=(->)))\
|(?<=\s|\[|\()([tT]his(?=\.))\
|(?<=^|\s)(class(?=\s))\
|(?<=\s)(var(?=\s))\
|(?<=\s)(let(?=\s))\
|(?<=\s)(def(?=\s))\
|(?<=\s)(fun(?=\s))\
|(?<=\s)(import(?=\s))\
|(?<=^|\s)(end(?=\s|$))\
|(?<=&|\s|\[|\()(unless(?=\s|,))\
|(?<=&|\s|\[|\()(raise(?=\s|,))\
|(?<=&|\s|\[|\()(which(?=\s|,))\
|(?<=&|\s|\[|\()(getch(?=\s|,))\
|(?<=&|\s|\[|\()(fstat(?=\s|,))\
|(?<=&|\s|\[|\()(COLOR(?=\s|\.))\
|(?<=\s|\[)([P|U|G]+ID\s*(?=\s))\
|(?<=&|\s|\[|\()(repeat(?=\s|,))\
|(?<=&|\s|\[|\()(readfile(?=\s|,))\
|(?<=&|\s|\[|\(|^)(__err_handler__)(?=\s|,|\))\
|(?<=&|\s|\[|\(|^)(send_msg(_dr)?(?=\s|,))\
|(?<=&|\s|\[|\(|^)(tostd[out|err]+(?=\s|,))\
|(?<=&|\s|\[|\()(exception_to_array(?=\s|,))\
|(?<=\s|\[|^)((PERM|FLAGS)+\s*(?==|\[))\
|(?<=\s|\[|:)((LINES|COLUMNS)(?=\s|:|\]|\)))\
|(?<=\s|\[|:)(((PROMPT|MSG)+ROW)(?=\s|:|\]|\)))\
|(?<=&|\s|\[|\(|^)((getref|load|import)+f...(?=\s|,))\
|(?<=\s|\[|\(|^)((LCL|USR|STD|MDL|A|HIST|ROOT)+(DATA)?DIR(?=\s|,|\]|\[|;|\))))+"R, 0),
% intrinsic functions
  pcre_compile ("\
((evalfile(?=\s))\
|(?<=&|\s|\[|\()(int(?=\s|,))\
|(?<=&|\s|\[|\()(sum(?=\s|,))\
|(?<=&|\s|\[|\()(max(?=\s|,))\
|(?<=&|\s|\[|\()(any(?=\s|,))\
|(?<=&|\s|\[|\()(pop(?=\s|,))\
|(?<!\w)(\(\)(?=\s|,|\.|;|\)))\
|(?<=&|\s|\[|\()(atoi(?=\s|,))\
|(?<=&|\s|\[|\()(fork(?=\s|,))\
|(?<=&|\s|\[|\()(bind(?=\s|,))\
|(?<=&|\s|\[|\()(pipe(?=\s|,))\
|(?<=&|\s|\[|\()(char(?=\s|,))\
|(?<=&|\s|\[|\()(open(?=\s|,))\
|(?<=&|\s|\[|\()(strup(?=\s|,))\
|(?<=&|\s|\[|\()(fopen(?=\s|,))\
|(?<=&|\s|\[|\()(execv(?=\s|,))\
|(?<=&|\s|\[|\()(chdir(?=\s|,))\
|(?<=&|\s|\[|\()(mkdir(?=\s|,))\
|(?<=&|\s|\[|\()(sleep(?=\s|,))\
|(?<=&|\s|\[|\()(__tmp(?=\s|,))\
|(?<=&|\s|\[|\()(uname(?=\s|,))\
|([s|g]et_\w*_\w*_path(?=\s|,))\
|(?<=&|\s|\[|\()(fflush(?=\s|,))\
|(?<=&|\s|\[|\()(sscanf(?=\s|,))\
|(?<=&|\s|\[|\()(string(?=\s|,))\
|(?<=&|\s|\[|\()(substr(?=\s|,))\
|(?<=&|\s|\[|\()(strlen(?=\s|,))\
|(?<=&|\s|\[|\()(f?read(?=\s|,))\
|(?<=&|\s|\[|\()(access(?=\s|,))\
|(?<=&|\s|\[|\()(getcwd(?=\s|,))\
|(?<=&|\s|\[|\()(cumsum(?=\s|,))\
|(?<=&|\s|\[|\()(rename(?=\s|,))\
|(?<=&|\s|\[|\()(remove(?=\s|,))\
|(?<=&|\s|\[|\()(signal(?=\s|,))\
|(?<=&|\s|\[|\()(execve(?=\s|,))\
|(?<=&|\s|\[|\()(socket(?=\s|,))\
|(?<=&|\s|\[|\()(strtok(?=\s|,))\
|(?<=&|\s|\[|\()(listen(?=\s|,))\
|(?<=&|\s|\[|\()(getenv(?=\s|,))\
|(?<=&|\s|\[|\()(getuid(?=\s|,))\
|(?<=^|&|\s|\[|\()(eval(?=\s|,))\
|(?<=&|\s|\[|\()(mkfifo(?=\s|,))\
|(?<=&|\s|\[|\()(_isnull(?=\s|,))\
|(?<=&|\s|\[|\()(listdir(?=\s|,))\
|(?<=&|\s|\[|\()(isblank(?=\s|,))\
|(?<=&|\s|\[|\()(integer(?=\s|,))\
|(?<=&|\s|\[|\()(strjoin(?=\s|,))\
|(?<=&|\s|\[|\()(f?write(?=\s|,))\
|(?<=&|\s|\[|\()(connect(?=\s|,))\
|(?<=&|\s|\[|\()(strchop(?=\s|,))\
|(?<=&|\s|\[|\()(sprintf(?=\s|,))\
|(?<=&|\s|\[|\()(_?typeof(?=\s|,))\
|(?<=&|\s|\[|\()(_?fileno(?=\s|,))\
|(?<=&|\s|\[|\()(dup2?_fd(?=\s|,))\
|(?<=&|\s|\[|\(|:)(length(?=\s|,))\
|(?<=&|\s|\[|\()(strn?cmp(?=\s|,))\
|(?<=&|\s|\[|\()(f?printf(?=\s|,))\
|(?<=&|\s|\[|\()(realpath(?=\s|,))\
|(?<=&|\s|\[|\()(_stk_roll(?=\s|,))\
|(?<=^|\s|\[|\()(array_map(?=\s|,))\
|(?<=&|\s|\[|\()(qualifier(?=\s|,))\
|(?<=&|\s|\[|\()([l|f]seek(?=\s|,))\
|(?<=&|\s|\[|\()(_stkdepth(?=\s|,))\
|(?<=&|\s|\[|\()(get[gpu]id(?=\s|,))\
|(?<=&|\s|\[|\()(array_sort(?=\s|,))\
|(?<=&|\s|\[|\()(strbytelen(?=\s|,))\
|(?<=&|\s|\[|\()(is_defined(?=\s|,))\
|(?<=&|\s|\[|\()((f|_)?close(?=\s|,))\
|(?<=&|\s|\[|\()(__p\w*_list(?=\s|,))\
|(?<=&|\s|\[|\()(substrbytes(?=\s|,))\
|(?<=&|\s|\[|\()(list_append(?=\s|,))\
|(?<=&|\s|\[|\()(errno_string(?=\s|,))\
|(?<=&|\s|\[|\()(string_match(?=\s|,))\
|(?<=&|\s|\[|\()(__is_callable(?=\s|,))\
|(?<=&|\s|\[|\(|^)(sigprocmask(?=\s|,))\
|(?<=&|\s|\[|\()(list_to_array(?=\s|,))\
|(?<=&|\s|\[|\()(strtrim(_\w*)?(?=\s|,))\
|(?<=&|\s|\[|\(|^)(new_exception)(?=\s|,)\
|(?<=&|\s|\[|\(|^)(__set_argc_argv(?=\s))\
|(?<=&|\s|\[|\()(l?stat_\w*[e|s](?=\s|,))\
|(?<=&|\s|\[|\()(qualifier_exists(?=\s|,))\
|(?<=&|\s|\[|\()(_function_name(?=\s|,|\)))\
|(?<=&|\s|\[|\(|@)(__get_reference(?=\s|,))\
|(?<=&|\s|\[|\()(assoc_\w*_\w*[s,y](?=\s|,))\
|(?<=&|\s|\[|\(|;|@)(__qualifiers(?=\s|,|\)))\
|(?<=&|\s|\[|\()(f(get|put)s[lines]*(?=\s|,))\
|(?<=&|\s|\[|\()(__get_exception_info(?=\s|,|\.))\
|(?<=&|\s|\[|\()(__(is_|un)initialize(d)?(?=\s|,|\.))\
|(?<=^|&|\s|\[|\()((use|current)+_namespace(?=\s|,|\.))\
|(?<=&|\s|\[|\()((g|s)et_struct_field(s|_names)?(?=\s|,))\
|(?<=&|\s|\[|\()(list_(insert|delete|append|to_array)(?=\s|,))\
|(?<=&|\s|\[|\()(where(first|last|not)?(max|min)?(_[engl][qet])?(?=\s|,))\
|(?<=&|\s|\[|\()(path_\w*(nam|(i.*t)|conca)[e|t](?=\s|,)))+"R, 0),
%conditional
  pcre_compile ("\
(^\s*(if(?=\s))\
|^\s*(else if(?=\s))\
|^\s*(while(?=\s))\
|^\s*(else)(?=$|\s{2,}%)\
|^\s*(do$)\
|^\s*(for(?=\s))\
|((?<!\w)ifnot(?=\s))\
|((?<!\w)\{$)\
|((?<!\{)(?<!\w)\}(?=;))\
|((?<!\w)\}$)\
|((?<!\w)loop(?=$|\s))\
|((?<!\w)switch(?=\s))\
|((?<!\w)case(?=\s))\
|((?<!\w)_for(?=\s))\
|((?<!\w)foreach(?=\s))\
|((?<!\w)forever$)\
|((?<!\w)then$)\
|((?<=\w|\])--(?=;|\)|,))\
|((?<=\w|\])\+\+(?=;|\)|,))\
|((?<=\s)[\&\|]+=? ~?)\
|((?<=\s|R|O|H|T|Y|C|D|U|G|P|\])\|(?=\s|O|S))\
|((?<=\s)\?(?=\s))\
|((?<=\s):(?=\s))\
|((?<=\s)\+(?=\s))\
|((?<=\s)-(?=\s))\
|((?<=\s)\*(?=\s))\
|((?<=\s)/(?=\s))\
|((?<=\s)\&\&(?=\s|$))\
|((?<=\s)\|\|(?=\s|$))\
|((?<=').(?='))\
|((?<=\s)(mod|xor)(?=\s))\
|((?<=\s)\+=(?=\s))\
|((?<=\s)!=(?=\s))\
|((?<=\s)>=(?=\s))\
|((?<=\s)<=(?=\s))\
|((?<=\s)<(?=\s))\
|((?<=\s)>(?=\s))\
|((?<=\w)->(?=\w))\
|(?<=:|\s|\[|\()-?\d+(?=:|\s|\]|,|\)|;)\
|(?<=\s)(0x[a-fA-F0-9]{1,5})(?=;|,|\s|\])\
|((?<=\s)==(?=\s)))+"R, 0),
%type
  pcre_compile ("\
(((?<!\w)define(?=\s))\
|(^\{$)\
|(^\}$)\
|((?<!\w)variable(?=[\s]*))\
|(^private(?=\s))\
|(^public(?=\s))\
|(^static(?=\s))\
|(^typedef struct)\
|((?<!\w)struct(?=[\s]*))\
|^\s*(try(?=[\s]*))\
|^\s*(catch(?=\s))\
|^\s*(throw(?=\s))\
|^\s*(finally(?=\s|$))\
|^\s*(return(?=[\s;]))\
|^\s*(break(?=;))\
|^\s*(exit(?=\s))\
|^\s*(import(?=\s))\
|^\s*(continue(?=;))\
|((?<=[\(|\s])errno(?=[;|\)]))\
|(__arg[vc])\
|(SEEK_...)\
|(_NARGS|__FILE__|NULL)\
|((?<!\w)stderr(?=[,\)\.]))\
|((?<!\w)stdin(?=[,\)\.]))\
|((?<!\w)stdout(?=[,\)\.]))\
|((?<!\w)stdout(?=[,\)\.]))\
|((?<=\s|\|)[F|R|W]_OK(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRGRP(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IROTH(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRUSR(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRWXG(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRWXO(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRWXU(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IWGRP(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IWOTH(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IWUSR(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IXGRP(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IXOTH(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IXUSR(?=[,\|;\)]+))\
|((?<=\s|\||\()S_ISUID(?=[,\|;\)]+))\
|((?<=\s|\||\()S_ISGID(?=[,\|;\)]+))\
|((?<=\s|\||\()S_ISVTX(?=[,\|;\)]+))\
|((?<=\s|\|)O_APPEND(?=[,\|;\)]+))\
|((?<=\s|\|)O_BINARY(?=[,\|;\)]+))\
|((?<=\s|\|)O_NOCTTY(?=[,\|;\)]+))\
|((?<=\s|\|)O_RDONLY(?=[,\|;\)]+))\
|((?<=\s|\|)O_WRONLY(?=[,\|;\)]+))\
|((?<=\s|\|)O_CREAT(?=[\s|,\|;\)]+))\
|((?<=\s|\|)O_EXCL(?=[,\|;\)]+))\
|((?<=\s|\|)O_RDWR(?=[,\|;\)]+))\
|((?<=\s|\|)O_TEXT(?=[,\|;\)]+))\
|((?<=\s|\|)O_TRUNC(?=[,\|;\)]+))\
|((?<=\s|\|)O_NONBLOCK(?=[,\|;\)]+))\
|((?<=\(|\[)SIGINT(?=,|\]))\
|((?<=\(|\[)SIGALRM(?=,|\]))\
|((?<=\()SIG_(UN)?BLOCK(?=,))\
|((?<=\(|\s|\[|}|@)\w+_Type(?=[,\s\]\[;\)]))\
|((?<!\w)[\w]+Error(?=[:|,|;])))+"R, 0),
%errors
  pcre_compile ("\
(((?<=\S)\s+$)\
|(^\s+$))+"R, 0),
];

define sl_lexicalhl (s, lines, vlines)
{
  __hl_groups (lines, vlines, colors, regexps);
}

