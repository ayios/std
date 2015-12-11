define seltoX (sel)
{
  variable len = strlen (sel);

  ifnot (len) return;

  variable file = NULL;
  variable isnotlentoobigforfd = len < 256 * 256;
  variable com = [XCLIP_BIN];
  variable p = proc->init (isnotlentoobigforfd, 0, 0);

  ifnot (isnotlentoobigforfd)
    {
    file = sprintf ("%s/%d_%d_clipboard", VED_DIR, Env.vget ("PID"), Env.vget ("UID"));
    if (-1 == writestring (file, sel))
      return;
    com = [com, "-i", file];
    }
  else
    p.stdin.in = sel;

  () = p.execve (com, ["DISPLAY=" + Env.vget ("DISPLAY"), "XAUTHORITY=" +
    Env.vget ("XAUTHORITY")], NULL);

  ifnot (NULL == file)
    () = remove (file);
}

define getXsel ()
{
  variable file = sprintf ("%s/%d_%d_clipboard", VED_DIR, Env.vget ("PID"), Env.vget ("UID"));
  variable com = [XCLIP_BIN, "-o"];
  variable p = proc->init (0, 1, 0);

  p.stdout.file = file;

  () = p.execve (com, ["DISPLAY=" + Env.vget ("DISPLAY"), "XAUTHORITY=" +
    Env.vget ("XAUTHORITY")], NULL);

  variable sel = strjoin (IO.readfile (file), "\n");

  () = remove (file);

  sel;
}
