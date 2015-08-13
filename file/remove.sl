define __remove (file, interactive, isdir)
{
  variable f = [&remove, &rmdir][isdir];
  variable type = ["file", "directory"][isdir];

  ifnot (NULL == @interactive)
    {
    variable retval = ask ([
      file + ": remove " + type + "?", file,
      "y[es remove " + type + "]",
      "n[o do not remove " + type + "]",
      "q[uit question and abort the operation (exit)]",
      "a[ll continue by removing " + type + " and without asking again]",
      ],
      ['y', 'n', 'q', 'a']);

    switch (retval)

      {
      case 'y':
        if (-1 == (@f) (file))
          {
          tostderr (file + ": " + errno_string (errno));
          return -1;
          }
        else
          {
          tostdout (file + ": removed " + type);
          return 0;
          }
      }

      {
      case 'q':
        tostdout ("removing " + type + " `" + file + "' aborting ...");
        @interactive = "exit";
        return 0;
      }

      {
      case 'a':
        @interactive = NULL;
        if (-1 == (@f) (file))
          {
          tostderr (file + ": " + errno_string (errno));
          return -1;
          }
        else
          {
          tostdout (file + ": removed " + type);
          return 0;
          }
      }

      {
      case 'n':
        tostdout (file + ": Not confirming to remove " + type);
        return 0;
      }

    }

  if (-1 == (@f) (file))
    {
    tostderr (file + ": " + errno_string (errno));
    return -1;
    }
  else
    {
    tostdout (file + ": removed " + type);
    return 0;
    }
}
