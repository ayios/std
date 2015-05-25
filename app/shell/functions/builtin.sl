define _cd_ (argv)
{
  shell_pre_header (argv);

  if (1 == length (argv))
    {
    () = chdir ("$HOME"$);
    SHELLLASTEXITSTATUS = 0;
    return;
    }
    
  if (-1 == chdir (argv[1]))
    {
    tostderr (errno_string (errno));
    SHELLLASTEXITSTATUS = 1;
    }

  shell_post_header ();

  draw (qualifier ("ved"));
}
