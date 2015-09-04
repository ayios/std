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
    file = VED_DIR + "/clipboard";
    if (-1 == writestring (file, sel))
      return;
    com = [com, "-i", file];
    }
  else
    p.stdin.in = sel;

  () = p.execve (com, ["DISPLAY=" + DISPLAY, "XAUTHORITY=" + XAUTHORITY], NULL);

  ifnot (NULL == file)
    () = remove (file);
}
