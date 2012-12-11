a = GObj.create
b = GObj.create
c = a.async_do_sth
d = c.get_result
e = b.async_do_sth
f = e.get_result
h = nil
hh = nil
P.parallelFor(args) do
  g = a.async_do_sth(d)
  h = g.get_result
  gg = a.async_do_sth(h)
  hh = gg.get_result
end
j = nil
jj = nil
P.parallelFor(args) do
  i = b.async_do_sth(f)
  j = i.get_result
  ii = b.async_do_sth(j)
  jj = ii.get_result
end
k = a.async_do_sth(h, j)
l = b.async_do_sth(hh, jj)
