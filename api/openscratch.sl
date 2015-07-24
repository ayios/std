define toscratch (str)
{
  () = lseek (SCRATCHFD, 0, SEEK_END);
  () = write (SCRATCHFD, str);
}

if (is_defined ("init_ftype"))
  {
  SCRATCH_VED = init_ftype ("txt");
  SCRATCH_VED._fd = SCRATCHFD;
  }

if (is_defined ("txt_settype"))
  txt_settype (SCRATCH_VED, SCRATCH, VED_ROWS, NULL);
  
