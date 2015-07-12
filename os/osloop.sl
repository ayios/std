define osloop ()
{
  toplinedr (" -- OS CONSOLE --" + " (depth " + string (_stkdepth ()) + ")");

  forever
    {
    rline->set (RLINE);
    rline->readline (RLINE);
    topline (" -- OS CONSOLE --" + " (depth " + string (_stkdepth ()) + ")");
    }
}
