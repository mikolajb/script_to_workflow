a = GObj.create
b = GObj.create
z = GObj.create
c = a.async_do_sth
d = b.async_do_sth
e = c.get_result
f = d.get_result
g = z.async_do_sth(e, f)
h = g.get_result
