define seltoX (sel)
{
  ifnot (strlen (sel))
    return;

  variable
    p = proc->init (1, 1, 1);

  p.stdout.file = "/tmp/o";
  p.stderr.file = "/tmp/e";
  p.stdin.in = sel;

  () = p.execve ([which ("xclip")], ["DISPLAY=" + DISPLAY], NULL);
}

