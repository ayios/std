define seltoX (sel)
{
  ifnot (strlen (sel))
    return;

  variable
    p = proc->init (1, 0, 0);

  p.stdin.in = sel;

  () = p.execve ([which ("xclip")],
    ["DISPLAY=" + DISPLAY, "XAUTHORITY=" + XAUTHORITY], NULL);
}

