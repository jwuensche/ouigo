# TODOs still open

- Check if a new resource is further in the future
  We can use to this end the job api in grid5000
  The according attribute is `scheduled_start`
  If this is too far in the future aka > 5 min cancel and let's try something else (modify the requirement to a lesser machine to guarantee some
  availability)
  If this cannnot be done error out

- Renew existing reservations
  This is were the files come into play, they save some adjurning data we may need to process requests like the job id, node name, vlan id
