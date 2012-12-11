a = GObj.craete
b = a.async_do_sth
c = b.get_result
g = 0
P.parallelFor([1, 2, 3, 4]) { |i|
  d = a.async_do_sth(c + i)
  e = d.get_result
  f = a.async_do_sth(e)
  g = f.get_result
}
h = a.async_do_sth(g)
