define getscreensizefromenv ()
{
  return atoi (getenv ("LINES")), atoi (getenv ("COLUMNS"));
}
