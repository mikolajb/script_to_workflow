a = GObj.create
b = a.async_do_sth
c = b.get_result
k = nil
P.parallelFor(args) do
  d = a.async_do_sth(c)
  e = d.get_result
  f = a.async_do_sth(e)
  g = f.get_result
  h = a.async_do_sth(g)
  i = h.get_result
  j = a.async_do_sth(i)
  k = j.get_result
end
l = a.async_do_sth(k)
m = l.get_result
n = a.async_do_sth(m)
o = n.get_result
p = a.async_do_sth(o)
