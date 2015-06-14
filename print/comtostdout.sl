define tostdout (str)
{
  () = lseek (stdoutfd, 0, SEEK_END);
  () = write (stdoutfd, str + "\n");
}

