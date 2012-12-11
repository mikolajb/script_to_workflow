a = GObj.create
b = a.async_do_sth
c = b.get_result
if c == true
  d = a.async_do_sth(c)
  e = d.get_result
elsif c == false
  f = a.async_do_sth(c)
  g = f.get_result
else
  h = a.async_do_sth(c)
  i = h.get_result
end
