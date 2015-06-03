define struct_field_exists (s, field)
{
  return wherefirst (get_struct_field_names (s) == field);
}
