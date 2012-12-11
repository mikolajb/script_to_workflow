a = GObj.create
b = a.async_do_sth
c = b.get_result
d = b.get_result
e = a.async_do_sth c
f = a.async_do_sth d
