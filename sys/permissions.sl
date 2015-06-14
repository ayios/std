public variable PERM = Assoc_Type[Integer_Type];

PERM["PRIVATE"]  = S_IRWXU;                          %0700
PERM["_PRIVATE"] = S_IRUSR|S_IWUSR;                  %0600

PERM["STATIC"]   = PERM["PRIVATE"]|S_IRWXG;          %0770
PERM["_STATIC"]  = PERM["PRIVATE"]|S_IRGRP|S_IXGRP;  %0750
PERM["__STATIC"] = PERM["_PRIVATE"]|S_IRGRP;         %0640

PERM["PUBLIC"]    = PERM["STATIC"]|S_IRWXO;          %0777
PERM["_PUBLIC"]   = PERM["_STATIC"]|S_IROTH|S_IXGRP; %0754
PERM["__PUBLIC"]  = PERM["__STATIC"]|S_IROTH;        %0644
