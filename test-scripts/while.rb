a = GObj.create

b = a.async_do_sth
c = b.get_result

d = 0
while true
  d = a.async_do_sth(c)
  c = d.get_result
end
e = d.get_result
f = a.async_do_sth(e)
g = f.get_result
