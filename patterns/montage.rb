a = GObj.create
b = a.async_do_sth
c = b.get_result

e = nil
5.times do
  d = a.async_do_sth(c)
  e = d.get_result
end

f = a.async_do_sth(e)
g = f.get_result

i = nil
5.times do
  h = a.async_do_sth(g)
  i = h.get_result
end

j = a.async_do_sth(i)
k = j.get_result
l = a.async_do_sth(k)

5.times do
  m = l.get_result
  n = a.async_do_sth(m)
  o = n.get_result
  l = a.async_do_sth(o)
end

p = l.get_result
r = a.async_do_sth(p)
