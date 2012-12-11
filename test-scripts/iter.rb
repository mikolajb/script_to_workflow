a = GObj.create

b = a.async_do_sth
c = b.get_result

d = a.async_do_sth(c)
5.times do
  e = d.get_result
  f = a.async_do_sth(e)
  g = f.get_result
  d = a.async_do_sth(g)
end
i = d.get_result
j = a.async_do_sth(i)
k = j.get_result
