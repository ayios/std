define osloop (app)
{
  ifnot (NULL == app)
    os->runapp (;argv0 = app);
  else
    draw (ERR);

  toplinedr (" -- OS CONSOLE --" + " (depth " + string (_stkdepth ()) + ")");
 
  forever
    {
    rline->set (RLINE);
    rline->readline (RLINE);
    topline (" -- OS CONSOLE --" + " (depth " + string (_stkdepth ()) + ")");
    }
}
