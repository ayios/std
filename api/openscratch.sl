define toscratch (str)
{
  () = lseek (SCRATCHFD, 0, SEEK_END);
  () = write (SCRATCHFD, str);
}

SCRATCH_VED = init_ftype ("txt");
SCRATCH_VED._fd = SCRATCHFD;

txt_settype (SCRATCH_VED, SCRATCH, VED_ROWS, NULL;_autochdir = 0);

SPECIAL = [SPECIAL, SCRATCH];
