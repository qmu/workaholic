# QFS expression strings use single quotes and backslash escapes (not JSON
# quotes, and not the doubled quotes used by QFS path segments).
def qfs_string:
  "'" + (explode | map(
    if . == 39 then "\\'"
    elif . == 92 then "\\\\"
    elif . == 10 then "\\n"
    elif . == 13 then "\\r"
    elif . == 9 then "\\t"
    elif . == 0 then "\\0"
    else [.] | implode end
  ) | join("")) + "'";
