variable getchar_lang;
variable maps = Ref_Type[2];
variable TTY_INITED = 0;

importfrom ("std", "getkey", "input", &on_eval_err);

loadfrom ("keys", "keysInit", 1, &on_eval_err);
loadfrom ("input", "inputinit", 1, &on_eval_err);

maps[0] = input->get_en_lang ();
maps[1] = input->get_el_lang ();

input->curlang = 0;
getchar_lang = maps[0];
