import ("getkey");

private variable
  esc_pend = 2;
 
define el_getch ()
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

define en_getch ()
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

define getch_until (timeout)
{
  if (0 == input_pending (timeout))
    return NULL;

  return (@getchar_lang);
}

define getch ()
{
  ifnot (TTY_INITED)
    {
    init_tty (-1, 0, 0);
    TTY_INITED = @(__get_reference ("TTY_Inited"));
    }

  esc_pend = qualifier ("esc_pend", 2);

  variable chr = (@getchar_lang) (;;__qualifiers ());
  while (any ([-1, 0] == chr))
    chr = (@getchar_lang) (;;__qualifiers ());

  return (chr);
}

(TTY_INITED, getchar_lang) = (@(__get_reference ("TTY_Inited")),
  &en_getch);

init_tty (-1, 0, 0);
