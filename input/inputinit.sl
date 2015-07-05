private variable esc_pend = 2;
static variable alias = Assoc_Type[String_Type];
static variable curlang;

static define toggle_map ()
{
  curlang = curlang == length (maps) - 1 ? 0 : curlang + 1;
  return maps[curlang];
}

private define el_getch ()
{
  variable
    esc_key = qualifier ("esc_key", 033),
    chr,
    index,
    vowel,
    el =  [[913:929:1], [931:937:1],[945:969:1],';',':'],
    eng = [
      'A','B','G','D','E','Z','H','U','I','K','L','M','N','J','O','P','R','S','T','Y',
      'F','X','C','V',
      'a','b','g','d','e','z','h','u','i','k','l','m','n','j','o','p','r','w', 's','t',
      'y','f','x','c','v','q','Q'],
    accent_vowels = ['ά','έ','ή','ί','ό','ύ','ώ','΄','Ά','Έ','Ό','Ί','Ώ','Ύ','Ή'],
    vowels_in_eng = ['a','e','h','i','o','y','v',';','A','E','O','I','V','Y','H'],
    ais = ['ϊ', 'ΐ', '¨'],
    ais_eng = ['i', ';', ':'];

  while (0 == input_pending (1))
    continue;

  chr = getkey ();

  if (chr == esc_key)
    if (0 == input_pending (esc_pend))
	    return esc_key;
    else
      chr = getkey () + 65535;

  if (';' == chr)
    {
    while (0 == input_pending (1))
      continue;
    vowel = getkey ();
    index = wherefirst_eq (vowels_in_eng, vowel);
    if (NULL == index)
      return -1;
    else
      chr = accent_vowels[index];
    }
  else if (':' == chr)
    {
    while (0 == input_pending (1))
      continue;
    vowel = getkey ();
    index = wherefirst_eq (ais_eng, vowel);
    if (NULL == index)
      return -1;
    else
      chr = ais[index];
    }
  else
    {
    index = wherefirst_eq (eng, chr);
    ifnot (NULL == index)
      chr = el[index];
    }

  return chr;
}

private define en_getch ()
{
  variable
    esc_key = qualifier ("esc_key", 033),
    chr;

  while (0 == input_pending (1))
    continue;

  chr = getkey ();

  if (chr == esc_key)
    if (0 == input_pending (esc_pend))
	    return esc_key;
    else
      chr = getkey () + 65535;

  return chr;
}

public define getch ();
public define getch ()
{
  ifnot (TTY_INITED)
    {
    init_tty (-1, 0, 0);
    TTY_INITED = @(__get_reference ("input->TTY_Inited"));
    }

  esc_pend = qualifier ("esc_pend", 2);

  variable chr = (@getchar_lang) (;;__qualifiers ());
  while (any ([-1, 0] == chr))
    chr = (@getchar_lang) (;;__qualifiers ());
 
  if (any (keys->rmap.changelang == chr))
    if (qualifier_exists ("disable_langchange"))
      return chr;
    else
      {
      getchar_lang = toggle_map ();

      variable callbackf = qualifier ("on_lang");
      variable args = qualifier ("on_lang_args");

      ifnot (NULL == callbackf)
        ifnot (NULL == args)
          (@callbackf) (args);
        else
          (@callbackf);

      return getch ();
      }
  else
    return chr;
}

static define get_en_lang ()
{
  return &en_getch;
}

static define get_el_lang ()
{
  return &el_getch;
}

static define getmapname ()
{
  return alias[string (maps[curlang])];
}

static define getlang ()
{
  return maps[curlang];
}

static define setlang (lang)
{
  getchar_lang = lang;
}

static define at_exit ()
{
  if (TTY_INITED)
    reset_tty ();
}

alias["&en_getch"] = "US";
alias["&el_getch"] = "EL";
