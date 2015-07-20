variable SCRATCH = TEMPDIR + "/" + string (PID) + "_" + APP.appname +  "_scratch.txt";
variable SCRATCHFD =  initstream (SCRATCH);
variable SCRATCH_VED = "";

if (is_defined ("init_ftype"))
  {
  SCRATCH_VED = init_ftype ("txt");
  SCRATCH_VED._fd = SCRATCHFD;
  }

if (is_defined ("txt_settype"))
  txt_settype (SCRATCH_VED, SCRATCH, VED_ROWS, NULL);
  
