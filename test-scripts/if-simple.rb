a = GObj.create

b = a.async_do_sth
c = b.get_result
d = a.async_do_sth
e = d.get_result

f = nil
if c == 2
  f = a.async_do_sth(c)
else
  f = a.async_do_sth(e)
end

g = f.get_result
h = a.async_do_sth(g)
i = h.get_result
