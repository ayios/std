private define files (s, fnamea, fnameb)
{
  if (-1 == access (fnamea, F_OK|R_OK))
    {
    IO.tostderr (fnamea, ": ", errno_string (errno));
    return NULL;
    }

  if (-1 == access (fnameb, F_OK|R_OK))
    {
    IO.tostderr (fnameb, ": ", errno_string (errno));
    return NULL;
    }

  ifnot (File.isreg (fnamea))
    {
    IO.tostderr (fnamea, " : is not a regular file");
    return NULL;
    }

  ifnot (File.isreg (fnameb))
    {
    IO.tostderr (fnameb, " : is not a regular file");
    return NULL;
    }

  if (File.are_same (fnamea, fnameb))
    {
    IO.tostderr (fnamea, " and ", fnameb, " are the same files");
    return NULL;
    }

  variable x = IO.readfile (fnamea);
  variable y = IO.readfile (fnameb);

  s.new (x, y);
}
