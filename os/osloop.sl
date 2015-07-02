define osloop ()
{
  toplinedr (" -- OS CONSOLE --" + " (depth " + string (_stkdepth ()) + ")");

  forever
    {
    rline->set (OSRL);
    rline->readline (OSRL);
    topline (" -- OS CONSOLE --" + " (depth " + string (_stkdepth ()) + ")");
    }
}
