define removedir (dir, interactive)
{
  ifnot (NULL == @interactive)
    {
    variable retval = ask ([
      sprintf ("%s: remove directory?", dir),
      "y[es remove directory]",
      "n[o do not remove directory]",
      "q[uit question and abort the operation (exit)]",
      "a[ll continue by removing directory and without asking again]",
      "escape to remove directory and never ask again, same as all"
      ],
      ['y', 'q', 'a', 'n']);

    switch (retval)

      {
      case 'y':
        if (-1 == rmdir (dir))
          {
          tostderr (sprintf ("%s: %s", dir, errno_string (errno));print_in_msg_line);
          return -1;
          }
        else
          {
          tostdout (sprintf ("%s: removed directory", dir);print_in_msg_line);
          return 0;
          }
      }

      {
      case 'q':
        tostdout (sprintf ("removing directory `%s' aborting ...", dir));
        @interactive = "exit";
        return 0;
      }

      {
      case 'a' || case 033:
        @interactive = NULL;
        if (-1 == rmdir (dir))
          {
          tostderr (sprintf ("%s: %s", dir, errno_string (errno)));
          return -1;
          }
        else
          {
          tostdout (sprintf ("%s: removed directory", dir));
          return 0;
          }
      }

      {
      case 'n':
        tostdout (sprintf ("%s: Not confirming to remove directory", dir));
        return 0;
      }
    }

  if (-1 == rmdir (dir))
    {
    tostderr (sprintf ("%s: %s", dir, errno_string (errno)));
    return -1;
    }
  else
    {
    tostdout (sprintf ("%s: removed directory", dir));
    return 0;
    }
}
