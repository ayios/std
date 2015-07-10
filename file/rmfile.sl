define rmfile (file, interactive)
{
  ifnot (NULL == @interactive)
    {
    variable retval = ask ([
      sprintf ("%s: remove it ?", file),
      "y[es remove file]",
      "n[o do not remove file]",
      "q[uit question and abort the operation (exit)]",
      "a[ll continue by removing file and without asking again]",
      ],
      ['y', 'q', 'a', 'n']);

    switch (retval)

      {
      case 'y':
        if (-1 == remove (file))
          {
          tostderr (sprintf ("%s: %s", file, errno_string (errno)));
          return -1;
          }
        else
          {
          tostdout (sprintf ("%s: removed file", file));
          return 0;
          }
      }

      {
      case 'q':
        tostdout (sprintf ("removing file `%s' aborting ...", file));
        @interactive = "exit";
        return 0;
      }

      {
      case 'a':
        @interactive = NULL;
        if (-1 == remove (file))
          {
          tostderr (sprintf ("%s: %s", file, errno_string (errno)));
          return -1;
          }
        else
          {
          tostdout (sprintf ("%s: removed file", file));
          return  0;
          }
      }

      {
      case 'n':
        tostdout (sprintf ("%s: Not confirming to remove file", file));
        return 0;
      }

    }

  if (-1 == remove (file))
    {
    tostderr (sprintf ("%s: %s", file, errno_string (errno)));
    return -1;
    }
  else
    {
    tostdout (sprintf ("%s: removed file", file));
    return 0;
    }
}
