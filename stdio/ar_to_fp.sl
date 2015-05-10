define ar_to_fp (ar, fmt, fp)
{
  variable
    bts = int (sum (array_map (Integer_Type, &fprintf, fp, fmt, ar)));
 
  () = fflush (fp);

  return bts;
}
